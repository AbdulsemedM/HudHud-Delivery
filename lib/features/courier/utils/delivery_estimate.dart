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
  });

  final double? estimatedCost;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final String currency;
  final double? baseDeliveryFee;
  final double? distanceRate;
  final double? freeDistance;
  final double? weightCharge;

  bool get isValid => estimatedCost != null;
}

/// Parses estimate JSON — flat, nested `{ data: ... }`, or generic Map from Dio.
DeliveryEstimate parseDeliveryEstimate(dynamic rawData) {
  final data = _extractEstimateData(rawData);
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
