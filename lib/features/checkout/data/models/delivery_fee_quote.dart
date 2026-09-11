/// Preview delivery fee from POST /api/customer/delivery-fee/quote.
///
/// Preview only — order create recalculates the authoritative fee.
class DeliveryFeeQuote {
  final double deliveryFee;
  final String currency;
  final String currencySymbol;
  final String formattedDeliveryFee;
  final double distanceKm;
  final String? distanceSource;
  final int estimatedDurationMinutes;
  final DateTime quotedAt;
  final DateTime validUntil;
  final DeliveryFeeQuoteRestaurant? restaurant;
  final DeliveryFeeQuoteAddress? deliveryAddress;
  final DeliveryFeeQuoteBreakdown? breakdown;

  const DeliveryFeeQuote({
    required this.deliveryFee,
    required this.currency,
    required this.currencySymbol,
    required this.formattedDeliveryFee,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.quotedAt,
    required this.validUntil,
    this.distanceSource,
    this.restaurant,
    this.deliveryAddress,
    this.breakdown,
  });

  bool get isExpired => DateTime.now().isAfter(validUntil);

  bool get isUsable => !isExpired && deliveryFee >= 0;

  factory DeliveryFeeQuote.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeQuote(
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      currency: json['currency'] as String? ?? '',
      currencySymbol: json['currency_symbol'] as String? ?? '',
      formattedDeliveryFee: json['formatted_delivery_fee'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      distanceSource: json['distance_source'] as String?,
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt() ?? 0,
      quotedAt: DateTime.parse(json['quoted_at'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      restaurant: json['restaurant'] is Map
          ? DeliveryFeeQuoteRestaurant.fromJson(
              Map<String, dynamic>.from(json['restaurant'] as Map),
            )
          : null,
      deliveryAddress: json['delivery_address'] is Map
          ? DeliveryFeeQuoteAddress.fromJson(
              Map<String, dynamic>.from(json['delivery_address'] as Map),
            )
          : null,
      breakdown: json['breakdown'] is Map
          ? DeliveryFeeQuoteBreakdown.fromJson(
              Map<String, dynamic>.from(json['breakdown'] as Map),
            )
          : null,
    );
  }
}

class DeliveryFeeQuoteRestaurant {
  final int branchId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  const DeliveryFeeQuoteRestaurant({
    required this.branchId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory DeliveryFeeQuoteRestaurant.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeQuoteRestaurant(
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class DeliveryFeeQuoteAddress {
  final String address;
  final double latitude;
  final double longitude;

  const DeliveryFeeQuoteAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory DeliveryFeeQuoteAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeQuoteAddress(
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DeliveryFeeQuoteBreakdown {
  final double baseFee;
  final double distanceCharge;
  final double distanceRate;
  final double freeDistanceKm;
  final double surgeMultiplier;
  final bool surgeApplied;
  final double nightSurcharge;
  final bool nightSurchargeApplied;

  const DeliveryFeeQuoteBreakdown({
    required this.baseFee,
    required this.distanceCharge,
    required this.distanceRate,
    required this.freeDistanceKm,
    required this.surgeMultiplier,
    required this.surgeApplied,
    required this.nightSurcharge,
    required this.nightSurchargeApplied,
  });

  factory DeliveryFeeQuoteBreakdown.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeQuoteBreakdown(
      baseFee: (json['base_fee'] as num?)?.toDouble() ?? 0,
      distanceCharge: (json['distance_charge'] as num?)?.toDouble() ?? 0,
      distanceRate: (json['distance_rate'] as num?)?.toDouble() ?? 0,
      freeDistanceKm: (json['free_distance_km'] as num?)?.toDouble() ?? 0,
      surgeMultiplier: (json['surge_multiplier'] as num?)?.toDouble() ?? 1,
      surgeApplied: json['surge_applied'] == true,
      nightSurcharge: (json['night_surcharge'] as num?)?.toDouble() ?? 0,
      nightSurchargeApplied: json['night_surcharge_applied'] == true,
    );
  }
}

/// Structured failure from the delivery-fee quote endpoint.
class DeliveryFeeQuoteException implements Exception {
  static const String branchUnavailable = 'BRANCH_UNAVAILABLE';
  static const String branchLocationUnavailable = 'BRANCH_LOCATION_UNAVAILABLE';

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? errors;

  const DeliveryFeeQuoteException({
    required this.message,
    this.statusCode,
    this.code,
    this.errors,
  });

  bool get isUnauthenticated => statusCode == 401;
  bool get isValidation => statusCode == 422 && code == null;
  bool get isBranchUnavailable => code == branchUnavailable;
  bool get isBranchLocationUnavailable => code == branchLocationUnavailable;
  bool get isRetryableNetwork {
    final s = statusCode;
    return s == null ||
        s == 500 ||
        s == 502 ||
        s == 503 ||
        s == 504;
  }

  @override
  String toString() => message;
}

/// Cache key for in-memory quote reuse until [DeliveryFeeQuote.validUntil].
String deliveryFeeQuoteCacheKey({
  required int branchId,
  required double latitude,
  required double longitude,
  required String address,
}) {
  return '$branchId|${latitude.toStringAsFixed(6)}|'
      '${longitude.toStringAsFixed(6)}|${address.trim()}';
}
