import 'growth_json.dart';

/// Ad placements from the contract (§6).
class SponsoredPlacement {
  SponsoredPlacement._();

  static const String home = 'home';
  static const String search = 'search';
}

/// One sponsored vendor from `GET /api/ads/sponsored` or the home feed's
/// `sponsored` array.
class SponsoredItem {
  final int adId;
  final String impressionToken;
  final int vendorId;
  final String vendorName;
  final String? imageUrl;
  final double? rating;
  final bool? isOpen;

  /// Server label (e.g. "Sponsored"); the app shows its own localized label.
  final String? label;

  /// Placement this item was served for (sent back on click).
  final String placement;

  const SponsoredItem({
    required this.adId,
    required this.impressionToken,
    required this.vendorId,
    required this.vendorName,
    this.imageUrl,
    this.rating,
    this.isOpen,
    this.label,
    required this.placement,
  });

  bool get isValid => adId > 0 && vendorId > 0;

  factory SponsoredItem.fromJson(
    Map<String, dynamic> json, {
    required String placement,
  }) {
    final vendor = growthMap(json['vendor']) ?? const {};
    return SponsoredItem(
      adId: growthInt(json['ad_id']),
      impressionToken: growthString(json['impression_token']) ?? '',
      vendorId: growthInt(vendor['id']),
      vendorName: growthString(vendor['name']) ?? '',
      imageUrl: growthString(vendor['image_url']),
      rating: growthDoubleOrNull(vendor['rating']),
      isOpen: storeOpenFlag(vendor),
      label: growthString(json['label']),
      placement: growthString(json['placement']) ?? placement,
    );
  }

  /// Parses a raw list, dropping malformed entries and duplicate vendors.
  static List<SponsoredItem> listFromJson(
    dynamic raw, {
    required String placement,
  }) {
    final seen = <int>{};
    final out = <SponsoredItem>[];
    for (final entry in growthList(raw)) {
      final map = growthMap(entry);
      if (map == null) continue;
      final item = SponsoredItem.fromJson(map, placement: placement);
      if (!item.isValid || !seen.add(item.vendorId)) continue;
      out.add(item);
    }
    return out;
  }

  /// Parses `{success, data: {items: [...]}}` (or `data: [...]`).
  static List<SponsoredItem> listFromResponseBody(
    dynamic body, {
    required String placement,
  }) {
    final list = growthEnvelopeList(body);
    if (list == null) return const [];
    return listFromJson(list, placement: placement);
  }
}
