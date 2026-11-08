import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

import 'growth_json.dart';

/// `POST /api/customer/orders/{id}/reorder`
class ReorderResult {
  final int vendorId;
  final List<ReorderItem> items;
  final List<ReorderUnavailableItem> unavailable;

  const ReorderResult({
    required this.vendorId,
    required this.items,
    required this.unavailable,
  });

  factory ReorderResult.fromJson(Map<String, dynamic> json) {
    final vendorId = growthInt(json['vendor_id']);
    return ReorderResult(
      vendorId: vendorId,
      items: growthList(json['items'])
          .map(growthMap)
          .whereType<Map<String, dynamic>>()
          .map((m) => ReorderItem.fromJson(m, vendorId: vendorId))
          .where((i) => i.productId > 0 && i.quantity > 0)
          .toList(),
      unavailable: growthList(json['unavailable'])
          .map(growthMap)
          .whereType<Map<String, dynamic>>()
          .map(ReorderUnavailableItem.fromJson)
          .toList(),
    );
  }

  static ReorderResult? tryParseResponseBody(dynamic body) {
    final data = growthEnvelopeData(body);
    if (data == null) return null;
    return ReorderResult.fromJson(data);
  }
}

class ReorderItem {
  final int productId;
  final int vendorId;
  final int? variantId;
  final List<int> modifierOptionIds;
  final int quantity;
  final double unitPrice;
  final String name;
  final String? imageUrl;

  const ReorderItem({
    required this.productId,
    required this.vendorId,
    this.variantId,
    this.modifierOptionIds = const [],
    required this.quantity,
    required this.unitPrice,
    required this.name,
    this.imageUrl,
  });

  factory ReorderItem.fromJson(
    Map<String, dynamic> json, {
    required int vendorId,
  }) {
    final modifiers = <int>[];
    for (final m in growthList(json['modifiers'] ?? json['modifier_option_ids'])) {
      final map = growthMap(m);
      final id = map == null
          ? growthIntOrNull(m)
          : growthIntOrNull(map['option_id'] ?? map['modifier_option_id'] ?? map['id']);
      if (id != null && id > 0) modifiers.add(id);
    }
    final variant = growthIntOrNull(json['variant_id']);
    return ReorderItem(
      productId: growthInt(json['product_id']),
      vendorId: growthInt(json['vendor_id'], vendorId),
      variantId: variant != null && variant > 0 ? variant : null,
      modifierOptionIds: modifiers,
      quantity: growthInt(json['quantity'], 1),
      unitPrice: growthDouble(json['unit_price']),
      name: growthString(json['name']) ?? '',
      imageUrl: growthString(json['image_url']),
    );
  }

  /// Cart line in the shape [CartService] already understands
  /// (variant / modifiers travel via `options`, like product detail does).
  CategoriesProductsModel toCartProduct() {
    final options = <String, dynamic>{};
    if (variantId != null) options['variant_id'] = variantId;
    if (modifierOptionIds.isNotEmpty) {
      options['modifier_option_ids'] = List<int>.from(modifierOptionIds);
    }
    return CategoriesProductsModel(
      id: productId,
      vendor_id: vendorId > 0 ? vendorId : null,
      name: name,
      price: unitPrice.toStringAsFixed(2),
      image_path: imageUrl,
      options: options.isEmpty ? null : options,
      is_available: true,
      status: 'active',
    );
  }
}

class ReorderUnavailableItem {
  final int productId;
  final String name;

  /// out_of_stock | removed | vendor_closed
  final String reason;

  const ReorderUnavailableItem({
    required this.productId,
    required this.name,
    required this.reason,
  });

  factory ReorderUnavailableItem.fromJson(Map<String, dynamic> json) {
    return ReorderUnavailableItem(
      productId: growthInt(json['product_id']),
      name: growthString(json['name']) ?? '',
      reason: (growthString(json['reason']) ?? '').toLowerCase(),
    );
  }
}

/// One past order from `GET /api/customer/retention/reorder-suggestions`.
///
/// Current backend shape (RetentionController::reorderSuggestions):
/// `{success, data: {orders: [{id, status, total_amount, currency, created_at}]}}`
/// — up to 5 most recent delivered/completed orders. Vendor fields are read
/// when present (forward compatible) but are not sent today.
class ReorderSuggestion {
  final int orderId;
  final String? orderNumber;
  final String status;
  final double totalAmount;
  final String currency;
  final DateTime? createdAt;
  final String? vendorName;
  final String? vendorImageUrl;

  const ReorderSuggestion({
    required this.orderId,
    this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.createdAt,
    this.vendorName,
    this.vendorImageUrl,
  });

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) {
    final vendor = growthMap(json['vendor']);
    final created = growthString(json['created_at']);
    return ReorderSuggestion(
      orderId: growthInt(json['id'] ?? json['order_id']),
      orderNumber: growthString(json['order_number']),
      status: growthString(json['status']) ?? '',
      totalAmount: growthDouble(json['total_amount']),
      currency: growthString(json['currency']) ?? 'ETB',
      createdAt: created == null ? null : DateTime.tryParse(created),
      vendorName: growthString(json['vendor_name']) ??
          growthString(vendor?['name']) ??
          growthString(vendor?['business_name']),
      vendorImageUrl: growthString(json['vendor_image_url']) ??
          growthString(vendor?['logo_url']) ??
          growthString(vendor?['avatar']),
    );
  }

  static List<ReorderSuggestion> listFromResponseBody(dynamic body) {
    final data = growthEnvelopeData(body);
    if (data == null) return const [];
    return growthList(data['orders'])
        .map(growthMap)
        .whereType<Map<String, dynamic>>()
        .map(ReorderSuggestion.fromJson)
        .where((s) => s.orderId > 0)
        .toList();
  }
}
