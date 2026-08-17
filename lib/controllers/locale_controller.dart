import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's app language (English + regional languages).
class LocaleController extends ChangeNotifier {
  static const String _prefsKey = 'app_locale_language_code';

  /// BCP 47 language codes used by [Locale].
  static const String langEnglish = 'en';
  static const String langAmharic = 'am';
  static const String langOromo = 'om';
  static const String langSomali = 'so';
  static const String langArabic = 'ar';

  static const List<String> supportedLanguageCodes = [
    langEnglish,
    langAmharic,
    langOromo,
    langSomali,
    langArabic,
  ];

  Locale _locale = const Locale(langEnglish);

  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      _locale = Locale(code);
      Intl.defaultLocale = code;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    if (_locale == locale) return;
    _locale = locale;
    Intl.defaultLocale = locale.languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
    notifyListeners();
  }
}
