import 'wishlist_item_model.dart';

class WishlistVendorGroupModel {
  final int? vendorId;
  final String? vendorName;
  final List<WishlistItemModel> items;
  final int totalItems;
  final num totalValue;

  const WishlistVendorGroupModel({
    this.vendorId,
    this.vendorName,
    this.items = const [],
    this.totalItems = 0,
    this.totalValue = 0,
  });

  factory WishlistVendorGroupModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => WishlistItemModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <WishlistItemModel>[];

    return WishlistVendorGroupModel(
      vendorId: _parseInt(json['vendor_id']),
      vendorName: json['vendor_name']?.toString(),
      items: items,
      totalItems: _parseInt(json['total_items']) ?? items.length,
      totalValue: _parseNum(json['total_value']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }
}
