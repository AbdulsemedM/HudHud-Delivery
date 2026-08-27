import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Minimum password length for reset/signup flows.
const int kMinPasswordLength = 4;

/// Validates password strength for reset/signup flows.
/// Returns null when valid, or a localized error message.
String? validatePasswordStrength(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) {
    return l10n.validationPasswordRequired;
  }
  if (value.length < kMinPasswordLength) {
    return l10n.validationPasswordMin;
  }
  return null;
}
