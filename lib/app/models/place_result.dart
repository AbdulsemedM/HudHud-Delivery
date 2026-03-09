import 'package:latlong2/latlong.dart';

/// Represents a place from Google Places / Geocoding API (or any source).
class PlaceResult {
  final String displayName;
  final LatLng coordinates;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;

  PlaceResult({
    required this.displayName,
    required this.coordinates,
    this.street,
    this.city,
    this.state,
    this.country,
    this.postcode,
  });

  String get shortAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (parts.isEmpty && displayName.isNotEmpty) {
      return displayName.split(',').first.trim();
    }
    return parts.join(', ');
  }
}
