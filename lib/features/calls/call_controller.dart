/// The glue: decisions from [CallSession], audio from flutter_webrtc,
/// signals from [CallSignalPoller].
///
/// Deliberately dull, as the session file promised. Everything about WHETHER
/// and WHEN lives in call_session.dart and is tested there without a device.
/// What is here is "create a peer connection, hand it an offer, play audio" —
/// plus the two things that are easy to get wrong and expensive in the field:
/// the microphone permission, and buffered ICE candidates.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_api.dart';
import 'call_session.dart';
import 'call_transport.dart';

enum CallFailure {
  /// The user refused the microphone, or the OS did.
  microphoneDenied,

  /// No relay configured. The call would connect on wifi and fail on mobile
  /// data; saying so beats dialling into silence.
  noRelay,

  /// The server refused to start the call. [CallController.failureMessage]
  /// carries what it said.
  refused,

  /// Something broke mid-call.
  broken,
}

/// One call, for the UI to watch.
class CallController extends ChangeNotifier {
  CallController({CallApi? api}) : _api = api ?? CallApi();

  final CallApi _api;

  CallSession? _session;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  CallSignalPoller? _poller;
  Timer? _ringTimer;
  Timer? _durationTimer;

  CallFailure? _failure;
  String? _failureMessage;
  String? _peerName;
  bool _turnAvailable = true;
  Duration _elapsed = Duration.zero;
  bool _muted = false;
  bool _speakerOn = false;

  CallState get state => _session?.state ?? CallState.idle;
  bool get isActive => _session != null && !_session!.isOver;
  CallEndReason? get endReason => _session?.endReason;
  CallFailure? get failure => _failure;
  String? get failureMessage => _failureMessage;
  String? get peerName => _peerName;
  String? get callUid => _session?.uid;

  /// False means a call will probably fail on mobile data. The screen says
  /// so rather than letting the user find out by shouting into it.
  bool get turnAvailable => _turnAvailable;

  /// Only ticks once audio is flowing. A timer that starts at `connecting`
  /// makes every call look longer than it was.
  Duration get elapsed => _elapsed;
  bool get muted => _muted;
  bool get speakerOn => _speakerOn;

  // ── Starting ─────────────────────────────────────────────────────────

  /// Place a call. [calleeId] must be the other party on a job that is still
  /// running; the server enforces that and refuses otherwise.
  Future<bool> placeCall(int calleeId, {String? displayName}) async {
    if (isActive) return false;
    _reset();
    _peerName = displayName;

    if (!await _ensureMicrophone()) return false;

    final ice = await _api.iceServers();
    if (ice.servers.isEmpty) {
      return _fail(CallFailure.noRelay, 'Calling is unavailable right now.');
    }
    _turnAvailable = ice.turnAvailable;

    final String? uid;
    try {
      uid = await _api.initiate(calleeId);
    } catch (e) {
      return _fail(CallFailure.refused, _messageFrom(e));
    }
    if (uid == null) {
      return _fail(CallFailure.refused, 'The call could not be started.');
    }

    _session = CallSession.outgoing(uid);
    await _prepare(ice);
    _startPolling(uid);
    _armRingTimeout();
    notifyListeners();
    return true;
  }

  /// A call is ringing this phone. [uid] comes from the push payload.
  Future<void> receiveCall(String uid, {String? callerName}) async {
    if (isActive) return;
    _reset();
    _peerName = callerName;
    _session = CallSession.incoming(uid);
    _startPolling(uid);
    _armRingTimeout();
    notifyListeners();
  }

  // ── The user's three buttons ─────────────────────────────────────────

  Future<void> answer() async {
    final session = _session;
    if (session == null || session.state != CallState.ringing) return;

    // BEFORE accepting, not after. Accepting first and then discovering the
    // microphone is refused gives both sides a connected call with silence
    // on one end, which is indistinguishable from a broken network.
    if (!await _ensureMicrophone()) {
      await _api.reject(session.uid, reason: 'no_microphone').catchError((_) {});
      return;
    }

    final ice = await _api.iceServers();
    if (ice.servers.isEmpty) {
      await _api.reject(session.uid, reason: 'unavailable').catchError((_) {});
      _fail(CallFailure.noRelay, 'Calling is unavailable right now.');
      return;
    }
    _turnAvailable = ice.turnAvailable;

    await _prepare(ice);

    session.accept();
    _cancelRingTimeout();
    try {
      await _api.accept(session.uid);
    } catch (e) {
      _fail(CallFailure.broken, _messageFrom(e));
      return;
    }
    notifyListeners();
  }

  Future<void> decline() async {
    final session = _session;
    if (session == null) return;
    await _api.reject(session.uid).catchError((_) {});
    _finish(session.end(CallEndReason.declined));
  }

  Future<void> hangUp() async {
    final session = _session;
    if (session == null) return;
    final reason = session.state == CallState.dialling
        ? CallEndReason.cancelled
        : CallEndReason.hungUp;
    await _api.end(session.uid).catchError((_) {});
    _finish(session.end(reason));
  }

  void toggleMute() {
    _muted = !_muted;
    for (final track in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !_muted;
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
    } catch (_) {
      // Not fatal: the call still works on the earpiece.
    }
    notifyListeners();
  }

  // ── Signals ──────────────────────────────────────────────────────────

  void _startPolling(String uid) {
    _poller = CallSignalPoller(
      source: _api,
      callUid: uid,
      onSignal: _onSignal,
      onStatus: (status) {
        // The call ended while this phone was not looking. The drain says
        // so even when the `ended` signal itself was collected by a session
        // that is gone.
        if (terminalCallStatuses.contains(status) && isActive) {
          _finish(_session!.end(CallEndReason.hungUp));
        }
      },
    )..start();
  }

  Future<void> _onSignal(CallSignalMessage signal) async {
    final session = _session;
    if (session == null) return;

    final outcome = session.onSignal(session.uid, signal.type, payload: signal.data);

    switch (outcome.effect) {
      case CallEffect.sendOffer:
        _cancelRingTimeout();
        await _sendOffer();
        break;

      case CallEffect.answerOffer:
        await _applyRemote(signal.data, 'offer');
        // Candidates that arrived before there was anywhere to put them.
        // The session held them; releasing them is this file's only job
        // in that story.
        await _addCandidates(outcome.candidates);
        await _sendAnswer();
        break;

      case CallEffect.applyAnswer:
        await _applyRemote(signal.data, 'answer');
        await _addCandidates(outcome.candidates);
        break;

      case CallEffect.applyCandidates:
        await _addCandidates(outcome.candidates);
        break;

      case CallEffect.teardown:
        _finish(outcome);
        return;

      case CallEffect.startRinging:
      case CallEffect.none:
        break;
    }

    notifyListeners();
  }

  // ── WebRTC ───────────────────────────────────────────────────────────

  Future<void> _prepare(IceConfig ice) async {
    _pc = await createPeerConnection({
      'iceServers': ice.servers,
      // Audio only. Relayed audio is the running cost of calling and a
      // courier call needs a few tens of kbit/s.
      'sdpSemantics': 'unified-plan',
    });

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onIceCandidate = (candidate) {
      final session = _session;
      if (session == null || session.isOver) return;
      _api.signal(session.uid, 'ice', candidate.toMap()).catchError((_) {});
    };

    _pc!.onConnectionState = (state) {
      final session = _session;
      if (session == null) return;
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          if (session.mediaConnected().state == CallState.active) {
            _startDurationTimer();
            notifyListeners();
          }
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _finish(session.mediaFailed());
          break;
        default:
          break;
      }
    };
  }

  Future<void> _sendOffer() async {
    final pc = _pc;
    final session = _session;
    if (pc == null || session == null) return;
    final offer = await pc.createOffer({'offerToReceiveAudio': true});
    await pc.setLocalDescription(offer);
    await _api.signal(session.uid, 'offer', offer.toMap());
  }

  Future<void> _sendAnswer() async {
    final pc = _pc;
    final session = _session;
    if (pc == null || session == null) return;
    final answer = await pc.createAnswer({'offerToReceiveAudio': true});
    await pc.setLocalDescription(answer);
    await _api.signal(session.uid, 'answer', answer.toMap());
  }

  Future<void> _applyRemote(Object? data, String type) async {
    final pc = _pc;
    if (pc == null || data is! Map) return;
    final sdp = data['sdp'];
    if (sdp is! String) return;
    await pc.setRemoteDescription(
      RTCSessionDescription(sdp, (data['type'] as String?) ?? type),
    );
  }

  Future<void> _addCandidates(List<Object> candidates) async {
    final pc = _pc;
    if (pc == null) return;
    for (final raw in candidates) {
      if (raw is! Map) continue;
      final candidate = raw['candidate'];
      if (candidate is! String) continue;
      await pc.addCandidate(RTCIceCandidate(
        candidate,
        raw['sdpMid'] as String?,
        raw['sdpMLineIndex'] as int?,
      ));
    }
  }

  // ── Housekeeping ─────────────────────────────────────────────────────

  Future<bool> _ensureMicrophone() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    return _fail(
      CallFailure.microphoneDenied,
      'HudHud needs the microphone to place a call.',
    );
  }

  void _armRingTimeout() {
    _ringTimer?.cancel();
    _ringTimer = Timer(
      const Duration(seconds: 45),
      () {
        final session = _session;
        if (session == null || session.isOver) return;
        _api.end(session.uid, reason: 'missed').catchError((_) {});
        _finish(session.ringTimeout());
      },
    );
  }

  void _cancelRingTimeout() {
    _ringTimer?.cancel();
    _ringTimer = null;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _finish(CallOutcome outcome) {
    if (outcome.effect == CallEffect.teardown || _session?.isOver == true) {
      _teardown();
    }
    notifyListeners();
  }

  bool _fail(CallFailure failure, String message) {
    _failure = failure;
    _failureMessage = message;
    _teardown();
    notifyListeners();
    return false;
  }

  void _teardown() {
    _poller?.stop();
    _poller = null;
    _cancelRingTimeout();
    _durationTimer?.cancel();
    _durationTimer = null;

    // The microphone light must go out. A stream left running after a call
    // is a privacy problem, not a leak.
    for (final track in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      track.stop();
    }
    _localStream?.dispose();
    _localStream = null;

    _pc?.close();
    _pc = null;
  }

  void _reset() {
    _failure = null;
    _failureMessage = null;
    _elapsed = Duration.zero;
    _muted = false;
    _speakerOn = false;
    _turnAvailable = true;
    _session = null;
  }

  String _messageFrom(Object error) {
    final text = error.toString();
    if (text.contains('NO_ACTIVE_JOB')) {
      return 'You can only call someone you have an active delivery with.';
    }
    if (text.contains('CALLEE_BUSY')) return 'They are already on a call.';
    if (text.contains('CALLS_DISABLED')) return 'Calling is unavailable right now.';
    return 'The call could not be started.';
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }
}
