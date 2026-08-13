import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the home onboarding tour has been shown on this device.
class OnboardingTourPrefs {
  OnboardingTourPrefs._();

  static const String seenKey = 'has_seen_home_tour_v2';

  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(seenKey) ?? false;
  }

  static Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKey, true);
  }

  /// Clears the seen flag so the tour replays on next Home screen visit.
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(seenKey);
  }
}
