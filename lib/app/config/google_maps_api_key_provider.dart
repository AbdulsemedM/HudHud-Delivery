import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Provides the Google keys from the native side (Android BuildConfig / iOS
/// Info.plist). Falls back to empty string on an unsupported platform.
///
/// THERE ARE TWO KEYS AND THEY ARE NOT INTERCHANGEABLE.
///
/// [getKey] is the Maps SDK key — the one in the Android manifest as
/// `com.google.android.geo.API_KEY`, used to draw map tiles. It carries an
/// "Android apps" application restriction, which only the Maps SDKs honour.
///
/// [getWebKey] is for anything that talks to `maps.googleapis.com` over HTTPS:
/// Places autocomplete, place details, nearby search, Geocoding, Directions.
/// Google does not apply Android/iOS application restrictions to those
/// endpoints — a key that carries one is rejected with REQUEST_DENIED — so
/// they need a separate, app-unrestricted key whose API restriction is
/// narrowed to those three APIs instead.
///
/// Sending the SDK key to a web service fails *silently from the user's seat*:
/// the map still renders, and only address search stops working. If you add a
/// new call to maps.googleapis.com, use [getWebKey].
class GoogleMapsApiKeyProvider {
  GoogleMapsApiKeyProvider._();
  static const _channel = MethodChannel('hudhud_delivery/config');

  static String? _cachedKey;
  static String? _cachedWebKey;

  /// Returns the Maps SDK key, or empty string if unavailable.
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

  /// Returns the key for maps.googleapis.com web services.
  ///
  /// Falls back to [getKey] when the host app predates the split — an older
  /// native binary answers `getGoogleMapsWebKey` with MissingPluginException,
  /// and behaving as before beats returning empty and breaking address search
  /// for everyone on that build.
  static Future<String> getWebKey() async {
    if (_cachedWebKey != null) return _cachedWebKey!;
    try {
      final key = await _channel.invokeMethod<String>('getGoogleMapsWebKey');
      final resolved = key ?? '';
      _cachedWebKey = resolved.isNotEmpty ? resolved : await getKey();
      return _cachedWebKey!;
    } on MissingPluginException {
      _cachedWebKey = await getKey();
      return _cachedWebKey!;
    } on PlatformException {
      _cachedWebKey = await getKey();
      return _cachedWebKey!;
    }
  }

  /// Test seam only.
  @visibleForTesting
  static void resetForTest() {
    _cachedKey = null;
    _cachedWebKey = null;
  }
}
