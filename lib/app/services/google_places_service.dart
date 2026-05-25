import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/google_maps_api_key_provider.dart';
import '../models/place_result.dart';

/// Google Places Autocomplete, Place Details, and Geocoding (reverse).
/// Uses the same API key as the map (from .env via Android BuildConfig).
/// All results are restricted to Ethiopia.
class GooglePlacesService {
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Restrict suggestions to Ethiopia (ISO 3166-1 alpha-2: et).
  static const String _countryRestriction = 'country:et';

  /// Fetch place suggestions for the given [input]. Only returns places in Ethiopia.
  static Future<List<PlaceResult>> searchPlaces(String input) async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (key.isEmpty) return [];

    final query = input.trim();
    if (query.length < 2) return [];

    try {
      final uri = Uri.parse(
        '$_autocompleteUrl?input=${Uri.encodeComponent(query)}&key=$key&components=$_countryRestriction',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') return [];

      final predictions = json['predictions'] as List<dynamic>?;
      if (predictions == null || predictions.isEmpty) return [];

      final results = <PlaceResult>[];
      for (final p in predictions.take(8)) {
        final map = p as Map<String, dynamic>;
        final placeId = map['place_id'] as String?;
        final description = map['description'] as String? ?? '';
        final structured = map['structured_formatting'] as Map<String, dynamic>?;
        final mainText = structured?['main_text'] as String? ?? description;
        final secondaryText = structured?['secondary_text'] as String? ?? '';

        if (placeId == null || placeId.isEmpty) continue;

        final coords = await _getPlaceDetails(key, placeId);
        if (coords == null) continue;

        results.add(PlaceResult(
          displayName: description,
          coordinates: coords,
          street: mainText.isNotEmpty ? mainText : null,
          city: secondaryText.isNotEmpty ? secondaryText : null,
        ));
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  /// Reverse geocode: get address(es) for the given coordinates. Uses Google Geocoding API.
  static Future<List<PlaceResult>> reverseGeocode(
      double latitude, double longitude) async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (key.isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_geocodeUrl?latlng=$latitude,$longitude&key=$key',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return [];

      final resultsList = json['results'] as List<dynamic>?;
      if (resultsList == null || resultsList.isEmpty) return [];

      final results = <PlaceResult>[];
      for (final r in resultsList) {
        final map = r as Map<String, dynamic>;
        final formatted = map['formatted_address'] as String? ?? '';
        final geometry = map['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;
        if (formatted.isEmpty || location == null) continue;

        final lat = (location['lat'] as num?)?.toDouble();
        final lng = (location['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final resultTypes =
            (map['types'] as List<dynamic>?)?.cast<String>() ?? [];
        final isPlusCodeOnly = resultTypes.length == 1 &&
            resultTypes.contains('plus_code');

        final components = map['address_components'] as List<dynamic>? ?? [];
        String? street;
        String? neighborhood;
        String? sublocality;
        String? establishment;
        String? city;
        String? state;
        String? country;
        String? postcode;

        for (final c in components) {
          final comp = c as Map<String, dynamic>;
          final types = (comp['types'] as List<dynamic>?)?.cast<String>() ?? [];
          final long = comp['long_name'] as String? ?? '';
          if (long.isEmpty) continue;

          if (types.contains('street_number') || types.contains('route')) {
            street = (street ?? '') + (street != null ? ' ' : '') + long;
          } else if (types.contains('neighborhood')) {
            neighborhood ??= long;
          } else if (types.contains('sublocality') ||
              types.contains('sublocality_level_1')) {
            sublocality ??= long;
          } else if (types.contains('administrative_area_level_2') &&
              sublocality == null) {
            sublocality = long;
          } else if (types.contains('establishment') ||
              types.contains('point_of_interest') ||
              types.contains('premise')) {
            establishment ??= long;
          } else if (types.contains('locality')) {
            city = long;
          } else if (types.contains('administrative_area_level_1')) {
            state = long;
          } else if (types.contains('country')) {
            country = long;
          } else if (types.contains('postal_code')) {
            postcode = long;
          }
        }

        final trimmedStreet = street?.trim();
        results.add(PlaceResult(
          displayName: formatted,
          coordinates: LatLng(lat, lng),
          street: trimmedStreet?.isEmpty == true ? null : trimmedStreet,
          neighborhood: neighborhood,
          sublocality: sublocality,
          establishment: establishment,
          city: city,
          state: state,
          country: country,
          postcode: postcode,
          isPlusCodeOnly: isPlusCodeOnly,
        ));
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  static Future<LatLng?> _getPlaceDetails(String key, String placeId) async {
    try {
      final uri = Uri.parse(
        '$_detailsUrl?place_id=${Uri.encodeComponent(placeId)}&key=$key&fields=geometry,formatted_address',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      final result = json['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }
}
