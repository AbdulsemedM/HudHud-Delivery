import 'package:latlong2/latlong.dart';

import '../utils/human_readable_address.dart';

/// Represents a place from Google Places / Geocoding API (or any source).
class PlaceResult {
  final String? placeId;
  final String displayName;
  final LatLng coordinates;
  final String? street;
  final String? neighborhood;
  final String? sublocality;
  final String? establishment;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;

  /// Autocomplete structured labels (cleaner than Place Details in Ethiopia).
  final String? autocompleteMainText;
  final String? autocompleteSecondaryText;
  final String? autocompleteDescription;

  /// True when Google only returned a plus_code result for this hit.
  final bool isPlusCodeOnly;

  PlaceResult({
    this.placeId,
    required this.displayName,
    required this.coordinates,
    this.street,
    this.neighborhood,
    this.sublocality,
    this.establishment,
    this.city,
    this.state,
    this.country,
    this.postcode,
    this.autocompleteMainText,
    this.autocompleteSecondaryText,
    this.autocompleteDescription,
    this.isPlusCodeOnly = false,
  });

  /// Venue name for search suggestion title (Autocomplete main_text).
  String get suggestionTitle {
    if (autocompleteMainText != null &&
        autocompleteMainText!.trim().isNotEmpty) {
      return autocompleteMainText!.trim();
    }
    return venueLabel;
  }

  /// Area / city line for search suggestion subtitle (Autocomplete secondary_text).
  String get suggestionSubtitle {
    if (autocompleteSecondaryText != null &&
        autocompleteSecondaryText!.trim().isNotEmpty) {
      return autocompleteSecondaryText!.trim();
    }
    return _builtAreaLine();
  }

  /// Area-style name: Bole, Merkato, etc. (never a plus code).
  String? get areaLabel {
    for (final candidate in [
      neighborhood,
      sublocality,
      establishment,
      city,
    ]) {
      if (candidate != null &&
          candidate.trim().isNotEmpty &&
          !HumanReadableAddress.isPlusCode(candidate)) {
        return candidate.trim();
      }
    }
    return HumanReadableAddress.firstReadableSegment(displayName);
  }

  /// Venue or primary line for search suggestions (mall, hotel, street, etc.).
  String get venueLabel {
    for (final candidate in [
      establishment,
      street,
      neighborhood,
      sublocality,
    ]) {
      if (candidate != null &&
          candidate.trim().isNotEmpty &&
          !HumanReadableAddress.isPlusCode(candidate)) {
        return candidate.trim();
      }
    }
    return HumanReadableAddress.firstReadableSegment(displayName) ??
        formattedAddress;
  }

  /// Full formatted address for booking / order submission (no plus codes).
  String get formattedAddress {
    if (autocompleteDescription != null &&
        autocompleteDescription!.trim().isNotEmpty) {
      return HumanReadableAddress.stripPlusCodesFromAddress(
        autocompleteDescription!.trim(),
      );
    }

    final fromComponents = _buildFromComponents();
    if (fromComponents.isNotEmpty) {
      return fromComponents;
    }

    return HumanReadableAddress.stripPlusCodesFromAddress(displayName.trim());
  }

  /// True when the place looks city-level only (no venue, street, or neighborhood).
  bool get isCityLevelOnly {
    if (establishment != null && establishment!.trim().isNotEmpty) return false;
    if (street != null && street!.trim().isNotEmpty) return false;
    if (neighborhood != null && neighborhood!.trim().isNotEmpty) return false;
    if (sublocality != null && sublocality!.trim().isNotEmpty) return false;
    if (autocompleteMainText != null &&
        autocompleteMainText!.trim().isNotEmpty) {
      return false;
    }

    final segments = formattedAddress
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !HumanReadableAddress.isPlusCode(s))
        .toList();
    return segments.length <= 1;
  }

  String get shortAddress {
    final area = areaLabel;
    if (area != null) {
      final parts = <String>[area];
      if (city != null &&
          city!.trim().isNotEmpty &&
          city!.trim().toLowerCase() != area.toLowerCase()) {
        parts.add(city!.trim());
      }
      return parts.join(', ');
    }
    return HumanReadableAddress.firstReadableSegment(displayName) ?? displayName;
  }

  String _builtAreaLine() {
    final parts = <String>[];
    for (final candidate in [neighborhood, sublocality, city, state, country]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      if (HumanReadableAddress.isPlusCode(candidate)) continue;
      if (parts.any((p) => p.toLowerCase() == candidate.trim().toLowerCase())) {
        continue;
      }
      parts.add(candidate.trim());
    }
    if (parts.isNotEmpty) return parts.join(', ');
    return HumanReadableAddress.stripPlusCodesFromAddress(displayName);
  }

  String _buildFromComponents() {
    final parts = <String>[];
    for (final candidate in [
      establishment,
      street,
      neighborhood,
      sublocality,
      city,
      state,
      country,
    ]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      if (HumanReadableAddress.isPlusCode(candidate)) continue;
      if (parts.any((p) => p.toLowerCase() == candidate.trim().toLowerCase())) {
        continue;
      }
      parts.add(candidate.trim());
    }
    if (parts.isNotEmpty) return parts.join(', ');

    return HumanReadableAddress.stripPlusCodesFromAddress(displayName);
  }
}
