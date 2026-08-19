import '../../utils/delivery_notification.dart';

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LiveTrackingDriver {
  const LiveTrackingDriver({
    this.id,
    this.name,
    this.phone,
    this.vehicleType,
    this.vehicleColor,
    this.vehiclePlateNumber,
    this.rating,
  });

  final int? id;
  final String? name;
  final String? phone;
  final String? vehicleType;
  final String? vehicleColor;
  final String? vehiclePlateNumber;
  final double? rating;
}

class LiveTrackingDriverLocation {
  const LiveTrackingDriverLocation({
    this.latitude,
    this.longitude,
    this.heading,
    this.speedKph,
    this.accuracyMeters,
    this.recordedAt,
    this.ageSeconds,
    this.isLive = true,
  });

  final double? latitude;
  final double? longitude;
  final double? heading;
  final double? speedKph;
  final double? accuracyMeters;
  final DateTime? recordedAt;
  final int? ageSeconds;
  final bool isLive;

  bool get hasCoordinates => latitude != null && longitude != null;
}

class DeliveryLiveTracking {
  const DeliveryLiveTracking({
    this.kind,
    this.jobId,
    this.status,
    this.trackingAvailable = false,
    this.message,
    this.pollAfterSeconds = 10,
    this.driver,
    this.driverLocation,
    this.destinationLabel,
    this.destination,
    this.routeOrigin,
    this.routeDestination,
    this.estimatedArrivalMinutes,
  });

  final String? kind;
  final int? jobId;
  final String? status;
  final bool trackingAvailable;
  final String? message;
  final int pollAfterSeconds;
  final LiveTrackingDriver? driver;
  final LiveTrackingDriverLocation? driverLocation;
  final String? destinationLabel;
  final GeoPoint? destination;
  final GeoPoint? routeOrigin;
  final GeoPoint? routeDestination;
  final int? estimatedArrivalMinutes;

  /// Prefer the API destination label; otherwise infer from delivery status.
  String get effectiveDestinationLabel {
    final fromApi = destinationLabel?.toLowerCase().trim();
    if (fromApi == 'pickup' || fromApi == 'dropoff') return fromApi!;
    return destinationLabelForDeliveryStatus(status);
  }
}

/// Pickup vs dropoff route target from canonical delivery status.
String destinationLabelForDeliveryStatus(String? status) {
  final normalized = normalizeDeliveryStatus(status);
  const pickup = {'pickup_assigned', 'en_route_pickup', 'at_pickup'};
  const dropoff = {'en_route_dropoff', 'at_dropoff'};
  if (dropoff.contains(normalized)) return 'dropoff';
  if (pickup.contains(normalized)) return 'pickup';
  return 'pickup';
}

/// Keep the last valid marker; never replace coordinates with null.
GeoPoint? retainDriverLocation({
  required GeoPoint? previous,
  required LiveTrackingDriverLocation? incoming,
}) {
  if (incoming != null && incoming.hasCoordinates) {
    return GeoPoint(
      latitude: incoming.latitude!,
      longitude: incoming.longitude!,
    );
  }
  return previous;
}

DeliveryLiveTracking parseDeliveryLiveTrackingResponse(dynamic response) {
  final root = _asMap(response);
  final nestedData = _asMap(root['data']);
  final trackingMap = _asMap(root['tracking']).isNotEmpty
      ? _asMap(root['tracking'])
      : (_asMap(nestedData['tracking']).isNotEmpty
          ? _asMap(nestedData['tracking'])
          : (nestedData.isNotEmpty ? nestedData : root));

  final driverMap = _asMap(trackingMap['driver']);
  LiveTrackingDriver? driver;
  if (driverMap.isNotEmpty) {
    driver = LiveTrackingDriver(
      id: _firstInt([driverMap['id']]),
      name: _firstString([driverMap['name']]),
      phone: _firstString([driverMap['phone'], driverMap['mobile']]),
      vehicleType: _firstString([driverMap['vehicle_type']]),
      vehicleColor: _firstString([driverMap['vehicle_color']]),
      vehiclePlateNumber: _firstString([
        driverMap['vehicle_plate_number'],
        driverMap['plate_number'],
      ]),
      rating: _firstDouble([driverMap['rating']]),
    );
  }

  final locMap = _asMap(trackingMap['driver_location']);
  LiveTrackingDriverLocation? driverLocation;
  if (locMap.isNotEmpty) {
    driverLocation = LiveTrackingDriverLocation(
      latitude: _firstDouble([locMap['latitude'], locMap['lat']]),
      longitude: _firstDouble([locMap['longitude'], locMap['lng']]),
      heading: _firstDouble([locMap['heading']]),
      speedKph: _firstDouble([locMap['speed_kph'], locMap['speed']]),
      accuracyMeters: _firstDouble([locMap['accuracy_meters'], locMap['accuracy']]),
      recordedAt: DateTime.tryParse(locMap['recorded_at']?.toString() ?? ''),
      ageSeconds: _firstInt([locMap['age_seconds']]),
      isLive: locMap['is_live'] != false,
    );
  }

  final destMap = _asMap(trackingMap['destination']);
  GeoPoint? destination;
  if (destMap.isNotEmpty) {
    final lat = _firstDouble([destMap['latitude'], destMap['lat']]);
    final lng = _firstDouble([destMap['longitude'], destMap['lng']]);
    if (lat != null && lng != null) {
      destination = GeoPoint(latitude: lat, longitude: lng);
    }
  }

  final routeMap = _asMap(trackingMap['route']);
  final originMap = _asMap(routeMap['origin']);
  final routeDestMap = _asMap(routeMap['destination']);

  final poll = _firstInt([
        trackingMap['poll_after_seconds'],
        trackingMap['pollAfterSeconds'],
      ]) ??
      (trackingMap['tracking_available'] == true ? 7 : 10);

  return DeliveryLiveTracking(
    kind: _firstString([trackingMap['kind']]),
    jobId: _firstInt([trackingMap['job_id'], trackingMap['id']]),
    status: _firstString([trackingMap['status']]),
    trackingAvailable: trackingMap['tracking_available'] == true,
    message: _firstString([trackingMap['message'], root['message']]),
    pollAfterSeconds: poll < 1 ? 10 : poll,
    driver: driver,
    driverLocation: driverLocation,
    destinationLabel: _firstString([destMap['label']]),
    destination: destination,
    routeOrigin: _geoFromMap(originMap),
    routeDestination: _geoFromMap(routeDestMap),
    estimatedArrivalMinutes: _firstInt([
      trackingMap['estimated_arrival_minutes'],
    ]),
  );
}

GeoPoint? _geoFromMap(Map<String, dynamic> map) {
  if (map.isEmpty) return null;
  final lat = _firstDouble([map['latitude'], map['lat']]);
  final lng = _firstDouble([map['longitude'], map['lng']]);
  if (lat == null || lng == null) return null;
  return GeoPoint(latitude: lat, longitude: lng);
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
