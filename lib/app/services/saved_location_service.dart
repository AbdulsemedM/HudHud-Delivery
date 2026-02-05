import 'package:shared_preferences/shared_preferences.dart';

/// Persists and retrieves the user's saved delivery/location address.
class SavedLocationService {
  static const String _key = 'saved_delivery_address';

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
}
