/// Minimum weight (kg) used for early estimates before package details are entered.
const kCourierEstimateMinWeightKg = 1.0;

/// Minimum quantity used for early estimates before package details are entered.
const kCourierEstimateMinQuantity = 1;

/// Effective placeholder weight sent to the estimate API (min weight × min quantity).
const kCourierEstimatePlaceholderWeightKg =
    kCourierEstimateMinWeightKg * kCourierEstimateMinQuantity;

/// Generic package type for early estimates before item type is selected.
const kCourierEstimatePlaceholderPackageType = 'other';

/// Maps booking mode to the API `service_type` used by both estimate and create.
String deliveryServiceType({required bool isInstantDelivery}) {
  return isInstantDelivery ? 'same_day' : 'standard';
}

/// Maps legacy UI vehicle ids to API `vehicle_type`. API values pass through.
String mapCourierVehicleType(String vehicle) {
  const mapping = {
    'motorcycle': 'motorbike',
    'car': 'car',
    'van': 'van',
  };
  return mapping[vehicle] ?? vehicle;
}

/// Aligns the current selection with server-returned vehicle types.
({List<String> types, String? selected}) applyCourierSupportedVehicleTypes({
  required List<String> supportedVehicleTypes,
  String? selectedVehicleType,
}) {
  final types = supportedVehicleTypes
      .map((e) => mapCourierVehicleType(e.trim()))
      .where((e) => e.isNotEmpty)
      .toList();
  final current = selectedVehicleType == null || selectedVehicleType.isEmpty
      ? null
      : mapCourierVehicleType(selectedVehicleType);
  final selected = current != null && types.contains(current)
      ? current
      : (types.isEmpty ? null : types.first);
  return (types: types, selected: selected);
}

/// JSON body for POST /api/services/delivery/estimate.
Map<String, dynamic> buildDeliveryEstimateRequestBody({
  required String packageType,
  required double packageWeight,
  required double pickupLatitude,
  required double pickupLongitude,
  required double dropoffLatitude,
  required double dropoffLongitude,
  required String vehicleType,
  required String serviceType,
  String? pickupLocation,
  String? scheduledPickup,
}) {
  final body = <String, dynamic>{
    'package_type': packageType,
    'package_weight': packageWeight,
    'pickup_latitude': pickupLatitude,
    'pickup_longitude': pickupLongitude,
    'dropoff_latitude': dropoffLatitude,
    'dropoff_longitude': dropoffLongitude,
    'vehicle_type': vehicleType,
    'service_type': serviceType,
  };
  final pickup = pickupLocation?.trim();
  if (pickup != null && pickup.isNotEmpty) {
    body['pickup_location'] = pickup;
  }
  if (scheduledPickup != null && scheduledPickup.isNotEmpty) {
    body['scheduled_pickup'] = scheduledPickup;
  }
  return body;
}

/// Builds a [DeliveryEstimate] from [CourierRepository.estimateDelivery] output.
DeliveryEstimate? deliveryEstimateFromRepositoryResult(
  Map<String, dynamic> result,
) {
  if (result['success'] != true) return null;
  final estimate = DeliveryEstimate(
    estimatedCost: result['estimatedCost'] as double?,
    estimatedDistance: result['estimatedDistance'] as double?,
    estimatedDuration: result['estimatedDuration'] as int?,
    currency: result['currency'] as String? ?? 'ETB',
    baseDeliveryFee: result['baseDeliveryFee'] as double?,
    distanceRate: result['distanceRate'] as double?,
    freeDistance: result['freeDistance'] as double?,
    weightCharge: result['weightCharge'] as double?,
    timeBandName: result['timeBandName'] as String?,
    timeBandMultiplier: result['timeBandMultiplier'] as double?,
    timeBandSurchargeRate: result['timeBandSurchargeRate'] as double?,
    timeBandSurcharge: result['timeBandSurcharge'] as double?,
    evaluatedPickupAt: result['evaluatedPickupAt'] as String?,
    timezone: result['timezone'] as String?,
    nightHoursStart: result['nightHoursStart'] as int?,
    nightHoursEnd: result['nightHoursEnd'] as int?,
    vehicleType: result['vehicleType'] as String?,
  );
  return estimate.isValid ? estimate : null;
}

/// Formats a picker wall-clock time as Africa/Addis_Ababa ISO-8601 with fixed +03:00.
///
/// Ethiopia has no DST. Calendar fields are treated as Addis Ababa local time;
/// the device timezone offset is ignored so quote and create send the same string.
String formatDeliveryScheduledPickup(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$y-$m-${d}T$h:$min:$s+03:00';
}

/// Server quote from POST /api/services/delivery/estimate. Cost is never derived locally.
class DeliveryEstimate {
  const DeliveryEstimate({
    this.estimatedCost,
    this.estimatedDistance,
    this.estimatedDuration,
    this.currency = 'ETB',
    this.baseDeliveryFee,
    this.distanceRate,
    this.freeDistance,
    this.weightCharge,
    this.timeBandName,
    this.timeBandMultiplier,
    this.timeBandSurchargeRate,
    this.timeBandSurcharge,
    this.evaluatedPickupAt,
    this.timezone,
    this.nightHoursStart,
    this.nightHoursEnd,
    this.vehicleType,
  });

  final double? estimatedCost;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final String currency;
  final double? baseDeliveryFee;
  final double? distanceRate;
  final double? freeDistance;
  final double? weightCharge;

  /// From `pricing.time_band.name` (e.g. `day`, `night`). Never infer locally.
  final String? timeBandName;
  final double? timeBandMultiplier;
  final double? timeBandSurchargeRate;
  final double? timeBandSurcharge;
  final String? evaluatedPickupAt;
  final String? timezone;
  final int? nightHoursStart;
  final int? nightHoursEnd;

  /// From API `vehicle_type` (e.g. `bicycle`, `motorbike`). Never infer locally.
  final String? vehicleType;

  bool get isValid => estimatedCost != null;

  /// True when the API returned a positive time-band surcharge to display.
  bool get hasTimeBandSurcharge =>
      timeBandSurcharge != null && timeBandSurcharge! > 0;
}

/// Parses estimate JSON — flat, nested `{ data: ... }`, or generic Map from Dio.
DeliveryEstimate parseDeliveryEstimate(dynamic rawData) {
  final data = _extractEstimateData(rawData);
  final pricing = data['pricing'];
  Map<String, dynamic>? pricingMap;
  if (pricing is Map) {
    pricingMap = Map<String, dynamic>.from(pricing);
  }

  Map<String, dynamic>? timeBand;
  final rawBand = pricingMap?['time_band'];
  if (rawBand is Map) {
    timeBand = Map<String, dynamic>.from(rawBand);
  }

  Map<String, dynamic>? nightHours;
  final rawNight = timeBand?['night_hours'];
  if (rawNight is Map) {
    nightHours = Map<String, dynamic>.from(rawNight);
  }

  return DeliveryEstimate(
    estimatedCost: _parseDouble(data['estimated_cost']),
    estimatedDistance: _parseDouble(data['estimated_distance']),
    estimatedDuration: _parseInt(data['estimated_duration']),
    currency: data['currency']?.toString() ?? 'ETB',
    baseDeliveryFee: _parseDouble(data['base_delivery_fee']) ??
        _parseDouble(data['base_fare']),
    distanceRate: _parseDouble(data['distance_rate']) ??
        _parseDouble(data['per_km_rate']),
    freeDistance: _parseDouble(data['free_distance']),
    weightCharge: _parseDouble(data['weight_charge']),
    timeBandName: timeBand?['name']?.toString(),
    timeBandMultiplier: _parseDouble(timeBand?['multiplier']),
    timeBandSurchargeRate: _parseDouble(timeBand?['surcharge_rate']),
    timeBandSurcharge: _parseDouble(pricingMap?['time_band_surcharge']),
    evaluatedPickupAt: timeBand?['evaluated_pickup_at']?.toString(),
    timezone: timeBand?['timezone']?.toString(),
    nightHoursStart: _parseInt(nightHours?['start']),
    nightHoursEnd: _parseInt(nightHours?['end']),
    vehicleType: data['vehicle_type']?.toString(),
  );
}

Map<String, dynamic> _extractEstimateData(dynamic rawData) {
  if (rawData is! Map) return {};
  final map = Map<String, dynamic>.from(rawData);
  if (map.containsKey('estimated_distance') ||
      map.containsKey('estimated_cost')) {
    return map;
  }
  final nested = map['data'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return {};
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
