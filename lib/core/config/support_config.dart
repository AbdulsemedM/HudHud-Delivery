/// Public support contact — replace with your real email/phone for production.
class SupportConfig {
  static const String supportEmail = 'support@hudhud.com';

  /// Fallback when no `SUPPORT_PHONE` dart-define is given.
  /// Short code 9491 (HudHud help line).
  static const String _defaultSupportPhoneE164 = '9491';

  static const String _supportPhoneDefine =
      String.fromEnvironment('SUPPORT_PHONE');

  /// Dialable number (short code or E.164), e.g. 9491 or +251911000000.
  /// Override at build time with `--dart-define=SUPPORT_PHONE=...`.
  static String get supportPhoneE164 {
    final fromEnv = _supportPhoneDefine.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return _defaultSupportPhoneE164;
  }
}
