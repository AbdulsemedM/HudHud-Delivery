import 'growth_json.dart';
import 'sponsored.dart';

/// `GET /api/home/feed`
class HomeFeed {
  final List<HomeFeedBanner> banners;
  final List<HomeFeedCollection> collections;

  /// Phase 3: sponsored vendors (present only when ads are enabled).
  final List<SponsoredItem> sponsored;

  const HomeFeed({
    required this.banners,
    required this.collections,
    this.sponsored = const [],
  });

  static const HomeFeed empty = HomeFeed(banners: [], collections: []);

  bool get isEmpty =>
      banners.isEmpty &&
      collections.every((c) => c.items.isEmpty) &&
      sponsored.isEmpty;

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    final banners = growthList(json['banners'])
        .map(growthMap)
        .whereType<Map<String, dynamic>>()
        .map(HomeFeedBanner.fromJson)
        .where((b) => b.imageUrl != null || b.title.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final collections = growthList(json['collections'])
        .map(growthMap)
        .whereType<Map<String, dynamic>>()
        .map(HomeFeedCollection.fromJson)
        .where((c) => c.items.isNotEmpty)
        .toList();
    return HomeFeed(
      banners: banners,
      collections: collections,
      sponsored: SponsoredItem.listFromJson(
        json['sponsored'],
        placement: SponsoredPlacement.home,
      ),
    );
  }
}

/// Banner tap actions from the contract.
enum HomeFeedActionType { vendor, product, collection, url, promo, none }

HomeFeedActionType parseHomeFeedActionType(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'vendor':
      return HomeFeedActionType.vendor;
    case 'product':
      return HomeFeedActionType.product;
    case 'collection':
      return HomeFeedActionType.collection;
    case 'url':
      return HomeFeedActionType.url;
    case 'promo':
      return HomeFeedActionType.promo;
    default:
      return HomeFeedActionType.none;
  }
}

class HomeFeedBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final HomeFeedActionType actionType;
  final String? actionValue;
  final int sortOrder;

  const HomeFeedBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.actionType,
    this.actionValue,
    required this.sortOrder,
  });

  factory HomeFeedBanner.fromJson(Map<String, dynamic> json) {
    final action = growthMap(json['action']) ?? const {};
    return HomeFeedBanner(
      id: growthInt(json['id']),
      title: growthString(json['title']) ?? '',
      subtitle: growthString(json['subtitle']),
      imageUrl: growthString(json['image_url']),
      actionType: parseHomeFeedActionType(
        growthString(action['type']) ?? growthString(json['action_type']),
      ),
      actionValue:
          growthString(action['value']) ?? growthString(json['action_value']),
      sortOrder: growthInt(json['sort_order']),
    );
  }
}

class HomeFeedCollection {
  final int id;
  final String title;
  final String? slug;

  /// vendor | product
  final String itemType;
  final List<HomeFeedItem> items;

  const HomeFeedCollection({
    required this.id,
    required this.title,
    this.slug,
    required this.itemType,
    required this.items,
  });

  bool matchesKey(String key) {
    final k = key.trim().toLowerCase();
    if (k.isEmpty) return false;
    return id.toString() == k || (slug ?? '').toLowerCase() == k;
  }

  factory HomeFeedCollection.fromJson(Map<String, dynamic> json) {
    final itemType = (growthString(json['item_type']) ?? 'product').toLowerCase();
    return HomeFeedCollection(
      id: growthInt(json['id']),
      title: growthString(json['title']) ?? '',
      slug: growthString(json['slug']),
      itemType: itemType,
      items: growthList(json['items'])
          .map(growthMap)
          .whereType<Map<String, dynamic>>()
          .map((m) => HomeFeedItem.fromJson(m, fallbackType: itemType))
          .where((i) => i.id > 0)
          .toList(),
    );
  }
}

class HomeFeedItem {
  final int id;

  /// vendor | product
  final String type;
  final String name;
  final String? imageUrl;
  final double? rating;
  final bool? isOpen;
  final double? price;
  final int? vendorId;

  const HomeFeedItem({
    required this.id,
    required this.type,
    required this.name,
    this.imageUrl,
    this.rating,
    this.isOpen,
    this.price,
    this.vendorId,
  });

  bool get isVendor => type == 'vendor';

  factory HomeFeedItem.fromJson(
    Map<String, dynamic> json, {
    String fallbackType = 'product',
  }) {
    return HomeFeedItem(
      id: growthInt(json['id']),
      type: (growthString(json['type']) ?? fallbackType).toLowerCase(),
      name: growthString(json['name']) ?? '',
      imageUrl: growthString(json['image_url']),
      rating: growthDoubleOrNull(json['rating']),
      isOpen: storeOpenFlag(json),
      price: growthDoubleOrNull(json['price']),
      vendorId: growthIntOrNull(json['vendor_id']),
    );
  }
}
