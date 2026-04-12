import 'package:hudhud_delivery/l10n/app_localizations.dart';

class GreetingUtils {
  static String getTimeBasedGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return l10n.greetingGoodMorning;
    } else if (hour >= 12 && hour < 17) {
      return l10n.greetingGoodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return l10n.greetingGoodEvening;
    } else {
      return l10n.greetingGoodNight;
    }
  }

  static String getGreetingWithName(AppLocalizations l10n, String? name) {
    final greeting = getTimeBasedGreeting(l10n);
    final displayName = name ?? l10n.userDefault;
    return '$greeting, $displayName';
  }
}