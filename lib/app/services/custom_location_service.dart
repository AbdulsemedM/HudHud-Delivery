import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  @override
  String toString() {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}

class CustomLocationService {
  static const MethodChannel _channel = MethodChannel('custom_location');
  static const String _defaultLocation = "Current Location";
  
  /// Check if location services are enabled on the device
  static Future<bool> isLocationServiceEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isLocationServiceEnabled');
      return result;
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      final PermissionStatus status = await Permission.location.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final PermissionStatus status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current location coordinates
  static Future<LocationData?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permissions
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        bool granted = await requestLocationPermission();
        if (!granted) {
          print('Location permission denied');
          return null;
        }
      }

      // Get current position using platform channel
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getCurrentLocation');
      
      return LocationData(
        latitude: result['latitude']?.toDouble() ?? 0.0,
        longitude: result['longitude']?.toDouble() ?? 0.0,
        accuracy: result['accuracy']?.toDouble(),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get current location as a formatted string
  static Future<String> getCurrentLocation() async {
    try {
      final LocationData? position = await getCurrentPosition();
      if (position != null) {
        return position.toString();
      }
      return _defaultLocation;
    } catch (e) {
      print('Error getting location: $e');
      return _defaultLocation;
    }
  }

  /// Initialize location permissions at app startup
  static Future<void> initializeLocationPermissions() async {
    try {
      print('Initializing location permissions...');
      
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      // Request location permission if not already granted
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        print('Requesting location permission...');
        bool granted = await requestLocationPermission();
        if (granted) {
          print('Location permission granted');
        } else {
          print('Location permission denied');
        }
      } else {
        print('Location permission already granted');
      }
    } catch (e) {
      print('Error initializing location permissions: $e');
    }
  }
}