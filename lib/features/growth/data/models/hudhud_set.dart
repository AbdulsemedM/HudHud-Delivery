import 'growth_json.dart';

/// One item of `GET /api/public/sets` (Phase 4 HudHud Set).
///
/// A set is a normal product (`product_id`) sold at a fixed price with the
/// delivery fee funded by HudHud. `vendor.id` is the vendor OWNER user id —
/// the id the cart, store screen and public vendor endpoints use.
class HudHudSetItem {
  final int productId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final bool deliveryIncluded;

  /// `image` map: thumb / small / medium / original / large URLs.
  final Map<String, dynamic>? imageUrls;
  final String? imagePath;
  final int vendorId;
  final String vendorName;
  final Map<String, dynamic>? vendorLogoUrls;
  final String? vendorLogoPath;
  final bool vendorIsOpen;

  const HudHudSetItem({
    required this.productId,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    this.deliveryIncluded = true,
    this.imageUrls,
    this.imagePath,
    required this.vendorId,
    required this.vendorName,
    this.vendorLogoUrls,
    this.vendorLogoPath,
    this.vendorIsOpen = true,
  });

  bool get isValid =>
      productId > 0 && vendorId > 0 && price > 0 && name.isNotEmpty;

  /// Best display URL from the `image` map; `null` when none.
  String? get imageUrl {
    final urls = imageUrls;
    if (urls == null) return null;
    for (final key in const ['medium', 'small', 'large', 'original', 'thumb']) {
      final u = growthString(urls[key]);
      if (u != null) return u;
    }
    return null;
  }

  factory HudHudSetItem.fromJson(Map<String, dynamic> json, {String? currency}) {
    final vendor = growthMap(json['vendor']) ?? const {};
    return HudHudSetItem(
      productId: growthInt(json['product_id'] ?? json['id']),
      name: growthString(json['name']) ?? '',
      description: growthString(json['description']),
      price: growthDouble(json['price']),
      currency: (growthString(json['currency']) ?? currency ?? 'ETB')
          .toUpperCase(),
      deliveryIncluded: growthBool(json['delivery_included'], true),
      imageUrls: growthMap(json['image']),
      imagePath: growthString(json['image_path']),
      vendorId: growthInt(vendor['id']),
      vendorName: growthString(vendor['name']) ?? '',
      vendorLogoUrls: growthMap(vendor['logo_urls']),
      vendorLogoPath: growthString(vendor['logo_path']),
      vendorIsOpen: storeOpenFlag(vendor, legacy: false) ??
          growthBool(
            vendor['is_currently_open'] ?? vendor['is_open'],
            true,
          ),
    );
  }
}

/// `GET /api/public/sets` page: `{success, data: {enabled, market, currency,
/// max_per_order, data: [...], current_page, last_page, per_page, total}}`.
class HudHudSetsPage {
  final bool enabled;
  final String? market;
  final String currency;

  /// Server limit (`growth.set_max_per_order`); never hardcoded in the app.
  final int maxPerOrder;
  final List<HudHudSetItem> items;

  const HudHudSetsPage({
    required this.enabled,
    this.market,
    this.currency = 'ETB',
    this.maxPerOrder = 1,
    this.items = const [],
  });

  static const HudHudSetsPage empty = HudHudSetsPage(enabled: false);

  /// The row is shown only when the server returned items.
  bool get hasItems => items.isNotEmpty;

  factory HudHudSetsPage.fromJson(Map<String, dynamic> json) {
    final currency = growthString(json['currency'])?.toUpperCase() ?? 'ETB';
    final seen = <int>{};
    final items = <HudHudSetItem>[];
    for (final raw in growthList(json['data'])) {
      final map = growthMap(raw);
      if (map == null) continue;
      final item = HudHudSetItem.fromJson(map, currency: currency);
      if (!item.isValid || !seen.add(item.productId)) continue;
      items.add(item);
    }
    final max = growthInt(json['max_per_order'], 1);
    return HudHudSetsPage(
      enabled: growthBool(json['enabled']),
      market: growthString(json['market']),
      currency: currency,
      maxPerOrder: max > 0 ? max : 1,
      items: items,
    );
  }

  /// Parses the full response body; [empty] when not a valid envelope.
  static HudHudSetsPage fromResponseBody(dynamic body) {
    final data = growthEnvelopeData(body);
    if (data == null) return empty;
    try {
      return HudHudSetsPage.fromJson(data);
    } catch (_) {
      return empty;
    }
  }
}

/// Product ids of sets seen in this session, so checkout can ask the server
/// for a quote (which carries the set delivery subsidy) when the cart holds
/// a set even if no other growth feature is on.
class KnownHudHudSets {
  KnownHudHudSets._();

  static final Set<int> _productIds = <int>{};

  static void remember(Iterable<HudHudSetItem> items) {
    for (final item in items) {
      if (item.productId > 0) _productIds.add(item.productId);
    }
  }

  static bool contains(int? productId) =>
      productId != null && _productIds.contains(productId);

  static bool get isEmpty => _productIds.isEmpty;

  /// Test hook.
  static void clear() => _productIds.clear();
}
