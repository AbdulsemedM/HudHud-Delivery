import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Import for distance calculation
import 'package:latlong2/latlong.dart' show Distance;

// Import mock service for fallback
import 'mock_location_service.dart';

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
  /// Falls back to mock data if the API call fails
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
      ).timeout(const Duration(seconds: 5)); // Add timeout to prevent long waits
      
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        
        return results
            .map((json) => PlaceResult.fromJson(json as Map<String, dynamic>))
            .where((place) => place.displayName.isNotEmpty)
            .toList();
      } else {
        print('Nominatim API error: ${response.statusCode}');
        // Fall back to mock data
        return _getFallbackLocations(query);
      }
    } catch (e) {
      print('Error searching places: $e');
      // Fall back to mock data
      return _getFallbackLocations(query);
    }
  }
  
  /// Get fallback locations from mock data based on search query
  static List<PlaceResult> _getFallbackLocations(String query) {
    return MockLocationService.getMockLocations(query);
  }
  
  /// Get fallback locations near specified coordinates
  static List<PlaceResult> _getFallbackLocationsNearby(double latitude, double longitude) {
    // Get all mock locations
    final allMockLocations = MockLocationService.getMockLocations("");
    
    // Sort by distance to the given coordinates
    allMockLocations.sort((a, b) {
      final distA = Distance().distance(
        LatLng(latitude, longitude),
        a.coordinates
      );
      final distB = Distance().distance(
        LatLng(latitude, longitude),
        b.coordinates
      );
      return distA.compareTo(distB);
    });
    
    // Return the closest location or all if there are few
    return allMockLocations.take(3).toList();
  }
  
  /// Reverse geocoding - get place from coordinates
  /// Returns a list of places near the given coordinates
  static Future<List<PlaceResult>> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5)); // Add timeout to prevent long waits
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        
        if (result.containsKey('display_name')) {
          final place = PlaceResult.fromJson(result);
          return [place];
        }
      } else {
        print('Reverse geocoding error: ${response.statusCode}');
        // Fall back to mock data
        return _getFallbackLocationsNearby(latitude, longitude);
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
      // Fall back to mock data
      return _getFallbackLocationsNearby(latitude, longitude);
    }
    
    // If we get here, something went wrong but we didn't catch it
    return _getFallbackLocationsNearby(latitude, longitude);
  }
  
  /// Get suggestions for autocomplete
  static Future<List<String>> getSuggestions(String query) async {
    final places = await searchPlaces(query);
    return places.map((place) => place.displayName).toList();
  }
}