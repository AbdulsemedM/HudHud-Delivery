import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/google_maps_api_key_provider.dart';
import '../models/place_result.dart';
import '../utils/human_readable_address.dart';

/// Google Places Autocomplete, Place Details, and Geocoding (reverse).
/// Uses the same API key as the map (from .env via Android BuildConfig).
/// All results are restricted to Ethiopia.
class GooglePlacesService {
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _textSearchUrl =
      'https://maps.googleapis.com/maps/api/place/textsearch/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Restrict suggestions to Ethiopia (ISO 3166-1 alpha-2: et).
  static const String _countryRestriction = 'country:et';

  /// Fetch place suggestions for the given [input]. Only returns places in Ethiopia.
  ///
  /// Autocomplete returns at most 5 predictions; Text Search adds up to 20 more.
  /// Results are merged (autocomplete first) and deduped by [place_id].
  static Future<List<PlaceResult>> searchPlaces(String input) async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (key.isEmpty) return [];

    final query = input.trim();
    if (query.length < 2) return [];

    try {
      final results = await Future.wait([
        _searchAutocomplete(key, query),
        _searchTextSearch(key, query),
      ]);
      return _mergePlaces(results[0], results[1]);
    } catch (e) {
      return [];
    }
  }

  static Future<List<PlaceResult>> _searchAutocomplete(
    String key,
    String query,
  ) async {
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

    final detailFutures = <Future<PlaceResult?>>[];
    for (final p in predictions) {
      final map = p as Map<String, dynamic>;
      final placeId = map['place_id'] as String?;
      final description = map['description'] as String? ?? '';
      final structured = map['structured_formatting'] as Map<String, dynamic>?;
      final mainText = structured?['main_text'] as String? ?? description;
      final secondaryText = structured?['secondary_text'] as String? ?? '';

      if (placeId == null || placeId.isEmpty) continue;

      detailFutures.add(
        _fetchPlaceDetails(
          key,
          placeId,
          fallbackDescription: description,
          fallbackMainText: mainText.isNotEmpty ? mainText : null,
          fallbackSecondaryText:
              secondaryText.isNotEmpty ? secondaryText : null,
          fallbackEstablishment: mainText.isNotEmpty ? mainText : null,
        ),
      );
    }

    final resolved = await Future.wait(detailFutures);
    return resolved.whereType<PlaceResult>().toList();
  }

  static Future<List<PlaceResult>> _searchTextSearch(
    String key,
    String query,
  ) async {
    final uri = Uri.parse(
      '$_textSearchUrl?query=${Uri.encodeComponent(query)}&key=$key&region=et',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String?;
    if (status != 'OK' && status != 'ZERO_RESULTS') return [];

    final resultsList = json['results'] as List<dynamic>?;
    if (resultsList == null || resultsList.isEmpty) return [];

    final results = <PlaceResult>[];
    for (final r in resultsList) {
      final place = _placeFromTextSearchResult(r as Map<String, dynamic>);
      if (place != null) {
        results.add(place);
      }
    }
    return results;
  }

  static List<PlaceResult> _mergePlaces(
    List<PlaceResult> primary,
    List<PlaceResult> secondary,
  ) {
    final seen = <String>{};
    final merged = <PlaceResult>[];

    void addAll(List<PlaceResult> places) {
      for (final place in places) {
        final id = place.placeId;
        if (id != null && id.isNotEmpty) {
          if (seen.contains(id)) continue;
          seen.add(id);
        }
        merged.add(place);
      }
    }

    addAll(primary);
    addAll(secondary);
    return merged;
  }

  static PlaceResult? _placeFromTextSearchResult(Map<String, dynamic> map) {
    final placeId = map['place_id'] as String?;
    final name = map['name'] as String? ?? '';
    final formatted = map['formatted_address'] as String? ?? '';
    final geometry = map['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) return null;

    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final resultTypes = (map['types'] as List<dynamic>?)?.cast<String>() ?? [];
    final isPlusCodeOnly =
        resultTypes.length == 1 && resultTypes.contains('plus_code');

    var displayName = formatted.isNotEmpty ? formatted : name;
    if (displayName.isEmpty) return null;

    if (HumanReadableAddress.startsWithPlusCode(displayName) &&
        name.isNotEmpty) {
      displayName = name;
    }

    final secondaryText = _textSearchSecondaryText(name, formatted);

    return PlaceResult(
      placeId: placeId,
      displayName: displayName,
      coordinates: LatLng(lat, lng),
      establishment: name.isNotEmpty ? name : null,
      autocompleteMainText: name.isNotEmpty ? name : null,
      autocompleteSecondaryText: secondaryText,
      autocompleteDescription:
          formatted.isNotEmpty ? formatted : (name.isNotEmpty ? name : null),
      isPlusCodeOnly: isPlusCodeOnly,
    );
  }

  static String? _textSearchSecondaryText(String name, String formatted) {
    if (formatted.isEmpty) return null;
    if (name.isEmpty) return formatted;

    final lowerFormatted = formatted.toLowerCase();
    final lowerName = name.toLowerCase();
    if (lowerFormatted.startsWith(lowerName)) {
      final remainder = formatted.substring(name.length).trim();
      if (remainder.startsWith(',')) {
        return remainder.substring(1).trim();
      }
      if (remainder.isNotEmpty) return remainder;
    }
    return formatted;
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
        final place = _placeFromGeocodeResult(map);
        if (place != null) {
          results.add(place);
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  static PlaceResult? _placeFromGeocodeResult(Map<String, dynamic> map) {
    final formatted = map['formatted_address'] as String? ?? '';
    final geometry = map['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (formatted.isEmpty || location == null) return null;

    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final resultTypes = (map['types'] as List<dynamic>?)?.cast<String>() ?? [];
    final isPlusCodeOnly =
        resultTypes.length == 1 && resultTypes.contains('plus_code');

    final parsed = _parseAddressComponents(
      map['address_components'] as List<dynamic>? ?? [],
    );

    return PlaceResult(
      placeId: map['place_id'] as String?,
      displayName: formatted,
      coordinates: LatLng(lat, lng),
      street: parsed.street,
      neighborhood: parsed.neighborhood,
      sublocality: parsed.sublocality,
      establishment: parsed.establishment,
      city: parsed.city,
      state: parsed.state,
      country: parsed.country,
      postcode: parsed.postcode,
      isPlusCodeOnly: isPlusCodeOnly,
    );
  }

  static Future<PlaceResult?> _fetchPlaceDetails(
    String key,
    String placeId, {
    String? fallbackDescription,
    String? fallbackMainText,
    String? fallbackSecondaryText,
    String? fallbackEstablishment,
  }) async {
    try {
      final uri = Uri.parse(
        '$_detailsUrl?place_id=${Uri.encodeComponent(placeId)}&key=$key&fields=geometry,formatted_address,address_components,name,types',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      final result = json['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      final formatted = result['formatted_address'] as String? ?? '';
      final name = result['name'] as String? ?? '';
      final resultTypes =
          (result['types'] as List<dynamic>?)?.cast<String>() ?? [];
      final isPlusCodeOnly =
          resultTypes.length == 1 && resultTypes.contains('plus_code');

      final parsed = _parseAddressComponents(
        result['address_components'] as List<dynamic>? ?? [],
      );

      var establishment = parsed.establishment;
      if (establishment == null || establishment.trim().isEmpty) {
        if (name.isNotEmpty &&
            !resultTypes.contains('locality') &&
            !resultTypes.contains('administrative_area_level_1')) {
          establishment = name;
        } else if (fallbackEstablishment != null &&
            fallbackEstablishment.trim().isNotEmpty) {
          establishment = fallbackEstablishment.trim();
        }
      }

      var displayName = formatted.isNotEmpty
          ? formatted
          : (fallbackDescription?.isNotEmpty == true
              ? fallbackDescription!
              : name);

      if (HumanReadableAddress.startsWithPlusCode(displayName) &&
          fallbackDescription != null &&
          fallbackDescription.trim().isNotEmpty) {
        displayName = fallbackDescription.trim();
      }

      if (displayName.isEmpty) return null;

      return PlaceResult(
        placeId: placeId,
        displayName: displayName,
        coordinates: LatLng(lat, lng),
        street: parsed.street,
        neighborhood: parsed.neighborhood,
        sublocality: parsed.sublocality,
        establishment: establishment,
        city: parsed.city,
        state: parsed.state,
        country: parsed.country,
        postcode: parsed.postcode,
        autocompleteMainText: fallbackMainText,
        autocompleteSecondaryText: fallbackSecondaryText,
        autocompleteDescription: fallbackDescription,
        isPlusCodeOnly: isPlusCodeOnly,
      );
    } catch (_) {
      return null;
    }
  }

  static _ParsedAddressComponents _parseAddressComponents(
    List<dynamic> components,
  ) {
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
    return _ParsedAddressComponents(
      street: trimmedStreet?.isEmpty == true ? null : trimmedStreet,
      neighborhood: neighborhood,
      sublocality: sublocality,
      establishment: establishment,
      city: city,
      state: state,
      country: country,
      postcode: postcode,
    );
  }
}

class _ParsedAddressComponents {
  final String? street;
  final String? neighborhood;
  final String? sublocality;
  final String? establishment;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;

  const _ParsedAddressComponents({
    this.street,
    this.neighborhood,
    this.sublocality,
    this.establishment,
    this.city,
    this.state,
    this.country,
    this.postcode,
  });
}
