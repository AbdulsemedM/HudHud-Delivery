import 'dart:math' as math;

/// Rectangle in degrees (south-west / north-east corners).
class CityBounds {
  final double south;
  final double west;
  final double north;
  final double east;

  const CityBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  bool contains(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;

  static CityBounds? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final s = _toDouble(raw['south']);
    final w = _toDouble(raw['west']);
    final n = _toDouble(raw['north']);
    final e = _toDouble(raw['east']);
    if (s == null || w == null || n == null || e == null) return null;
    if (s >= n || w >= e) return null;
    return CityBounds(south: s, west: w, north: n, east: e);
  }
}

/// One market's service area from `GET /api/markets?include=service_area`
/// (Phase 10). Used to centre maps, restrict place search to the city and
/// stop pins outside the area. The server enforces the same rule
/// (`CITY_*` error codes) when [enforced] is true.
class CityServiceArea {
  final String marketCode;
  final String marketName;
  final double? centerLat;
  final double? centerLng;
  final double radiusKm;
  final CityBounds? bounds;

  /// `[lat, lng]` pairs; empty unless the market has a drawn polygon.
  final List<List<double>> polygon;

  /// `polygon`, `bounds` or `radius`.
  final String shape;
  final String? countryCode;
  final bool enforced;

  const CityServiceArea({
    required this.marketCode,
    required this.marketName,
    this.centerLat,
    this.centerLng,
    this.radiusKm = 60,
    this.bounds,
    this.polygon = const [],
    this.shape = 'radius',
    this.countryCode,
    this.enforced = false,
  });

  bool get hasCenter => centerLat != null && centerLng != null;

  /// Same containment rule as the server's CityScopeService.
  bool contains(double lat, double lng) {
    if (shape == 'polygon' && polygon.length >= 3) {
      return _pointInPolygon(lat, lng);
    }
    if (shape == 'bounds' && bounds != null) {
      return bounds!.contains(lat, lng);
    }
    if (!hasCenter) return true;
    return distanceKm(lat, lng, centerLat!, centerLng!) <= radiusKm;
  }

  /// Google Places Autocomplete `locationrestriction` value.
  String? get autocompleteRestriction {
    final b = bounds;
    if (b == null) return null;
    return 'rectangle:${b.south},${b.west}|${b.north},${b.east}';
  }

  /// Google `components` filter (`country:so`), or null when unknown.
  String? get countryComponent {
    final cc = countryCode?.trim().toLowerCase();
    if (cc == null || cc.length != 2) return null;
    return 'country:$cc';
  }

  static CityServiceArea? fromJson(
    dynamic raw, {
    required String marketCode,
    required String marketName,
  }) {
    if (raw is! Map) return null;
    final center = raw['center'];
    final polygon = <List<double>>[];
    final rawPolygon = raw['polygon'];
    if (rawPolygon is List) {
      for (final point in rawPolygon) {
        if (point is Map) {
          final lat = _toDouble(point['lat']);
          final lng = _toDouble(point['lng']);
          if (lat != null && lng != null) polygon.add([lat, lng]);
        }
      }
    }
    return CityServiceArea(
      marketCode: marketCode,
      marketName: marketName,
      centerLat: center is Map ? _toDouble(center['lat']) : null,
      centerLng: center is Map ? _toDouble(center['lng']) : null,
      radiusKm: _toDouble(raw['radius_km']) ?? 60,
      bounds: CityBounds.fromJson(raw['bounds']),
      polygon: polygon,
      shape: raw['shape']?.toString() ?? 'radius',
      countryCode: raw['country_code']?.toString(),
      enforced: raw['enforced'] == true,
    );
  }

  bool _pointInPolygon(double lat, double lng) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final yi = polygon[i][0];
      final xi = polygon[i][1];
      final yj = polygon[j][0];
      final xj = polygon[j][1];
      final dy = (yj - yi) == 0 ? 1e-12 : (yj - yi);
      if (((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / dy + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthKm = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return earthKm * 2 * math.asin(math.min(1, math.sqrt(a)));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
