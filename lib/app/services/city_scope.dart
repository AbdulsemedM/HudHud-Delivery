import '../models/city_service_area.dart';

/// Result of a client-side one-city check (mirrors the server's CITY_* codes).
enum CityCheck {
  ok,

  /// A point is outside every served city (`CITY_OUTSIDE_SERVICE_AREA`).
  outside,

  /// Points are in two different cities (`CITY_CROSS_MARKET`).
  crossCity,

  /// Points are in a city other than the selected one (`CITY_MARKET_MISMATCH`).
  otherCity,
}

/// Phase 10 city scoping on the device.
///
/// MarketController publishes the service areas of all active markets and
/// the selected one here, so map pickers and place search (which live in the
/// app layer) can centre on, and stay inside, the customer's city without
/// depending on the growth feature. Empty (pre-Phase-10 backend) means "no
/// restriction": everything behaves as before.
class CityScope {
  CityScope._();

  static List<CityServiceArea> _areas = const [];
  static CityServiceArea? _current;

  static List<CityServiceArea> get areas => _areas;

  /// The selected market's area (null when unknown).
  static CityServiceArea? get current => _current;

  /// Pins outside the city are blocked only when the server enforces it.
  static bool get enforced => _current?.enforced ?? false;

  static void update({
    required List<CityServiceArea> areas,
    CityServiceArea? current,
  }) {
    _areas = List.unmodifiable(areas);
    _current = current;
  }

  static void reset() {
    _areas = const [];
    _current = null;
  }

  /// The served city containing the point (selected city first).
  static CityServiceArea? areaAt(double lat, double lng) {
    final selected = _current;
    if (selected != null && selected.contains(lat, lng)) return selected;
    for (final area in _areas) {
      if (area.contains(lat, lng)) return area;
    }
    return null;
  }

  /// True when the point may be used as a pin in the current city.
  static bool allowsPin(double lat, double lng) {
    final selected = _current;
    if (selected == null || !selected.enforced) return true;
    return selected.contains(lat, lng);
  }

  /// One-city rule for a request's points (pickup, drop-off, …).
  static CityCheck check(List<List<double>> points) {
    if (_areas.isEmpty && _current == null) return CityCheck.ok;
    String? code;
    for (final point in points) {
      final area = areaAt(point[0], point[1]);
      if (area == null) return CityCheck.outside;
      if (code != null && code != area.marketCode) return CityCheck.crossCity;
      code = area.marketCode;
    }
    final selected = _current;
    if (selected != null && code != null && code != selected.marketCode) {
      return CityCheck.otherCity;
    }
    return CityCheck.ok;
  }
}
