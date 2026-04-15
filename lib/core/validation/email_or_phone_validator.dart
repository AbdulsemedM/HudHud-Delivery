import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Shared validation for email or phone (matches login form rules).
String? validateEmailOrPhone(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) {
    return l10n.validationEmailOrPhoneRequired;
  }

  final trimmedValue = value.trim();

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (emailRegex.hasMatch(trimmedValue)) {
    return null;
  }

  String cleanedPhone = trimmedValue.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

  if (cleanedPhone.startsWith('+')) {
    if (RegExp(r'^\+[0-9]{10,15}$').hasMatch(cleanedPhone)) {
      return null;
    }
  } else {
    if (!RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
      return l10n.validationEmailOrPhoneInvalid;
    }

    if (cleanedPhone.startsWith('0') && cleanedPhone.length > 1) {
      cleanedPhone = cleanedPhone.substring(1);
    }

    if ((cleanedPhone.startsWith('9') || cleanedPhone.startsWith('7')) &&
        cleanedPhone.length == 9) {
      return null;
    }

    if (cleanedPhone.length >= 10 && cleanedPhone.length <= 15) {
      return null;
    }
  }

  return l10n.validationEmailOrPhoneInvalid;
}
