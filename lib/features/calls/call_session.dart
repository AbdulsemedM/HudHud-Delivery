/// The call lifecycle, with no Flutter and no WebRTC in it.
///
/// WHY IT IS SEPARATE. A voice call is mostly decisions — which signal to
/// act on, which to ignore, what may follow what — and those decisions are
/// where calls break. Buried inside a widget that owns a peer connection and
/// a native ring, none of them can be tested without two phones and a relay.
/// Here they are plain functions over plain data, so CI can exercise the
/// parts that actually go wrong.
///
/// What is left for the glue is deliberately dull: create a peer connection,
/// hand it an offer, play audio. This file decides *whether* and *when*.
library;

enum CallState {
  /// No call. The only state from which one may be started.
  idle,

  /// We called; the other phone has not answered.
  dialling,

  /// They called; this phone is ringing.
  ringing,

  /// Answered, media still negotiating. Audio is not flowing yet, and
  /// telling the user "connected" here is the lie that makes people say
  /// "hello?" into silence.
  connecting,

  /// Audio is flowing.
  active,

  /// Over. Terminal: nothing moves out of it.
  ended,
}

enum CallEndReason {
  hungUp,
  declined,
  missed,
  busy,
  failed,
  /// The caller gave up before it was answered.
  cancelled,
}

/// What the glue should do after a signal. Returned rather than performed,
/// so the decision can be asserted without a peer connection existing.
enum CallEffect {
  none,
  /// Build a peer connection and send an offer.
  sendOffer,
  /// Apply the remote offer and answer it.
  answerOffer,
  /// Apply the remote answer.
  applyAnswer,
  /// Apply one or more ICE candidates.
  applyCandidates,
  /// Start ringing this phone.
  startRinging,
  /// Stop everything and release the microphone.
  teardown,
}

class CallOutcome {
  const CallOutcome(this.state, this.effect, {this.candidates = const []});

  final CallState state;
  final CallEffect effect;

  /// Candidates released by this transition — see [CallSession.onSignal].
  final List<Object> candidates;
}

/// One call, from the point of view of one phone.
///
/// Signals arrive from the server over the private user channel, carrying a
/// `call_uid`. A phone can legitimately see signals for a call it is not in
/// (a second call arriving while one is active, a late message from a call
/// that already ended), so every signal is matched against the uid this
/// session belongs to and ignored otherwise. Acting on a stray signal is how
/// a live call gets torn down by a dead one.
class CallSession {
  CallSession._(this.uid, {required this.isCaller, required CallState state})
      : _state = state;

  /// This phone placed the call.
  factory CallSession.outgoing(String uid) =>
      CallSession._(uid, isCaller: true, state: CallState.dialling);

  /// This phone was called.
  factory CallSession.incoming(String uid) =>
      CallSession._(uid, isCaller: false, state: CallState.ringing);

  final String uid;
  final bool isCaller;

  CallState _state;
  CallState get state => _state;

  CallEndReason? _endReason;
  CallEndReason? get endReason => _endReason;

  bool get isOver => _state == CallState.ended;

  /// True once audio should be flowing. The glue shows a timer on this, and
  /// not on [CallState.connecting], because a timer that starts before audio
  /// does makes every call look longer than it was.
  bool get isTalking => _state == CallState.active;

  /*
   * ICE CANDIDATES ARRIVE BEFORE THERE IS ANYWHERE TO PUT THEM.
   *
   * The other phone starts gathering and sending candidates the moment it
   * has a local description, which is routinely before its answer reaches
   * us. A candidate handed to a peer connection that has no remote
   * description is REJECTED, and the usual mistake is to drop it: the call
   * then connects only when the discarded ones happened not to matter, which
   * is some of the time, on some networks. It produces a feature that works
   * for the developer and fails for a third of users with nothing in any log.
   *
   * So they are held until the remote description exists and released in one
   * go. _remoteDescriptionSet is the gate.
   */
  final List<Object> _pendingCandidates = [];
  bool _remoteDescriptionSet = false;

  int get bufferedCandidateCount => _pendingCandidates.length;

  /// The user answered an incoming call.
  CallOutcome accept() {
    if (_state != CallState.ringing) {
      // Answering a call that stopped ringing - they hung up while the
      // thumb was moving - must not resurrect it.
      return CallOutcome(_state, CallEffect.none);
    }
    _state = CallState.connecting;
    return const CallOutcome(CallState.connecting, CallEffect.none);
  }

  /// The user declined, or hung up, or the screen was closed.
  CallOutcome end(CallEndReason reason) {
    if (isOver) {
      // Hanging up twice is normal: the user taps as the other side drops.
      // The first reason is the true one.
      return const CallOutcome(CallState.ended, CallEffect.none);
    }
    _state = CallState.ended;
    _endReason = reason;
    _pendingCandidates.clear();
    return const CallOutcome(CallState.ended, CallEffect.teardown);
  }

  /// Nobody answered within the ring timeout.
  CallOutcome ringTimeout() {
    if (_state != CallState.dialling && _state != CallState.ringing) {
      return CallOutcome(_state, CallEffect.none);
    }
    return end(CallEndReason.missed);
  }

  /// A signal from the server.
  ///
  /// [type] is the server's own vocabulary: accepted, rejected, ended,
  /// offer, answer, ice. [payload] is handed back untouched in
  /// [CallOutcome.candidates] where it is one; this class never parses SDP.
  CallOutcome onSignal(String uid, String type, {Object? payload}) {
    // Not our call. See the class comment: acting on a stray signal is how a
    // live call gets torn down by a dead one.
    if (uid != this.uid) {
      return CallOutcome(_state, CallEffect.none);
    }

    if (isOver) {
      // Late signals from a finished call are ordinary, not errors.
      return const CallOutcome(CallState.ended, CallEffect.none);
    }

    switch (type) {
      case 'accepted':
        if (_state != CallState.dialling) {
          return CallOutcome(_state, CallEffect.none);
        }
        _state = CallState.connecting;
        // The caller offers. Doing it before they accept wastes a peer
        // connection on every unanswered call.
        return const CallOutcome(CallState.connecting, CallEffect.sendOffer);

      case 'rejected':
        return end(CallEndReason.declined);

      case 'ended':
        return end(CallEndReason.hungUp);

      case 'busy':
        return end(CallEndReason.busy);

      case 'offer':
        if (isCaller) {
          // Both sides offering is glare. The caller's offer wins, so the
          // callee's is ignored rather than applied over our own.
          return CallOutcome(_state, CallEffect.none);
        }
        _remoteDescriptionSet = true;
        return CallOutcome(_state, CallEffect.answerOffer,
            candidates: _drainCandidates());

      case 'answer':
        if (!isCaller) {
          return CallOutcome(_state, CallEffect.none);
        }
        _remoteDescriptionSet = true;
        return CallOutcome(_state, CallEffect.applyAnswer,
            candidates: _drainCandidates());

      case 'ice':
        if (payload == null) {
          return CallOutcome(_state, CallEffect.none);
        }
        if (!_remoteDescriptionSet) {
          _pendingCandidates.add(payload);
          return CallOutcome(_state, CallEffect.none);
        }
        return CallOutcome(_state, CallEffect.applyCandidates,
            candidates: [payload]);

      default:
        // An unknown signal is not a reason to drop a call in progress.
        return CallOutcome(_state, CallEffect.none);
    }
  }

  /// The peer connection reported that media is flowing.
  CallOutcome mediaConnected() {
    if (_state != CallState.connecting) {
      return CallOutcome(_state, CallEffect.none);
    }
    _state = CallState.active;
    return const CallOutcome(CallState.active, CallEffect.none);
  }

  /// The peer connection failed after answering.
  CallOutcome mediaFailed() => end(CallEndReason.failed);

  List<Object> _drainCandidates() {
    if (_pendingCandidates.isEmpty) return const [];
    final held = List<Object>.unmodifiable(_pendingCandidates);
    _pendingCandidates.clear();
    return held;
  }
}
