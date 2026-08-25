/// Anonymous nearby vehicle marker. [markerId] is a map key only — never a driver id.
class NearbyDriverMarker {
  const NearbyDriverMarker({
    required this.markerId,
    required this.latitude,
    required this.longitude,
    this.label,
    this.vehicleType,
    this.heading,
    this.distanceKm,
    this.estimatedPickupMinutes,
    this.rank,
  });

  final String markerId;
  final double latitude;
  final double longitude;
  final String? label;
  final String? vehicleType;
  final double? heading;
  final double? distanceKm;
  final int? estimatedPickupMinutes;
  final int? rank;
}

class NearbyDriversResult {
  const NearbyDriversResult({
    this.drivers = const [],
    this.total = 0,
    this.refreshAfterSeconds = 15,
    this.privacyMessage,
  });

  final List<NearbyDriverMarker> drivers;
  final int total;
  final int refreshAfterSeconds;
  final String? privacyMessage;
}

NearbyDriversResult parseNearbyDriversResponse(dynamic response) {
  final root = _asMap(response);
  final payload = _asMap(root['data']).isNotEmpty ? _asMap(root['data']) : root;

  final driversRaw = payload['drivers'];
  final drivers = <NearbyDriverMarker>[];
  if (driversRaw is List) {
    for (final item in driversRaw) {
      final map = _asMap(item);
      final markerId = _firstString([map['marker_id'], map['markerId']]);
      final lat = _firstDouble([map['latitude'], map['lat']]);
      final lng = _firstDouble([map['longitude'], map['lng']]);
      if (markerId == null || lat == null || lng == null) continue;
      drivers.add(
        NearbyDriverMarker(
          markerId: markerId,
          latitude: lat,
          longitude: lng,
          label: _firstString([map['label']]),
          vehicleType: _firstString([map['vehicle_type']]),
          heading: _firstDouble([map['heading']]),
          distanceKm: _firstDouble([map['distance_km']]),
          estimatedPickupMinutes: _firstInt([map['estimated_pickup_minutes']]),
          rank: _firstInt([map['rank']]),
        ),
      );
    }
  }

  final privacy = _asMap(payload['privacy']);
  final refresh = _firstInt([
        payload['refresh_after_seconds'],
        payload['refreshAfterSeconds'],
      ]) ??
      15;

  return NearbyDriversResult(
    drivers: drivers,
    total: _firstInt([payload['total']]) ?? drivers.length,
    refreshAfterSeconds: refresh < 1 ? 15 : refresh,
    privacyMessage: _firstString([
      privacy['message'],
      payload['privacy_message'],
    ]),
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int? _firstInt(List<dynamic> candidates) {
  for (final c in candidates) {
    if (c == null) continue;
    final parsed = int.tryParse(c.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

double? _firstDouble(List<dynamic> candidates) {
  for (final c in candidates) {
    if (c == null) continue;
    if (c is num) return c.toDouble();
    final parsed = double.tryParse(c.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String? _firstString(List<dynamic> candidates) {
  for (final c in candidates) {
    final s = c?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
  }
  return null;
}
