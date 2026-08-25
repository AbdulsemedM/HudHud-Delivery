import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Validates password strength for reset/signup flows.
/// Returns null when valid, or a localized error message.
String? validatePasswordStrength(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) {
    return l10n.validationPasswordRequired;
  }
  if (value.length < 6) {
    return l10n.validationPasswordMin;
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return l10n.validationPasswordComplexity;
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return l10n.validationPasswordComplexity;
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return l10n.validationPasswordComplexity;
  }
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(value)) {
    return l10n.validationPasswordComplexity;
  }
  return null;
}
