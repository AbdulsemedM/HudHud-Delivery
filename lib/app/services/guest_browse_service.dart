import 'package:shared_preferences/shared_preferences.dart';

/// Browse-only session without auth token (public `/api/public/*` catalog).
class GuestBrowseService {
  static final GuestBrowseService _instance = GuestBrowseService._internal();
  factory GuestBrowseService() => _instance;
  GuestBrowseService._internal();

  static const String _prefKey = 'guest_browse_mode';

  bool _cachedActive = false;
  bool _initialized = false;

  bool get isGuestBrowseMode => _cachedActive;

  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedActive = prefs.getBool(_prefKey) ?? false;
    _initialized = true;
  }

  Future<bool> isActive() async {
    await _ensureLoaded();
    return _cachedActive;
  }

  Future<void> enterGuestBrowseMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    _cachedActive = true;
    _initialized = true;
  }

  Future<void> clearGuestBrowseMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
    _cachedActive = false;
    _initialized = true;
  }
}
