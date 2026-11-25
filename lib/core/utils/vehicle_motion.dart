import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

/// A point, belonging to no map package.
///
/// This class deliberately does NOT use google_maps_flutter's MotionPoint or
/// latlong2's. Both are in these apps already, under the same name, and the
/// screens mix them: the tracking screen's unqualified `LatLng` is latlong2
/// while its markers take the Google one. A motion helper that picked either
/// would compile against half its callers - which is exactly how the first
/// version of this file failed analysis.
///
/// Callers convert at the boundary, where the type they want is obvious.
class MotionPoint {
  const MotionPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is MotionPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'MotionPoint($latitude, $longitude)';
}

/// Moves the driver's marker between the positions we are told about.
///
/// The driver's location arrives by poll, roughly every seven seconds. Drawn
/// straight onto the map it teleports: the car sits still, vanishes, and
/// reappears a street away. A customer watching it cannot tell whether the
/// driver is moving, stopped, or whether tracking has failed - which is the
/// one question the screen exists to answer.
///
/// So the marker is walked from where it was to where it now is, over the
/// interval until the next update is expected.
///
/// FOUR DECISIONS WORTH THE WORDS:
///
/// 1. LINEAR, NOT EASED. Every instinct says ease-in-out, and it is wrong
///    here. A car at constant speed would appear to accelerate away from
///    each point and brake into the next, seven seconds apart, forever. The
///    motion is continuous, so the interpolation is linear and the only
///    honest reading of "moving steadily" survives.
///
/// 2. THE DURATION IS THE POLL INTERVAL. Finish early and the marker stops
///    dead and waits, which reads as the driver pulling over. Finish late
///    and it falls progressively further behind where the driver actually
///    is. Arriving exactly as the next fix lands is what makes it look like
///    one continuous journey rather than a series of hops.
///
/// 3. A BIG JUMP IS NOT MOVEMENT. GPS corrects itself, a phone reconnects
///    after a tunnel, a driver's app restarts. Sliding the marker two
///    kilometres across the city at a smooth crawl states something false
///    about where the driver is. Past [_snapMetres] the marker snaps, which
///    is honest: we do not know how they got there.
///
/// 4. BEARING ONLY WHEN THERE IS ONE. A stationary vehicle's GPS wanders a
///    few metres at random, and rotating to face each wander spins the car
///    on the spot. Below [_bearingMetres] the heading is left alone.
///
/// Reduced motion is handled by the caller, which passes [animate] false:
/// the marker then tracks the real position exactly. Nothing is lost by
/// that, because on a map the position IS the content - the animation only
/// ever existed to make the gaps between readings legible.
class VehicleMotion {
  VehicleMotion({required TickerProvider vsync, required this.onChanged}) {
    _ticker = vsync.createTicker(_tick);
  }

  /// Called on every frame the marker moves. The caller rebuilds.
  final void Function() onChanged;

  /// Further than this between two readings and we snap instead of sliding.
  /// Roughly a city block at the low end of what a GPS jump looks like.
  static const double _snapMetres = 400;

  /// Shorter than this and the bearing is noise, not a direction.
  static const double _bearingMetres = 8;

  /// Guard rails on how long one leg may take. The server's poll interval is
  /// advisory and has been seen as 0.
  static const Duration _minLeg = Duration(milliseconds: 600);
  static const Duration _maxLeg = Duration(seconds: 20);

  late final Ticker _ticker;

  MotionPoint? _from;
  MotionPoint? _to;
  Duration _legDuration = const Duration(seconds: 7);
  Duration _elapsed = Duration.zero;

  MotionPoint? _current;
  double _bearing = 0;

  /// Where to draw the marker right now.
  MotionPoint? get position => _current;

  /// Which way the vehicle is pointing, degrees clockwise from north.
  double get bearing => _bearing;

  bool get isMoving => _ticker.isActive;

  /// A new reading from the server.
  ///
  /// [expectedInterval] is how long until the next one is expected - the
  /// server tells us, and it is what the leg is timed against.
  void moveTo(
    MotionPoint target, {
    Duration? expectedInterval,
    bool animate = true,
  }) {
    final previous = _current;

    if (previous == null || !animate) {
      // First fix, or motion is off: be exactly where we are told. The
      // heading is still worth having - a still marker pointing the wrong
      // way is still wrong.
      _settleAt(target, from: previous);
      return;
    }

    if (_samePlace(previous, target)) {
      return;
    }

    final distance = _metresBetween(previous, target);

    if (distance > _snapMetres) {
      // Not a journey we watched. Say where they are, not how they got there.
      _settleAt(target, from: previous);
      return;
    }

    if (distance >= _bearingMetres) {
      _bearing = _bearingBetween(previous, target);
    }

    _from = previous;
    _to = target;
    _elapsed = Duration.zero;
    _legDuration = _clampLeg(expectedInterval ?? const Duration(seconds: 7));

    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  /// Stop moving and hold the last position. For a delivery that has ended,
  /// or a screen that is no longer visible.
  void halt() {
    if (_ticker.isActive) _ticker.stop();
    _from = null;
    _to = null;
  }

  void dispose() {
    // A screen can be closed mid-leg. Ticker.dispose() asserts the ticker is
    // not active, so stopping first is what makes closing the map during a
    // move survive debug builds.
    if (_ticker.isActive) _ticker.stop(canceled: true);
    _ticker.dispose();
  }

  // ── internals ──────────────────────────────────────────────────────────

  void _settleAt(MotionPoint target, {MotionPoint? from}) {
    if (from != null && _metresBetween(from, target) >= _bearingMetres) {
      _bearing = _bearingBetween(from, target);
    }
    if (_ticker.isActive) _ticker.stop();
    _from = null;
    _to = null;
    _current = target;
    onChanged();
  }

  Duration _clampLeg(Duration proposed) {
    if (proposed < _minLeg) return _minLeg;
    if (proposed > _maxLeg) return _maxLeg;
    return proposed;
  }

  void _tick(Duration elapsed) {
    final from = _from;
    final to = _to;
    if (from == null || to == null) {
      _ticker.stop();
      return;
    }

    _elapsed = elapsed;
    final t = _legDuration.inMicroseconds == 0
        ? 1.0
        : (_elapsed.inMicroseconds / _legDuration.inMicroseconds).clamp(0.0, 1.0);

    // Linear. See decision 1 above; easing here would invent acceleration
    // the vehicle does not have.
    _current = MotionPoint(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );

    if (t >= 1.0) {
      _current = to;
      _from = null;
      _to = null;
      _ticker.stop();
    }

    onChanged();
  }

  static bool _samePlace(MotionPoint a, MotionPoint b) =>
      (a.latitude - b.latitude).abs() < 1e-7 && (a.longitude - b.longitude).abs() < 1e-7;

  /// Great-circle distance in metres. Short legs, so the earth is a sphere.
  static double _metresBetween(MotionPoint a, MotionPoint b) {
    const earthRadius = 6371000.0;
    final dLat = _radians(b.latitude - a.latitude);
    final dLng = _radians(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(a.latitude)) *
            math.cos(_radians(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Degrees clockwise from north, which is what Marker.rotation wants.
  static double _bearingBetween(MotionPoint from, MotionPoint to) {
    final lat1 = _radians(from.latitude);
    final lat2 = _radians(to.latitude);
    final dLng = _radians(to.longitude - from.longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    return (_degrees(math.atan2(y, x)) + 360) % 360;
  }

  static double _radians(double degrees) => degrees * math.pi / 180.0;

  static double _degrees(double radians) => radians * 180.0 / math.pi;
}
