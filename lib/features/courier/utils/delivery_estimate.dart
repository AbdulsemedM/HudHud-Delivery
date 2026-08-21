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

/// Maps UI vehicle id to API `vehicle_type`.
String mapCourierVehicleType(String vehicle) {
  const mapping = {
    'motorcycle': 'motorbike',
    'car': 'car',
    'van': 'van',
  };
  return mapping[vehicle] ?? vehicle;
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
