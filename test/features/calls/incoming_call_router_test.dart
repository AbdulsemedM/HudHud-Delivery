import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/calls/incoming_call_router.dart';

/// Reading a call out of a push payload.
///
/// This is the only thing between a courier ringing and a phone that stays
/// dark, and every way of getting it wrong is silent: a payload read wrong
/// means no ring and no error.
void main() {
  group('IncomingCallPush.fromData', () {
    Map<String, dynamic> ring({Object? callerId = '41'}) => {
          'kind': 'call_signal',
          'call_uid': 'abc-123',
          'signal': 'incoming',
          'caller_name': 'Selam',
          'caller_id': callerId,
        };

    test('reads a ring', () {
      final push = IncomingCallPush.fromData(ring());
      expect(push, isNotNull);
      expect(push!.callUid, 'abc-123');
      expect(push.isRing, isTrue);
      expect(push.callerName, 'Selam');
      expect(push.callerId, 41);
    });

    /// THE ONE THAT BITES. FCM data values are strings, always — a numeric
    /// id arrives as "41", not 41. Reading it as an int gives null on every
    /// real push while passing a test that hands it an int.
    test('accepts a numeric id as the string FCM actually sends', () {
      expect(IncomingCallPush.fromData(ring(callerId: '41'))!.callerId, 41);
      expect(IncomingCallPush.fromData(ring(callerId: 41))!.callerId, 41);
      expect(IncomingCallPush.fromData(ring(callerId: 'nope'))!.callerId, isNull);
      expect(IncomingCallPush.fromData(ring(callerId: null))!.callerId, isNull);
    });

    test('ignores a push that is not about a call', () {
      expect(IncomingCallPush.fromData({'kind': 'order_update', 'order_id': '9'}), isNull);
      expect(IncomingCallPush.fromData(null), isNull);
      expect(IncomingCallPush.fromData({}), isNull);
    });

    /// Without a uid there is no call to join, and acting on it would ring a
    /// phone that can never connect.
    test('refuses a call push with nothing to join', () {
      expect(IncomingCallPush.fromData({'kind': 'call_signal', 'signal': 'incoming'}), isNull);
      expect(
        IncomingCallPush.fromData({'kind': 'call_signal', 'call_uid': '', 'signal': 'incoming'}),
        isNull,
      );
      expect(
        IncomingCallPush.fromData({'kind': 'call_signal', 'call_uid': 'x', 'signal': ''}),
        isNull,
      );
    });

    /// accepted/ended also arrive by push, and must NOT ring the phone.
    test('only an incoming signal rings', () {
      for (final signal in ['accepted', 'rejected', 'ended', 'busy']) {
        final push = IncomingCallPush.fromData({
          'kind': 'call_signal', 'call_uid': 'x', 'signal': signal,
        });
        expect(push, isNotNull, reason: signal);
        expect(push!.isRing, isFalse, reason: signal);
      }
    });

    /// An empty name is not a name. Showing "" on a full-screen ring tells
    /// the person nothing about who is calling.
    test('a blank caller name becomes null, not an empty string', () {
      final push = IncomingCallPush.fromData({
        'kind': 'call_signal', 'call_uid': 'x', 'signal': 'incoming', 'caller_name': '   ',
      });
      expect(push!.callerName, isNull);
    });

    /// Support calls carry the company name. The agent's own name must
    /// never reach the phone, and the server is what guarantees that — this
    /// just pins that whatever it sends is what gets shown.
    test('shows the name the server sent', () {
      final push = IncomingCallPush.fromData({
        'kind': 'call_signal', 'call_uid': 'x', 'signal': 'incoming',
        'caller_name': 'HudHud Support',
      });
      expect(push!.callerName, 'HudHud Support');
    });
  });
}
