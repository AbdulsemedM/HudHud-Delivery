/// Body for `POST /api/customer/checkout/quote`.
///
/// Mirrors the item / vendor / branch / address fields sent to
/// `POST /api/customer/orders` (see CheckoutDataProvider.createOrder), plus
/// the Phase 2 inputs `coupon_code` and `redeem_points`. No client totals
/// or discounts are sent.
class CheckoutQuoteRequest {
  final int vendorId;
  final int? branchId;
  final List<Map<String, dynamic>> items;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String serviceType;
  final String? couponCode;
  final int? redeemPoints;

  const CheckoutQuoteRequest({
    required this.vendorId,
    this.branchId,
    required this.items,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.serviceType = 'restaurant',
    this.couponCode,
    this.redeemPoints,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'items': items.map(_mapItem).toList(),
      'delivery_address': {
        'latitude': deliveryLatitude,
        'longitude': deliveryLongitude,
        'address': deliveryAddress,
      },
      'delivery_location': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'service_type': serviceType.trim().isEmpty ? 'restaurant' : serviceType,
    };
    if (vendorId > 0) body['vendor_id'] = vendorId;
    if (branchId != null && branchId! > 0) body['branch_id'] = branchId;
    final code = couponCode?.trim();
    if (code != null && code.isNotEmpty) body['coupon_code'] = code;
    if (redeemPoints != null && redeemPoints! > 0) {
      body['redeem_points'] = redeemPoints;
    }
    return body;
  }

  /// Stable key so identical inputs are not re-quoted.
  String get cacheKey => toJson().toString();

  static Map<String, dynamic> _mapItem(Map<String, dynamic> item) {
    final mapped = <String, dynamic>{
      'product_id': item['product_id'],
      'quantity': item['quantity'],
    };
    final variantId = item['variant_id'];
    if (variantId != null) {
      final parsed =
          variantId is int ? variantId : int.tryParse(variantId.toString());
      if (parsed != null && parsed > 0) mapped['variant_id'] = parsed;
    }
    final modifierIds = item['modifier_option_ids'];
    if (modifierIds is List && modifierIds.isNotEmpty) {
      mapped['modifier_option_ids'] = modifierIds
          .map((e) => e is int ? e : int.tryParse(e.toString()))
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
    }
    return mapped;
  }
}
