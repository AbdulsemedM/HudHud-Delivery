import 'wishlist_item_model.dart';
import 'wishlist_vendor_group_model.dart';

class WishlistListResult {
  final List<WishlistItemModel> items;
  final int currentPage;
  final int lastPage;
  final int? total;
  final int? totalItems;
  final List<WishlistVendorGroupModel> vendorGroups;

  const WishlistListResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    this.total,
    this.totalItems,
    this.vendorGroups = const [],
  });

  bool get hasMore => currentPage < lastPage;

  static WishlistListResult fromResponseData(dynamic data) {
    if (data == null) {
      return const WishlistListResult(items: [], currentPage: 1, lastPage: 1);
    }

    Map<String, dynamic>? body;
    List<WishlistVendorGroupModel> vendorGroups = const [];
    int? totalItems;

    if (data is Map<String, dynamic>) {
      body = data;
      if (data['data'] is Map<String, dynamic>) {
        body = data['data'] as Map<String, dynamic>;
      }
      if (data['vendor_groups'] is List) {
        vendorGroups = (data['vendor_groups'] as List)
            .whereType<Map>()
            .map((e) => WishlistVendorGroupModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      }
      totalItems = _parseInt(data['total_items']);
    }

    if (body == null) {
      return const WishlistListResult(items: [], currentPage: 1, lastPage: 1);
    }

    final rawList = body['data'];
    final list = rawList is List ? rawList : <dynamic>[];
    final items = list
        .whereType<Map>()
        .map((e) =>
            WishlistItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return WishlistListResult(
      items: items,
      currentPage: _parseInt(body['current_page']) ?? 1,
      lastPage: _parseInt(body['last_page']) ?? 1,
      total: _parseInt(body['total']),
      totalItems: totalItems ?? _parseInt(body['total']),
      vendorGroups: vendorGroups,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class WishlistPriceDropsResult {
  final List<WishlistItemModel> items;
  final int totalDrops;
  final int notificationsSent;

  const WishlistPriceDropsResult({
    this.items = const [],
    this.totalDrops = 0,
    this.notificationsSent = 0,
  });

  factory WishlistPriceDropsResult.fromResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const WishlistPriceDropsResult();
    }
    final list = data['data'];
    final items = list is List
        ? list
            .whereType<Map>()
            .map((e) => WishlistItemModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <WishlistItemModel>[];

    return WishlistPriceDropsResult(
      items: items,
      totalDrops: _parseInt(data['total_drops']) ?? items.length,
      notificationsSent: _parseInt(data['notifications_sent']) ?? 0,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
