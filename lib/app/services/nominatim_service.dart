import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    
    return PlaceResult(
      displayName: json['display_name'] ?? '',
      coordinates: LatLng(
        double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
        double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      ),
      street: address['road'] ?? address['street'],
      city: address['city'] ?? address['town'] ?? address['village'],
      state: address['state'],
      country: address['country'],
      postcode: address['postcode'],
    );
  }

  String get shortAddress {
    List<String> parts = [];
    
    if (street != null && street!.isNotEmpty) {
      parts.add(street!);
    }
    
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    
    if (parts.isEmpty && displayName.isNotEmpty) {
      // Fallback to first part of display name
      final firstPart = displayName.split(',').first.trim();
      return firstPart;
    }
    
    return parts.join(', ');
  }
}

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'HudHudDeliveryApp/1.0 (contact@hudhuddelivery.com)';
  
  /// Search for places using Nominatim API
  static Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      final url = Uri.parse(
        '$_baseUrl/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=10'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        
        return results
            .map((json) => PlaceResult.fromJson(json as Map<String, dynamic>))
            .where((place) => place.displayName.isNotEmpty)
            .toList();
      } else {
        print('Nominatim API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
  
  /// Reverse geocoding - get place from coordinates
  static Future<PlaceResult?> reverseGeocode(LatLng coordinates) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?lat=${coordinates.latitude}&lon=${coordinates.longitude}&format=json&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        
        if (result.containsKey('display_name')) {
          return PlaceResult.fromJson(result);
        }
      } else {
        print('Reverse geocoding error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
    
    return null;
  }
  
  /// Get suggestions for autocomplete
  static Future<List<String>> getSuggestions(String query) async {
    final places = await searchPlaces(query);
    return places.map((place) => place.displayName).toList();
  }
}