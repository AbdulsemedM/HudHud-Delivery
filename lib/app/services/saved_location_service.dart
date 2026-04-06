import 'package:shared_preferences/shared_preferences.dart';

/// Persists and retrieves the user's saved delivery/location address.
class SavedLocationService {
  static const String _key = 'saved_delivery_address';
  static const String _latKey = 'saved_delivery_latitude';
  static const String _lngKey = 'saved_delivery_longitude';

  /// Get the user's saved delivery address, or null if none saved.
  static Future<String?> getSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (_) {
      return null;
    }
  }

  /// Save the user's delivery address.
  static Future<void> saveAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, address);
    } catch (_) {}
  }

  /// Save structured location data (address + coordinates).
  static Future<void> saveLocationData({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_key, address),
        prefs.setDouble(_latKey, latitude),
        prefs.setDouble(_lngKey, longitude),
      ]);
    } catch (_) {}
  }

  /// Returns saved address with coordinates when available.
  static Future<Map<String, dynamic>?> getSavedLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final address = prefs.getString(_key);
      if (address == null || address.isEmpty) return null;
      return {
        'address': address,
        'latitude': prefs.getDouble(_latKey),
        'longitude': prefs.getDouble(_lngKey),
      };
    } catch (_) {
      return null;
    }
  }
}
