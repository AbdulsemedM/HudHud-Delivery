import 'package:permission_handler/permission_handler.dart';
import 'custom_location_service.dart';
import 'geocoding_service.dart';

class LocationService {
  static const String _defaultLocation = "Current Location";
  
  /// Get current location with actual GPS coordinates
  static Future<String> getCurrentLocation() async {
    try {
      return await CustomLocationService.getCurrentLocation();
    } catch (e) {
      print('Error getting location: $e');
      return _defaultLocation;
    }
  }
  
  /// Get current location as street address
  static Future<String> getCurrentLocationAddress() async {
    try {
      return await GeocodingService.getCurrentLocationAddress();
    } catch (e) {
      print('Error getting location address: $e');
      return _defaultLocation;
    }
  }
  
  /// Get current street name only
  static Future<String> getCurrentStreetName() async {
    try {
      return await GeocodingService.getCurrentStreetName();
    } catch (e) {
      print('Error getting street name: $e');
      return _defaultLocation;
    }
  }
  
  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      return await CustomLocationService.hasLocationPermission();
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }
  
  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      return await CustomLocationService.requestLocationPermission();
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current position coordinates
  static Future<LocationData?> getCurrentPosition() async {
    try {
      return await CustomLocationService.getCurrentPosition();
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
}