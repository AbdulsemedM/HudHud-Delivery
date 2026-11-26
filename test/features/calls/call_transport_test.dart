import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/calls/call_transport.dart';

/// The polling transport, without a network.
///
/// Signalling was broadcast-only and this app has no websocket client, so
/// signals now arrive by draining an HTTP mailbox. Three things about that
/// drain decide whether a call connects, and all three are invisible on a
/// working network:
///
///  - the cursor must only move forward, or a retry redelivers `ended` and
///    tears down whatever call came next;
///  - a failed poll must not reset it, and mobile data fails polls;
///  - a terminal status must stop the loop, or a finished call keeps
///    polling for the life of the app.
class _FakeSource implements CallSignalSource {
  _FakeSource(this.responses);

  /// One entry per drain, in order. A [DrainResult] is returned; an
  /// [Exception] is thrown.
  final List<Object> responses;
  final List<int> cursorsSeen = [];
  int _i = 0;

  @override
  Future<DrainResult> drain(String callUid, int after) async {
    cursorsSeen.add(after);
    if (_i >= responses.length) return DrainResult(signals: const [], cursor: after);
    final next = responses[_i++];
    if (next is Exception) throw next;
    return next as DrainResult;
  }
}

CallSignalMessage msg(int id, String type, {Object? data}) =>
    CallSignalMessage(id: id, type: type, data: data);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallSignalMessage.fromJson', () {
    test('reads a well-formed signal', () {
      final m = CallSignalMessage.fromJson({
        'id': 4, 'type': 'offer', 'data': {'sdp': 'v=0'},
      });
      expect(m, isNotNull);
      expect(m!.id, 4);
      expect(m.type, 'offer');
      expect((m.data as Map)['sdp'], 'v=0');
    });

    /// A malformed row must be skipped, not crash the poll that carries the
    /// rest of the negotiation with it.
    test('refuses anything it cannot read', () {
      expect(CallSignalMessage.fromJson(null), isNull);
      expect(CallSignalMessage.fromJson('offer'), isNull);
      expect(CallSignalMessage.fromJson({'type': 'offer'}), isNull);
      expect(CallSignalMessage.fromJson({'id': 1}), isNull);
      expect(CallSignalMessage.fromJson({'id': '1', 'type': 'offer'}), isNull);
      expect(CallSignalMessage.fromJson({'id': 1, 'type': ''}), isNull);
    });
  });

  group('CallSignalPoller', () {
    test('hands every signal to the callback in order', () async {
      final source = _FakeSource([
        DrainResult(signals: [msg(1, 'accepted'), msg(2, 'offer')], cursor: 2),
      ]);
      final seen = <String>[];

      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (s) => seen.add(s.type),
        interval: const Duration(milliseconds: 5),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 40));
      poller.stop();

      expect(seen, ['accepted', 'offer']);
    });

    /// THE ONE THAT MATTERS. A cursor that goes backwards redelivers the
    /// whole call, `ended` included, and ends a call that had been replaced.
    test('the cursor only ever moves forward', () async {
      final source = _FakeSource([
        DrainResult(signals: [msg(5, 'ice')], cursor: 5),
        // A server that answers with a stale cursor must not drag us back.
        DrainResult(signals: const [], cursor: 0),
      ]);

      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (_) {},
        interval: const Duration(milliseconds: 5),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 40));
      poller.stop();

      expect(poller.cursor, 5);
      expect(source.cursorsSeen.last, 5);
    });

    /// Mobile data fails polls. A failure that reset the cursor would
    /// replay the call; one that stopped the loop would strand it.
    test('a failed poll keeps the cursor and keeps going', () async {
      final source = _FakeSource([
        DrainResult(signals: [msg(3, 'offer')], cursor: 3),
        Exception('network'),
        DrainResult(signals: [msg(4, 'ice')], cursor: 4),
      ]);
      final seen = <int>[];

      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (s) => seen.add(s.id),
        interval: const Duration(milliseconds: 5),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 60));
      poller.stop();

      expect(seen, [3, 4]);
      expect(poller.cursor, 4);
    });

    test('a replayed signal is not handled twice', () async {
      final source = _FakeSource([
        DrainResult(signals: [msg(7, 'ended')], cursor: 7),
        DrainResult(signals: [msg(7, 'ended')], cursor: 7),
      ]);
      var endedCount = 0;

      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (s) {
          if (s.type == 'ended') endedCount++;
        },
        interval: const Duration(milliseconds: 5),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      poller.stop();

      expect(endedCount, 1);
    });

    test('a terminal status stops the loop', () async {
      final source = _FakeSource([
        DrainResult(signals: const [], cursor: 0, status: 'ended'),
      ]);
      final statuses = <String>[];

      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (_) {},
        onStatus: statuses.add,
        interval: const Duration(milliseconds: 5),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(poller.isRunning, isFalse);
      expect(statuses, contains('ended'));
      final pollsWhenStopped = source.cursorsSeen.length;

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(source.cursorsSeen.length, pollsWhenStopped);
    });

    test('an in-progress status does not stop the loop', () async {
      final source = _FakeSource([
        DrainResult(signals: const [], cursor: 0, status: 'answered'),
      ]);

      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (_) {},
        interval: const Duration(milliseconds: 5),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(poller.isRunning, isTrue);
      poller.stop();
    });

    test('stop() means stop', () async {
      final source = _FakeSource([]);
      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (_) {},
        interval: const Duration(milliseconds: 5),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 20));
      poller.stop();
      final polls = source.cursorsSeen.length;

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(source.cursorsSeen.length, polls);
    });

    test('start() twice does not run two loops', () async {
      final source = _FakeSource([]);
      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (_) {},
        interval: const Duration(milliseconds: 10),
      )..start();
      poller.start();

      await Future<void>.delayed(const Duration(milliseconds: 35));
      poller.stop();

      // Two loops would roughly double this. Generous bound: the point is
      // that it is not 2x, not an exact count on a loaded CI box.
      expect(source.cursorsSeen.length, lessThan(7));
    });

    /// A quiet call must not keep polling at negotiation speed for its whole
    /// duration — that is a request a second for every call on the platform.
    test('it slows down once nothing is happening', () async {
      final source = _FakeSource([]);
      final poller = CallSignalPoller(
        source: source,
        callUid: 'c1',
        onSignal: (_) {},
        interval: const Duration(milliseconds: 5),
        idleInterval: const Duration(milliseconds: 200),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 120));
      poller.stop();

      // Three quick rounds, then it backs off; without the backoff this
      // would be ~24.
      expect(source.cursorsSeen.length, lessThanOrEqualTo(6));
    });
  });

  group('terminalCallStatuses', () {
    test('covers every way a call stops', () {
      expect(terminalCallStatuses, containsAll(['ended', 'rejected', 'missed', 'failed']));
    });

    /// `answered` and `ringing` are live. Treating either as terminal would
    /// hang up on a working call.
    test('does not include a live status', () {
      expect(terminalCallStatuses.contains('answered'), isFalse);
      expect(terminalCallStatuses.contains('ringing'), isFalse);
    });
  });
}
