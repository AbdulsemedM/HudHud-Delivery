import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/vehicle_motion.dart';

/// A TickerProvider the test owns, so these assert on the motion's decisions
/// rather than on a clock.
///
/// Note what that means for the tests below: no frames are pumped, so the
/// marker never advances along a leg. Every test therefore places the marker
/// exactly with `animate: false` before exercising the next move. Writing
/// them any other way measures the position the marker has NOT yet moved
/// from, which is how the first draft of this file managed to test a
/// 111-metre move while claiming to test GPS jitter.
class _TestVsync extends TickerProvider {
  Ticker? ticker;

  @override
  Ticker createTicker(TickerCallback onTick) => ticker = Ticker(onTick);
}

void main() {
  // REQUIRED, and not obviously so: Ticker.start() reaches for
  // SchedulerBinding.instance, which a plain `test()` never initializes -
  // only `testWidgets()` does. Without this line every test that starts a
  // leg throws "Binding has not yet been initialized", while the tests that
  // snap or settle without ticking pass, so the suite looks half-broken
  // rather than unbound. No frames are pumped either way.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Addis Ababa. 0.0001 degrees of latitude is about 11 metres.
  const start = MotionPoint(9.0222, 38.7468);

  late _TestVsync vsync;
  late VehicleMotion motion;
  late int changes;

  setUp(() {
    vsync = _TestVsync();
    changes = 0;
    motion = VehicleMotion(vsync: vsync, onChanged: () => changes++);
  });

  // NOT `tearDown(motion.dispose)`: that evaluates the tear-off when the
  // test is REGISTERED, before `late motion` has been assigned, and the
  // whole file fails to load with "Local 'motion' has not been initialized".
  tearDown(() => motion.dispose());

  /// Put the marker exactly here, with no leg in flight.
  void placeAt(MotionPoint point) => motion.moveTo(point, animate: false);

  group('the first reading', () {
    test('is drawn exactly where it is, with no slide from nowhere', () {
      motion.moveTo(start);

      expect(motion.position, start);
      expect(motion.isMoving, isFalse,
          reason: 'A first fix has nothing to travel from.');
      expect(changes, 1);
    });
  });

  group('an ordinary move', () {
    test('animates rather than jumping', () {
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0232, 38.7468)); // ~111m north

      expect(motion.isMoving, isTrue);
      expect(motion.position, start,
          reason: 'Still at the old point until a frame runs.');
    });

    test('faces the direction of travel', () {
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0232, 38.7468)); // due north
      expect(motion.bearing, closeTo(0, 1));

      placeAt(start);
      motion.moveTo(const MotionPoint(9.0222, 38.7478)); // due east
      expect(motion.bearing, closeTo(90, 1));

      placeAt(start);
      motion.moveTo(const MotionPoint(9.0212, 38.7468)); // due south
      expect(motion.bearing, closeTo(180, 1));
    });

    test('the same position again is not a move', () {
      placeAt(start);
      final before = changes;

      motion.moveTo(start);

      expect(motion.isMoving, isFalse);
      expect(changes, before, reason: 'Nothing changed, so nothing redrew.');
    });
  });

  group('a jump that is not movement', () {
    /// THE ONE THAT MATTERS: sliding the marker across the city at a smooth
    /// crawl states something false about where the driver is.
    test('snaps instead of sliding when the gap is too large', () {
      placeAt(start);

      // ~2.2 km north: a GPS correction, a tunnel, an app restart.
      const far = MotionPoint(9.0422, 38.7468);
      motion.moveTo(far);

      expect(motion.isMoving, isFalse,
          reason: 'We did not watch that journey, so we must not draw it.');
      expect(motion.position, far);
    });

    test('a move just under the threshold still animates', () {
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0252, 38.7468)); // ~330m

      expect(motion.isMoving, isTrue);
    });
  });

  group('a vehicle standing still', () {
    /// A parked car's GPS wanders a few metres. Rotating to face each wander
    /// spins the marker on the spot, which reads as a fault in the app.
    test('does not spin on GPS jitter', () {
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0232, 38.7468)); // establish north
      final heading = motion.bearing;
      expect(heading, closeTo(0, 1));

      // About 2 metres east of where the marker actually is.
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0222, 38.74682));

      expect(motion.bearing, heading,
          reason: 'Too short a hop to carry a direction.');
    });

    test('but still moves to the jittered position', () {
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0222, 38.74682));

      expect(motion.isMoving, isTrue,
          reason: 'The heading is ignored, not the position.');
    });
  });

  group('reduced motion', () {
    /// On a map the position IS the content, so not animating loses nothing:
    /// the marker is simply always correct.
    test('tracks the real position exactly when animation is off', () {
      placeAt(start);
      const next = MotionPoint(9.0232, 38.7468);

      motion.moveTo(next, animate: false);

      expect(motion.isMoving, isFalse);
      expect(motion.position, next);
    });

    test('still faces the right way', () {
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0222, 38.7478), animate: false); // east

      expect(motion.bearing, closeTo(90, 1),
          reason: 'A still marker pointing the wrong way is still wrong.');
    });
  });

  group('the leg duration', () {
    /// The server's interval is advisory and has been seen as 0. Finishing
    /// instantly would make the marker hop, which is the bug this exists to
    /// remove.
    test('survives a nonsense interval from the server', () {
      placeAt(start);
      motion.moveTo(
        const MotionPoint(9.0232, 38.7468),
        expectedInterval: Duration.zero,
      );

      expect(motion.isMoving, isTrue);
    });

    test('caps an absurdly long interval', () {
      placeAt(start);
      motion.moveTo(
        const MotionPoint(9.0232, 38.7468),
        expectedInterval: const Duration(minutes: 5),
      );

      expect(motion.isMoving, isTrue);
    });
  });

  group('halting', () {
    test('stops moving and holds the last position', () {
      placeAt(start);
      motion.moveTo(const MotionPoint(9.0232, 38.7468));

      motion.halt();

      expect(motion.isMoving, isFalse);
      expect(motion.position, start);
    });

    test('can be halted twice without complaint', () {
      placeAt(start);
      motion.halt();
      motion.halt();

      expect(motion.isMoving, isFalse);
    });
  });
}
