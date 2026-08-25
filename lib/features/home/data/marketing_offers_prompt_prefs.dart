import 'package:shared_preferences/shared_preferences.dart';

/// How often to show the marketing-offers prompt for users who have not opted in.
class MarketingOffersPromptPrefs {
  MarketingOffersPromptPrefs._();

  static const String launchCountKey = 'marketing_offers_prompt_launch_count';
  static const int showEveryNLaunches = 3;

  /// Counts an eligible app open. True on every [showEveryNLaunches]th open
  /// (3rd, 6th, …), not on the first two.
  static Future<bool> shouldShowThisLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(launchCountKey) ?? 0) + 1;
    await prefs.setInt(launchCountKey, next);
    return next % showEveryNLaunches == 0;
  }
}
