import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

String? validateLoginEmail(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.validationEmailRequired;
  }
  if (!_emailRegex.hasMatch(value.trim())) {
    return l10n.validationEmailInvalid;
  }
  return null;
}

String? validateLoginPhoneNational(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.validationPhoneRequired;
  }
  final digits = cleanNationalPhoneDigits(value);
  if (digits.length != 9) {
    return l10n.validationPhoneInvalid;
  }
  if (!digits.startsWith('9') && !digits.startsWith('7')) {
    return l10n.validationPhoneInvalid;
  }
  return null;
}

String normalizeLoginPhone(String countryCode, String nationalNumber) {
  final codeDigits = countryCode.replaceAll(RegExp(r'\D'), '');
  final national = cleanNationalPhoneDigits(nationalNumber);
  return normalizePhoneToBackend('$codeDigits$national');
}
