/// Resolves vendor/shop media URLs from API fields that often point at
/// broken Spatie conversion paths (`.../conversions/name-medium.jpg`) while
/// the original (`.../storage/{id}/name.jpeg`) is still available.
List<String> vendorMediaUrlCandidates({
  String? path,
  Map<dynamic, dynamic>? urls,
}) {
  final out = <String>[];

  void add(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return;
    if (!out.contains(v)) out.add(v);
  }

  if (urls != null) {
    for (final key in ['original', 'large', 'medium', 'small', 'thumb']) {
      add(urls[key]?.toString());
    }
  }

  // Prefer guessed originals before a conversion URL that may 404.
  for (final candidate in originalCandidatesFromConversionUrl(path)) {
    add(candidate);
  }
  add(path);

  return out;
}

/// Best single URL for models that store one string (prefers original).
String resolveVendorMediaUrl({
  String? path,
  Map<dynamic, dynamic>? urls,
}) {
  final candidates = vendorMediaUrlCandidates(path: path, urls: urls);
  return candidates.isEmpty ? '' : candidates.first;
}

/// From `.../storage/38/conversions/download-medium.jpg` try
/// `.../storage/38/download.jpeg|jpg|png|webp`.
List<String> originalCandidatesFromConversionUrl(String? url) {
  if (url == null || url.isEmpty) return const [];
  final match = RegExp(
    r'^(https?://.+)/storage/(\d+)/conversions/(.+)-(thumb|small|medium|large)\.\w+$',
    caseSensitive: false,
  ).firstMatch(url);
  if (match == null) return const [];

  final hostAndPrefix = match.group(1)!;
  final mediaId = match.group(2)!;
  final baseName = match.group(3)!;
  final stem = '$hostAndPrefix/storage/$mediaId/$baseName';
  return [
    '$stem.jpeg',
    '$stem.jpg',
    '$stem.png',
    '$stem.webp',
  ];
}
