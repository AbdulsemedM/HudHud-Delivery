import 'package:flutter/services.dart';

/// Provides the Google Maps API key from the native side (Android BuildConfig / iOS Info.plist).
/// Used for Google Places API calls in Dart. Falls back to empty string on unsupported platform.
class GoogleMapsApiKeyProvider {
  GoogleMapsApiKeyProvider._();
  static const _channel = MethodChannel('hudhud_delivery/config');

  static String? _cachedKey;

  /// Returns the Google Maps API key, or empty string if unavailable.
  static Future<String> getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    try {
      final key = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      _cachedKey = key ?? '';
      return _cachedKey!;
    } on PlatformException {
      _cachedKey = '';
      return '';
    }
  }
}
