import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/google_maps_api_key_provider.dart';
import '../models/city_service_area.dart';
import '../models/place_result.dart';
import '../services/city_scope.dart';
import '../utils/human_readable_address.dart';

/// Google Places Autocomplete, Place Details, and Geocoding (reverse).
/// Uses the same API key as the map (from .env via Android BuildConfig).
///
/// Phase 10: results follow the selected city ([CityScope.current]): the
/// market's country, a bias towards the city, and — when the server
/// enforces one city per request — a hard `locationrestriction` plus a
/// client-side filter so only places inside the city come back. Without a
/// known city the search stays restricted to Ethiopia, as before.
class GooglePlacesService {
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _textSearchUrl =
      'https://maps.googleapis.com/maps/api/place/textsearch/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const _nearbySearchUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  /// A named place (shop, building, office…) within this distance of the pin
  /// gives the address its name.
  static const double namedPlaceRadiusMeters = 50;

  /// Geocode hits further than this from the pin are ignored (stale fixes).
  static const double _maxGeocodeDistanceKm = 50;

  /// Nearby-search types that are areas, not places with their own name.
  static const Set<String> _areaTypes = {
    'route',
    'street_address',
    'intersection',
    'locality',
    'sublocality',
    'sublocality_level_1',
    'sublocality_level_2',
    'neighborhood',
    'political',
    'administrative_area_level_1',
    'administrative_area_level_2',
    'administrative_area_level_3',
    'country',
    'postal_code',
    'plus_code',
  };

  /// Default restriction without a known city: Ethiopia (ISO 3166-1 alpha-2: et).
  static const String _countryRestriction = 'country:et';

  /// Query parameters for Place Autocomplete in [area] (null = Ethiopia only).
  static Map<String, String> autocompleteScope(CityServiceArea? area) {
    final params = <String, String>{
      'components': area?.countryComponent ?? _countryRestriction,
    };
    final rectangle = area?.autocompleteRestriction;
    if (rectangle != null) {
      // Hard limit when the city rule is enforced, otherwise a preference.
      params[area!.enforced ? 'locationrestriction' : 'locationbias'] =
          rectangle;
    }
    return params;
  }

  /// Query parameters for Text Search in [area] (bias only; filtered after).
  static Map<String, String> textSearchScope(CityServiceArea? area) {
    final cc = area?.countryCode?.trim().toLowerCase();
    final params = <String, String>{
      'region': cc != null && cc.length == 2 ? cc : 'et',
    };
    if (area != null && area.hasCenter) {
      params['location'] = '${area.centerLat},${area.centerLng}';
      final radius = (area.radiusKm * 1000).round().clamp(1000, 50000);
      params['radius'] = radius.toString();
    }
    return params;
  }

  /// Drops places outside an enforced city.
  static List<PlaceResult> filterToCity(
    List<PlaceResult> places,
    CityServiceArea? area,
  ) {
    if (area == null || !area.enforced) return places;
    return places
        .where(
          (p) => area.contains(
            p.coordinates.latitude,
            p.coordinates.longitude,
          ),
        )
        .toList();
  }

  /// Fetch place suggestions for the given [input]. Only returns places in Ethiopia.
  ///
  /// Autocomplete returns at most 5 predictions; Text Search adds up to 20 more.
  /// Results are merged (autocomplete first) and deduped by [place_id].
  static Future<List<PlaceResult>> searchPlaces(String input) async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (key.isEmpty) return [];

    final query = input.trim();
    if (query.length < 2) return [];

    final area = CityScope.current;
    try {
      final results = await Future.wait([
        _searchAutocomplete(key, query, area),
        _searchTextSearch(key, query, area),
      ]);
      return filterToCity(_mergePlaces(results[0], results[1]), area);
    } catch (e) {
      return [];
    }
  }

  static Future<List<PlaceResult>> _searchAutocomplete(
    String key,
    String query,
    CityServiceArea? area,
  ) async {
    final uri = Uri.parse(_autocompleteUrl).replace(
      queryParameters: {
        'input': query,
        'key': key,
        ...autocompleteScope(area),
      },
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
    CityServiceArea? area,
  ) async {
    final uri = Uri.parse(_textSearchUrl).replace(
      queryParameters: {
        'query': query,
        'key': key,
        ...textSearchScope(area),
      },
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

  /// Describes the exact point a user picked on the map.
  ///
  /// Combines the nearest named place (Places Nearby Search, within
  /// [namedPlaceRadiusMeters]) with the area details from reverse geocoding,
  /// e.g. "Edna Mall, Bole, Addis Ababa". Without a named place nearby it
  /// falls back to the best geocode result. The returned coordinates are
  /// always the queried point, not Google's nearest address point.
  static Future<PlaceResult?> placeAtPoint(
    double latitude,
    double longitude,
  ) async {
    final point = LatLng(latitude, longitude);
    final (geocoded, venue) = await (
      reverseGeocode(latitude, longitude),
      _nearestNamedPlace(point),
    ).wait;

    const distance = Distance();
    final nearby = geocoded
        .where((r) =>
            distance.as(LengthUnit.Kilometer, point, r.coordinates) <=
            _maxGeocodeDistanceKm)
        .toList();
    final area = HumanReadableAddress.pickBestPlace(nearby);

    if (area == null && venue == null) return null;
    if (venue == null) return _withCoordinates(area!, point);

    final areaText = area?.displayName ?? venue.vicinity ?? '';
    return PlaceResult(
      placeId: venue.placeId,
      displayName:
          areaText.isEmpty ? venue.name : '${venue.name}, $areaText',
      coordinates: point,
      establishment: venue.name,
      street: area?.street,
      neighborhood: area?.neighborhood,
      sublocality: area?.sublocality,
      city: area?.city,
      state: area?.state,
      country: area?.country,
      postcode: area?.postcode,
    );
  }

  static PlaceResult _withCoordinates(PlaceResult place, LatLng point) {
    return PlaceResult(
      placeId: place.placeId,
      displayName: place.displayName,
      coordinates: point,
      street: place.street,
      neighborhood: place.neighborhood,
      sublocality: place.sublocality,
      establishment: place.establishment,
      city: place.city,
      state: place.state,
      country: place.country,
      postcode: place.postcode,
      isPlusCodeOnly: place.isPlusCodeOnly,
    );
  }

  /// Closest place with its own name (not a road or area) near [point].
  static Future<NamedPlaceHit?> _nearestNamedPlace(LatLng point) async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (key.isEmpty) return null;

    try {
      final uri = Uri.parse(_nearbySearchUrl).replace(queryParameters: {
        'location': '${point.latitude},${point.longitude}',
        'radius': namedPlaceRadiusMeters.toStringAsFixed(0),
        'key': key,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      return nearestNamedPlaceFrom(
        (json['results'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>(),
        point,
      );
    } catch (_) {
      return null;
    }
  }

  /// Picks the closest named place in a Nearby Search [results] list.
  /// Visible for tests.
  static NamedPlaceHit? nearestNamedPlaceFrom(
    List<Map<String, dynamic>> results,
    LatLng point,
  ) {
    const distance = Distance();
    NamedPlaceHit? best;
    double? bestMeters;
    for (final r in results) {
      final name = (r['name'] as String?)?.trim() ?? '';
      if (name.isEmpty || HumanReadableAddress.isNoiseSegment(name)) continue;
      if (r['business_status'] == 'CLOSED_PERMANENTLY') continue;

      final types = (r['types'] as List<dynamic>?)?.cast<String>() ?? const [];
      if (types.isEmpty || types.every(_areaTypes.contains)) continue;
      if (types.contains('route') || types.contains('locality')) continue;

      final loc = (r['geometry'] as Map<String, dynamic>?)?['location']
          as Map<String, dynamic>?;
      final lat = (loc?['lat'] as num?)?.toDouble();
      final lng = (loc?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final meters = distance.as(LengthUnit.Meter, point, LatLng(lat, lng));
      if (meters > namedPlaceRadiusMeters) continue;
      if (bestMeters == null || meters < bestMeters) {
        bestMeters = meters;
        best = NamedPlaceHit(
          name: name,
          placeId: r['place_id'] as String?,
          vicinity: (r['vicinity'] as String?)?.trim(),
          meters: meters,
        );
      }
    }
    return best;
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

      if (types.contains('route') && HumanReadableAddress.isUnnamedRoad(long)) {
        // Google's "Unnamed Road" placeholder is not a street; the area,
        // neighborhood and city components describe the place instead.
        continue;
      }
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

/// Closest named place found by Nearby Search.
class NamedPlaceHit {
  const NamedPlaceHit({
    required this.name,
    required this.meters,
    this.placeId,
    this.vicinity,
  });

  final String name;
  final String? placeId;
  final String? vicinity;

  /// Distance from the pin, in meters.
  final double meters;
}
