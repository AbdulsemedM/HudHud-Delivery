import 'package:latlong2/latlong.dart';

import '../utils/human_readable_address.dart';

/// Represents a place from Google Places / Geocoding API (or any source).
class PlaceResult {
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

  /// True when Google only returned a plus_code result for this hit.
  final bool isPlusCodeOnly;

  PlaceResult({
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
    this.isPlusCodeOnly = false,
  });

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
}
