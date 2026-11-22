import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists "Easy mode" (pictorial booking + spoken hints).
/// Defaults to ON for new installs so low-literacy users get the simpler path.
class EasyModeController extends ChangeNotifier {
  static const _prefsKey = 'easy_mode_enabled';
  static const _voicePrefsKey = 'easy_mode_voice_auto';

  bool _enabled = true;

  /// Whether each step reads itself aloud as the customer arrives on it.
  ///
  /// OFF by default, deliberately, and separately from [enabled].
  ///
  /// Easy mode used to start talking the moment the wizard opened and again
  /// on every step. That is the right behaviour for someone who cannot read
  /// the screen and the wrong behaviour for everyone else — and it is the
  /// customer app, so it fires in shops, on buses, next to other people, with
  /// no warning and no way to predict it. A phone that speaks without being
  /// asked is a reason to close it.
  ///
  /// The capability does not go away: the Listen button on every step still
  /// speaks on demand, which is the whole feature for the person who needs
  /// it. This flag only decides whether it speaks WITHOUT being asked.
  bool _voiceAutoSpeak = false;

  bool _ready = false;

  bool get enabled => _enabled;

  /// Whether steps speak on their own. The Listen button ignores this.
  bool get voiceAutoSpeak => _voiceAutoSpeak;

  bool get ready => _ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_prefsKey)) {
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } else {
      _enabled = true;
      await prefs.setBool(_prefsKey, true);
    }

    // No write-on-first-read here, unlike `enabled` above. An absent key must
    // stay absent so the default can be revisited later without silently
    // having stamped `false` into every install that ever opened the app.
    _voiceAutoSpeak = prefs.getBool(_voicePrefsKey) ?? false;

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

  Future<void> setVoiceAutoSpeak(bool value) async {
    if (_voiceAutoSpeak == value) return;
    _voiceAutoSpeak = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voicePrefsKey, value);
  }
}
