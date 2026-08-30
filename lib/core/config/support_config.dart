import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Public support contact — replace with your real email/phone for production.
class SupportConfig {
  static const String supportEmail = 'support@hudhud.com';

  /// Fallback when `.env` has no `SUPPORT_PHONE`. Override via env in production.
  /// Short code 9491 (HudHud help line).
  static const String _defaultSupportPhoneE164 = '9491';

  /// Dialable number (short code or E.164), e.g. 9491 or +251911000000.
  static String get supportPhoneE164 {
    try {
      if (dotenv.isInitialized) {
        final fromEnv = dotenv.maybeGet('SUPPORT_PHONE')?.trim();
        if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
      }
    } catch (_) {}
    return _defaultSupportPhoneE164;
  }
}
