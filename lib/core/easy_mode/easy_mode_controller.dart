import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists "Easy mode" (pictorial booking + spoken hints).
/// Defaults to ON for new installs so low-literacy users get the simpler path.
class EasyModeController extends ChangeNotifier {
  static const _prefsKey = 'easy_mode_enabled';

  bool _enabled = true;
  bool _ready = false;

  bool get enabled => _enabled;
  bool get ready => _ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_prefsKey)) {
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } else {
      _enabled = true;
      await prefs.setBool(_prefsKey, true);
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
