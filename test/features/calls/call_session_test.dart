import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/calls/call_session.dart';

/// The decisions a voice call is made of, tested without two phones.
///
/// Almost everything that breaks a call is a decision — which signal to act
/// on, which to ignore, what may follow what — and inside a widget that owns
/// a peer connection none of it can be exercised without a relay and two
/// handsets. Pulled out, each one is three lines of test.
void main() {
  group('answering', () {
    test('an incoming call rings, then connects when accepted', () {
      final call = CallSession.incoming('abc');

      expect(call.state, CallState.ringing);
      expect(call.accept().state, CallState.connecting);
      expect(call.isTalking, isFalse,
          reason: 'Accepted is not connected. Audio has not started.');
    });

    /// A timer that starts before audio does makes every call look longer
    /// than it was, and the caller is billed for the difference.
    test('only media actually flowing counts as talking', () {
      final call = CallSession.incoming('abc')..accept();

      expect(call.isTalking, isFalse);
      call.mediaConnected();
      expect(call.isTalking, isTrue);
      expect(call.state, CallState.active);
    });

    /// They hung up while the thumb was moving.
    test('accepting a call that already ended does not resurrect it', () {
      final call = CallSession.incoming('abc');
      call.onSignal('abc', 'ended');

      expect(call.accept().state, CallState.ended);
      expect(call.endReason, CallEndReason.hungUp);
    });
  });

  group('placing a call', () {
    /// Offering before they accept wastes a peer connection and a
    /// microphone permission prompt on every unanswered call.
    test('the caller offers only once the other side accepts', () {
      final call = CallSession.outgoing('abc');

      expect(call.state, CallState.dialling);
      final outcome = call.onSignal('abc', 'accepted');
      expect(outcome.state, CallState.connecting);
      expect(outcome.effect, CallEffect.sendOffer);
    });

    test('a decline ends it with the reason, not just "ended"', () {
      final call = CallSession.outgoing('abc');

      final outcome = call.onSignal('abc', 'rejected');
      expect(outcome.state, CallState.ended);
      expect(outcome.effect, CallEffect.teardown);
      expect(call.endReason, CallEndReason.declined);
    });

    test('busy is its own ending', () {
      final call = CallSession.outgoing('abc')..onSignal('abc', 'busy');
      expect(call.endReason, CallEndReason.busy);
    });

    test('nobody answering is missed, not hung up', () {
      final call = CallSession.outgoing('abc');

      expect(call.ringTimeout().state, CallState.ended);
      expect(call.endReason, CallEndReason.missed);
    });

    test('a ring timeout after the call connected changes nothing', () {
      final call = CallSession.outgoing('abc')
        ..onSignal('abc', 'accepted')
        ..mediaConnected();

      call.ringTimeout();

      expect(call.state, CallState.active,
          reason: 'A late timer must not drop a call that is happening.');
    });
  });

  group('signals for somebody else', () {
    /// THE ONE THAT PROTECTS A LIVE CALL. A phone legitimately sees signals
    /// for calls it is not in: a second call arriving, a late message from
    /// one that ended. Acting on a stray signal tears down a live call.
    test('a signal for another call is ignored', () {
      final call = CallSession.outgoing('abc')
        ..onSignal('abc', 'accepted')
        ..mediaConnected();

      call.onSignal('a-different-call', 'ended');

      expect(call.state, CallState.active);
      expect(call.endReason, isNull);
    });

    test('late signals from a finished call are not errors', () {
      final call = CallSession.outgoing('abc')..end(CallEndReason.hungUp);

      expect(call.onSignal('abc', 'answer').effect, CallEffect.none);
      expect(call.onSignal('abc', 'ice', payload: 'x').effect, CallEffect.none);
      expect(call.state, CallState.ended);
    });

    test('an unknown signal does not drop a call in progress', () {
      final call = CallSession.outgoing('abc')
        ..onSignal('abc', 'accepted')
        ..mediaConnected();

      call.onSignal('abc', 'something-new-the-server-sends');

      expect(call.state, CallState.active);
    });
  });

  group('ICE candidates that arrive too early', () {
    /*
     * THE ONE THAT MATTERS MOST.
     *
     * The other phone gathers and sends candidates as soon as it has a local
     * description, which is routinely before its answer reaches us. A
     * candidate given to a peer connection with no remote description is
     * rejected, and the usual mistake is to drop it. The call then connects
     * only when the discarded candidates happened not to matter — some of
     * the time, on some networks. It works for the developer and fails for a
     * third of users, with nothing in any log.
     */
    test('candidates before the answer are held, not dropped', () {
      final call = CallSession.outgoing('abc')..onSignal('abc', 'accepted');

      expect(call.onSignal('abc', 'ice', payload: 'c1').effect, CallEffect.none);
      expect(call.onSignal('abc', 'ice', payload: 'c2').effect, CallEffect.none);
      expect(call.bufferedCandidateCount, 2);

      final outcome = call.onSignal('abc', 'answer');

      expect(outcome.effect, CallEffect.applyAnswer);
      expect(outcome.candidates, ['c1', 'c2'],
          reason: 'Every held candidate must be released, in order.');
      expect(call.bufferedCandidateCount, 0);
    });

    test('the callee holds them until it has applied the offer', () {
      final call = CallSession.incoming('abc')..accept();

      call.onSignal('abc', 'ice', payload: 'c1');
      expect(call.bufferedCandidateCount, 1);

      final outcome = call.onSignal('abc', 'offer');
      expect(outcome.effect, CallEffect.answerOffer);
      expect(outcome.candidates, ['c1']);
    });

    test('candidates after the answer go straight through', () {
      final call = CallSession.outgoing('abc')
        ..onSignal('abc', 'accepted')
        ..onSignal('abc', 'answer');

      final outcome = call.onSignal('abc', 'ice', payload: 'late');

      expect(outcome.effect, CallEffect.applyCandidates);
      expect(outcome.candidates, ['late']);
      expect(call.bufferedCandidateCount, 0);
    });

    test('an empty candidate is not buffered', () {
      final call = CallSession.outgoing('abc')..onSignal('abc', 'accepted');

      call.onSignal('abc', 'ice');

      expect(call.bufferedCandidateCount, 0);
    });

    test('held candidates are dropped when the call ends', () {
      final call = CallSession.outgoing('abc')
        ..onSignal('abc', 'accepted')
        ..onSignal('abc', 'ice', payload: 'c1');

      call.end(CallEndReason.hungUp);

      expect(call.bufferedCandidateCount, 0);
    });
  });

  group('glare', () {
    /// Both sides offering at once. The caller's offer wins; applying the
    /// callee's over our own leaves two descriptions and no call.
    test('the caller ignores an offer from the callee', () {
      final call = CallSession.outgoing('abc')..onSignal('abc', 'accepted');

      expect(call.onSignal('abc', 'offer').effect, CallEffect.none);
    });

    test('the callee ignores an answer it did not ask for', () {
      final call = CallSession.incoming('abc')..accept();

      expect(call.onSignal('abc', 'answer').effect, CallEffect.none);
    });
  });

  group('ending', () {
    /// The user taps as the other side drops. Both happen; the first reason
    /// is the true one.
    test('hanging up twice keeps the first reason', () {
      final call = CallSession.outgoing('abc')
        ..onSignal('abc', 'rejected');

      call.end(CallEndReason.hungUp);

      expect(call.endReason, CallEndReason.declined);
    });

    test('ending asks for teardown exactly once', () {
      final call = CallSession.outgoing('abc');

      expect(call.end(CallEndReason.cancelled).effect, CallEffect.teardown);
      expect(call.end(CallEndReason.hungUp).effect, CallEffect.none,
          reason: 'Releasing the microphone twice is a crash in waiting.');
    });

    test('media failing after answering ends the call as failed', () {
      final call = CallSession.outgoing('abc')
        ..onSignal('abc', 'accepted')
        ..mediaConnected();

      expect(call.mediaFailed().state, CallState.ended);
      expect(call.endReason, CallEndReason.failed);
    });

    test('ended is terminal', () {
      final call = CallSession.incoming('abc')..end(CallEndReason.declined);

      call.accept();
      call.mediaConnected();
      call.onSignal('abc', 'accepted');

      expect(call.state, CallState.ended);
    });
  });
}
