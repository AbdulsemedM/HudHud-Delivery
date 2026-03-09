import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/google_maps_api_key_provider.dart';

/// Result of a directions request: decoded route polyline and distance in meters.
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final double distanceMeters;

  const DirectionsResult({
    required this.polylinePoints,
    required this.distanceMeters,
  });

  double get distanceKm => distanceMeters / 1000.0;
}

/// Fetches driving route (road path) from Google Directions API
/// and decodes polylines so the drawn route follows real roads.
class GoogleDirectionsService {
  static const _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Get driving route between origin and destination.
  /// Returns polyline points following roads and distance in meters, or null on failure.
  static Future<DirectionsResult?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (key.isEmpty) {
      if (kDebugMode) {
        print('Directions: No Google Maps API key.');
      }
      return null;
    }

    try {
      final uri = Uri.parse(
        '$_directionsUrl'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=driving'
        '&key=$key',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Directions: HTTP ${response.statusCode}');
        }
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String?;

      if (status != 'OK') {
        if (kDebugMode) {
          final errorMsg = json['error_message'] as String?;
          print('Directions: API status=$status. ${errorMsg ?? ""}');
          if (status == 'REQUEST_DENIED') {
            print('Directions: Enable "Directions API" in Google Cloud Console for this key.');
          }
        }
        return null;
      }

      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>?;

      // Prefer overview_polyline first (always follows roads when present)
      final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>?;
      final overviewEncoded = overviewPolyline?['points'] as String?;
      final points = <LatLng>[];

      if (overviewEncoded != null && overviewEncoded.isNotEmpty) {
        points.addAll(_decodePolyline(overviewEncoded));
      }

      // Optionally add more detail from each step's polyline (exact road geometry)
      double distanceMeters = 0;
      if (legs != null) {
        for (final legObj in legs) {
          final leg = legObj as Map<String, dynamic>;
          final distance = leg['distance'] as Map<String, dynamic>?;
          if (distance != null && distance['value'] != null) {
            distanceMeters += (distance['value'] as num).toDouble();
          }
          final steps = leg['steps'] as List<dynamic>?;
          if (steps != null && points.isEmpty) {
            for (final stepObj in steps) {
              final step = stepObj as Map<String, dynamic>;
              final polyline = step['polyline'] as Map<String, dynamic>?;
              final encoded = polyline?['points'] as String?;
              if (encoded != null && encoded.isNotEmpty) {
                points.addAll(_decodePolyline(encoded));
              }
            }
          }
        }
      }

      // If we only had overview, get distance from first leg
      if (distanceMeters == 0 && legs != null && legs.isNotEmpty) {
        final leg = legs.first as Map<String, dynamic>;
        final distance = leg['distance'] as Map<String, dynamic>?;
        if (distance != null && distance['value'] != null) {
          distanceMeters = (distance['value'] as num).toDouble();
        }
      }

      // Fallback: if no points from steps, overview already added above
      if (points.isEmpty && (overviewEncoded == null || overviewEncoded.isEmpty)) {
        if (kDebugMode) print('Directions: No overview_polyline or steps in response.');
        return null;
      }

      return DirectionsResult(
        polylinePoints: points,
        distanceMeters: distanceMeters,
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('Directions: $e');
        print(st);
      }
      return null;
    }
  }

  /// Decode Google's encoded polyline format into list of LatLng.
  /// See: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
