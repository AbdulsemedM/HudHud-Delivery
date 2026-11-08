import 'package:hudhud_delivery/app/models/place_result.dart';

/// Avoid Google Plus Codes (e.g. 2Q4J+3WH) in user-facing address labels.
class HumanReadableAddress {
  HumanReadableAddress._();

  static final RegExp _plusCode = RegExp(
    r'^[2-9A-Z]{4,}\+[2-9A-Z]{2,}$',
    caseSensitive: false,
  );

  static bool isPlusCode(String? value) {
    if (value == null) return false;
    final normalized = value.trim().replaceAll(' ', '');
    if (normalized.isEmpty) return false;
    return _plusCode.hasMatch(normalized);
  }

  /// Google's placeholder for roads without a name, in the languages it
  /// returns for our markets (English, Amharic script and romanized, Arabic).
  static const List<String> _unnamedRoadLabels = [
    'unnamed road',
    'ያልተሰየመ መንገድ',
    'yaliteseyeme menigedi',
    'طريق بدون اسم',
    'طريق غير مسمى',
  ];

  /// True for Google's "Unnamed Road" placeholder (it carries no real detail).
  static bool isUnnamedRoad(String? value) {
    if (value == null) return false;
    final normalized =
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return false;
    return _unnamedRoadLabels.contains(normalized);
  }

  /// Segments never shown to users: plus codes and unnamed-road placeholders.
  static bool isNoiseSegment(String? value) =>
      isPlusCode(value) || isUnnamedRoad(value);

  /// First comma-separated segment that is not a plus code or unnamed road.
  static String? firstReadableSegment(String text) {
    for (final part in text.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty && !isNoiseSegment(trimmed)) {
        return trimmed;
      }
    }
    return null;
  }

  /// Removes plus-code and unnamed-road segments from an address string.
  static String stripPlusCodesFromAddress(String text) {
    final parts = text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !isNoiseSegment(s))
        .toList();
    if (parts.isEmpty) {
      return firstReadableSegment(text) ?? text.trim();
    }
    return parts.join(', ');
  }

  /// True when the first comma-separated segment is a plus code.
  static bool startsWithPlusCode(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final first = text.split(',').first.trim();
    return isPlusCode(first);
  }

  /// Picks the geocode hit most likely to be a real place name (Bole, Merkato, etc.).
  static PlaceResult? pickBestPlace(List<PlaceResult> places) {
    if (places.isEmpty) return null;
    PlaceResult? best;
    var bestScore = -0x7fffffff;
    for (final p in places) {
      final score = _scorePlace(p);
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }
    return best ?? places.first;
  }

  static int _scorePlace(PlaceResult place) {
    var score = 0;
    if (place.neighborhood != null &&
        !isPlusCode(place.neighborhood)) {
      score += 50;
    }
    if (place.sublocality != null && !isPlusCode(place.sublocality)) {
      score += 45;
    }
    if (place.establishment != null &&
        !isPlusCode(place.establishment)) {
      score += 40;
    }
    if (place.street != null &&
        place.street!.isNotEmpty &&
        !isPlusCode(place.street)) {
      score += 35;
    }
    if (place.city != null && !isPlusCode(place.city)) {
      score += 20;
    }
    if (place.isPlusCodeOnly) {
      score -= 100;
    }
    final readable = firstReadableSegment(place.displayName);
    if (readable != null && readable != place.city) {
      score += 15;
    }
    return score;
  }

  /// Primary line for forms / API `address_line_1`.
  static String line1FromPlace(PlaceResult place) {
    for (final candidate in [
      place.establishment,
      place.neighborhood,
      place.sublocality,
      place.street,
    ]) {
      if (candidate != null &&
          candidate.trim().isNotEmpty &&
          !isPlusCode(candidate)) {
        return candidate.trim();
      }
    }
    return firstReadableSegment(place.displayName) ??
        (place.city?.trim().isNotEmpty == true ? place.city!.trim() : 'Selected location');
  }

  /// Short label (Bole, Merkato, Pizza area name, etc.).
  static String labelFromPlace(PlaceResult place) {
    return place.areaLabel ??
        line1FromPlace(place);
  }
}
