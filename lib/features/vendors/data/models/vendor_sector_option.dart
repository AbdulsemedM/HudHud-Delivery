/// One vendor type (sector) the server says has at least one live shop,
/// from GET /api/public/vendors/sectors.
///
/// Vendor types are now managed by admins in the portal: they can be added,
/// renamed, reordered, switched off and deleted. So the app can no longer
/// assume the eight built-in keys; the server sends each type's name (in up
/// to five languages) and its display order. An older API sends only
/// `{key, count}`, and that must keep working.
class VendorSectorOption {
  const VendorSectorOption({
    required this.key,
    this.count = 0,
    this.name,
    this.names = const {},
    this.sortOrder,
  });

  /// The code sent back as the `sector` filter. Never a label.
  final String key;
  final int count;

  /// English display name, when the server sends one.
  final String? name;

  /// Display names by language code (en, am, ar, om, so); only non-empty
  /// values are kept.
  final Map<String, String> names;

  /// Admin-set display order; null from an older API.
  final int? sortOrder;

  /// Parses one row. Returns null for anything without a usable key.
  static VendorSectorOption? fromJson(Object? row) {
    if (row is! Map) return null;
    final key = row['key']?.toString().trim() ?? '';
    if (key.isEmpty) return null;

    final names = <String, String>{};
    final rawNames = row['names'];
    if (rawNames is Map) {
      rawNames.forEach((lang, value) {
        final text = value?.toString().trim() ?? '';
        if (lang != null && text.isNotEmpty) names[lang.toString()] = text;
      });
    }
    final name = row['name']?.toString().trim();

    return VendorSectorOption(
      key: key,
      count: int.tryParse(row['count']?.toString() ?? '') ?? 0,
      name: (name == null || name.isEmpty) ? null : name,
      names: names,
      sortOrder: int.tryParse(row['sort_order']?.toString() ?? ''),
    );
  }

  /// Parses the endpoint body (`{success, data: [...]}`). Never throws: the
  /// chip row is a decoration, and a malformed answer means no chips.
  static List<VendorSectorOption> listFromResponse(Object? body) {
    try {
      final rows = body is Map ? body['data'] : null;
      if (rows is! List) return const [];
      return rows
          .map(fromJson)
          .whereType<VendorSectorOption>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

/// The built-in display order, used only when the server sends no
/// `sort_order` (an API from before vendor types were admin-managed).
const List<String> legacySectorOrder = [
  'restaurant',
  'bakery',
  'supermarket',
  'grocery',
  'market',
  'pharmacy',
  'spare_parts',
  'general',
];

/// "spare_parts" → "Spare parts". Last resort, so a type with no name at all
/// still gets a readable chip rather than a crash or a blank pill.
String humaniseSectorKey(String key) {
  final words = key
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return key;
  final text = words.join(' ').toLowerCase();
  return text[0].toUpperCase() + text.substring(1);
}

/// The label for one chip, in the customer's language:
/// the server's name in [languageCode] → the app's own translation for a
/// built-in key ([builtInLabels]) → the server's English name → the
/// humanised key. Never throws on an unknown key.
String sectorChipLabel(
  VendorSectorOption option, {
  required String languageCode,
  Map<String, String> builtInLabels = const {},
}) {
  final localized = option.names[languageCode];
  if (localized != null && localized.isNotEmpty) return localized;

  final builtIn = builtInLabels[option.key];
  if (builtIn != null && builtIn.trim().isNotEmpty) return builtIn;

  final english = option.names['en'] ?? option.name;
  if (english != null && english.isNotEmpty) return english;

  return humaniseSectorKey(option.key);
}

/// The chips to draw, in order, WITHOUT the leading "All" chip.
///
/// Server order (sort_order) when the server sends it; otherwise the
/// built-in order with any unknown key after it. One type is the same as
/// none - "All" and the only type would show an identical list - so fewer
/// than two gives an empty result. Duplicate keys are drawn once.
List<({String key, String label})> resolveSectorChips(
  List<VendorSectorOption> options, {
  required String languageCode,
  Map<String, String> builtInLabels = const {},
}) {
  final seen = <String>{};
  final unique = [
    for (final o in options)
      if (seen.add(o.key)) o,
  ];

  final ordered = List<VendorSectorOption>.of(unique);
  final hasServerOrder = ordered.any((o) => o.sortOrder != null);
  int rank(VendorSectorOption o) {
    if (hasServerOrder) return o.sortOrder ?? 1 << 30;
    final i = legacySectorOrder.indexOf(o.key);
    return i < 0 ? legacySectorOrder.length : i;
  }

  // Stable: equal ranks keep the order the server sent them in.
  final indexed = ordered.asMap().entries.toList()
    ..sort((a, b) {
      final byRank = rank(a.value).compareTo(rank(b.value));
      return byRank != 0 ? byRank : a.key.compareTo(b.key);
    });

  if (indexed.length < 2) return const [];

  return [
    for (final entry in indexed)
      (
        key: entry.value.key,
        label: sectorChipLabel(
          entry.value,
          languageCode: languageCode,
          builtInLabels: builtInLabels,
        ),
      ),
  ];
}
