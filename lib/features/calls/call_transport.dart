/// Getting signals off the server and onto this phone.
///
/// WHY POLLING AND NOT A SOCKET. There is no websocket client in this app,
/// and adding one would not solve the problem it looks like it solves: iOS
/// and Android drop the socket when the app is not in front, which is exactly
/// when a call arrives. Ringing is push's job. What a socket would buy is a
/// slightly faster SDP exchange during the two or three seconds both apps are
/// awake and negotiating, and an HTTP poll covers that at a cost of a few
/// requests per call.
///
/// It also survives what Ethiopian mobile data does to long-lived
/// connections, which is end them.
///
/// No Flutter and no WebRTC in here, so the parts that go wrong — the cursor,
/// the backoff, stopping — are testable without a device.
library;

import 'dart:async';

/// One signal, as the drain returns it.
class CallSignalMessage {
  const CallSignalMessage({
    required this.id,
    required this.type,
    this.data,
  });

  final int id;

  /// The server's vocabulary: incoming, accepted, rejected, ended, busy,
  /// offer, answer, ice.
  final String type;

  /// SDP or an ICE candidate, already unwrapped by the server. Untouched
  /// here: this file never parses SDP.
  final Object? data;

  static CallSignalMessage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final type = raw['type'];
    if (id is! int || type is! String || type.isEmpty) return null;
    return CallSignalMessage(id: id, type: type, data: raw['data']);
  }
}

/// What a drain returned.
class DrainResult {
  const DrainResult({
    required this.signals,
    required this.cursor,
    this.status,
  });

  final List<CallSignalMessage> signals;
  final int cursor;

  /// The call's own status. A client that missed the `ended` signal — app
  /// killed, network gone — learns here that the call is over instead of
  /// waiting for a message that has already been collected.
  final String? status;

  static const empty = DrainResult(signals: [], cursor: 0);
}

/// The HTTP calls this needs. An interface so the polling logic can be
/// tested without a network, which is the whole point of the split.
abstract class CallSignalSource {
  /// GET /api/calls/{uid}/signals?after={cursor}
  Future<DrainResult> drain(String callUid, int after);
}

/// Statuses that mean the call is finished and polling should stop.
const Set<String> terminalCallStatuses = {
  'ended', 'rejected', 'missed', 'failed',
};

/// Polls the drain and hands each signal, in order, to [onSignal].
///
/// The cursor only ever moves forward. Resetting it on an error would
/// redeliver every signal of the call — including `ended`, which would tear
/// down whatever came next.
class CallSignalPoller {
  CallSignalPoller({
    required this.source,
    required this.callUid,
    required this.onSignal,
    this.onStatus,
    this.interval = const Duration(milliseconds: 800),
    this.idleInterval = const Duration(seconds: 3),
  });

  final CallSignalSource source;
  final String callUid;
  final void Function(CallSignalMessage signal) onSignal;
  final void Function(String status)? onStatus;

  /// While anything is happening. A negotiation is over in a couple of
  /// seconds and a slower poll is a visibly slower call.
  final Duration interval;

  /// Once the call is connected and quiet. The signalling is done by then;
  /// this is only still running to notice a hang-up.
  final Duration idleInterval;

  int _cursor = 0;
  bool _running = false;
  bool _inFlight = false;
  int _quietRounds = 0;
  Timer? _timer;

  int get cursor => _cursor;
  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running = true;
    _schedule(Duration.zero);
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    if (!_running) return;
    _timer = Timer(delay, _tick);
  }

  Future<void> _tick() async {
    if (!_running || _inFlight) return;
    _inFlight = true;
    try {
      final result = await source.drain(callUid, _cursor);

      if (!_running) return;

      if (result.signals.isEmpty) {
        _quietRounds++;
      } else {
        _quietRounds = 0;
        for (final signal in result.signals) {
          // Guard against a server that ever replays: a signal at or below
          // the cursor has been handled, and handling `ended` twice would
          // end a call that had already been replaced.
          if (signal.id <= _cursor) continue;
          _cursor = signal.id;
          onSignal(signal);
        }
      }

      // Never backwards. See the class comment.
      if (result.cursor > _cursor) _cursor = result.cursor;

      final status = result.status;
      if (status != null) {
        onStatus?.call(status);
        if (terminalCallStatuses.contains(status)) {
          stop();
          return;
        }
      }
    } catch (_) {
      // A failed poll is ordinary on mobile data. Keep the cursor, keep
      // going; the next one collects whatever this one missed.
      _quietRounds++;
    } finally {
      _inFlight = false;
    }

    // Three quiet rounds is roughly "the negotiation finished".
    _schedule(_quietRounds >= 3 ? idleInterval : interval);
  }
}
