import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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

enum LocationFetchFailure {
  permissionDenied,
  locationDisabled,
  locationTimeout,
  locationError,
  unknown,
}

class LocationFetchResult {
  const LocationFetchResult._({this.data, this.failure});

  final LocationData? data;
  final LocationFetchFailure? failure;

  bool get isSuccess => data != null;

  factory LocationFetchResult.success(LocationData data) =>
      LocationFetchResult._(data: data);

  factory LocationFetchResult.failure(LocationFetchFailure failure) =>
      LocationFetchResult._(failure: failure);
}

class CustomLocationService {
  static const MethodChannel _channel = MethodChannel('custom_location');
  static const String _defaultLocation = "Current Location";

  static Future<LocationFetchResult>? _inFlightFetch;

  /// Check if location services are enabled on the device
  static Future<bool> isLocationServiceEnabled() async {
    try {
      final bool result =
          await _channel.invokeMethod<bool>('isLocationServiceEnabled') ?? false;
      return result;
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  static Permission get _locationPermission => Permission.locationWhenInUse;

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      final PermissionStatus status = await _locationPermission.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permission (when-in-use on iOS/Android).
  static Future<bool> requestLocationPermission() async {
    try {
      final PermissionStatus status = await _locationPermission.request();
      if (status.isGranted) {
        return true;
      }
      if (kDebugMode) {
        if (status.isPermanentlyDenied) {
          debugPrint(
            'Location permission permanently denied. Open Settings > HudHud Delivery > Location to enable.',
          );
        } else {
          debugPrint('Location permission denied ($status)');
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Opens the app’s Settings page so the user can enable Location after "Don\'t Allow".
  static Future<bool> openLocationAppSettings() => openAppSettings();

  /// Returns true when permission is permanently denied (user must go to Settings).
  static Future<bool> isLocationPermissionPermanentlyDenied() async {
    try {
      return (await _locationPermission.status).isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  static LocationFetchFailure _failureFromPlatformCode(String? code) {
    switch (code) {
      case 'location_permission_denied':
      case 'PERMISSION_DENIED':
        return LocationFetchFailure.permissionDenied;
      case 'location_disabled':
      case 'NO_PROVIDER':
        return LocationFetchFailure.locationDisabled;
      case 'location_timeout':
        return LocationFetchFailure.locationTimeout;
      case 'location_error':
      case 'location_unavailable':
      case 'LOCATION_ERROR':
        return LocationFetchFailure.locationError;
      default:
        return LocationFetchFailure.unknown;
    }
  }

  /// Get current location with structured failure info.
  /// Only one native fetch runs at a time app-wide.
  static Future<LocationFetchResult> getCurrentPositionDetailed() {
    _inFlightFetch ??= _fetchCurrentPositionDetailed();
    return _inFlightFetch!.whenComplete(() {
      _inFlightFetch = null;
    });
  }

  static Future<LocationFetchResult> _fetchCurrentPositionDetailed() async {
    try {
      // On iOS, deprecated locationServicesEnabled() can false-negative; let native decide.
      if (!Platform.isIOS) {
        final serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (kDebugMode) {
            debugPrint('Location services are disabled');
          }
          return LocationFetchResult.failure(LocationFetchFailure.locationDisabled);
        }
      }

      if (!await hasLocationPermission()) {
        return LocationFetchResult.failure(LocationFetchFailure.permissionDenied);
      }

      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('getCurrentLocation');

      return LocationFetchResult.success(
        LocationData(
          latitude: result['latitude']?.toDouble() ?? 0.0,
          longitude: result['longitude']?.toDouble() ?? 0.0,
          accuracy: result['accuracy']?.toDouble(),
          timestamp: DateTime.now(),
        ),
      );
    } on PlatformException catch (e) {
      final failure = _failureFromPlatformCode(e.code);
      if (kDebugMode) {
        debugPrint(
          'Error getting current position (${e.code}): ${e.message}',
        );
      }
      return LocationFetchResult.failure(failure);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting current position: $e');
      }
      return LocationFetchResult.failure(LocationFetchFailure.unknown);
    }
  }

  /// Get current location coordinates.
  /// Permission must already be granted; call [requestLocationPermission] first if unsure.
  static Future<LocationData?> getCurrentPosition() async {
    final result = await getCurrentPositionDetailed();
    return result.data;
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
      debugPrint('Error getting location: $e');
      return _defaultLocation;
    }
  }

  /// Initialize location permissions at app startup
  static Future<void> initializeLocationPermissions() async {
    try {
      debugPrint('Initializing location permissions...');

      if (!Platform.isIOS) {
        final serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('Location services are disabled');
          return;
        }
      }

      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        debugPrint('Requesting location permission...');
        final granted = await requestLocationPermission();
        if (granted) {
          debugPrint('Location permission granted');
        } else {
          debugPrint('Location permission denied');
        }
      } else {
        debugPrint('Location permission already granted');
      }
    } catch (e) {
      debugPrint('Error initializing location permissions: $e');
    }
  }
}
