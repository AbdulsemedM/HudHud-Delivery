import 'package:country_picker/country_picker.dart';

/// Country dial code (e.g. `+251`) and national number for separate form fields.
class PhoneDisplayParts {
  const PhoneDisplayParts({
    required this.countryDialCode,
    required this.nationalNumber,
  });

  final String countryDialCode;
  final String nationalNumber;
}

/// Default dial code when the stored phone cannot be parsed.
const String kDefaultPhoneDialCode = '+251';

/// Splits a stored phone into country code and national number for UI fields.
///
/// Handles `+251912345678`, `251912345678`, `254712345678`, and local `0912345678`.
PhoneDisplayParts splitPhoneForDisplay(
  String? phone, {
  String defaultDialCode = kDefaultPhoneDialCode,
}) {
  final raw = phone?.trim() ?? '';
  if (raw.isEmpty) {
    return PhoneDisplayParts(
      countryDialCode: defaultDialCode,
      nationalNumber: '',
    );
  }

  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return PhoneDisplayParts(
      countryDialCode: defaultDialCode,
      nationalNumber: '',
    );
  }

  // Local trunk prefix (e.g. 0912345678) — national only, default Ethiopia.
  if (digits.startsWith('0') && digits.length >= 10) {
    return PhoneDisplayParts(
      countryDialCode: defaultDialCode,
      nationalNumber: digits.substring(1),
    );
  }

  final phoneCodes = CountryService()
      .getAll()
      .map((c) => c.phoneCode)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final code in phoneCodes) {
    if (digits.startsWith(code) && digits.length > code.length) {
      var national = digits.substring(code.length);
      if (national.startsWith('0') && national.length > 1) {
        national = national.substring(1);
      }
      return PhoneDisplayParts(
        countryDialCode: '+$code',
        nationalNumber: national,
      );
    }
  }

  return PhoneDisplayParts(
    countryDialCode: defaultDialCode,
    nationalNumber: digits,
  );
}

/// Human-readable phone for read-only profile views.
String formatPhoneForDisplay(String? phone) {
  final parts = splitPhoneForDisplay(phone);
  if (parts.nationalNumber.isEmpty) return '';
  return '${parts.countryDialCode} ${parts.nationalNumber}';
}

/// Strips non-digits and a leading trunk `0` from the national number field.
String cleanNationalPhoneDigits(String? value) {
  var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0') && digits.length > 1) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Normalizes a phone number to backend format: 251 + 9 digits (Ethiopian).
/// Use for all API calls that send a phone number (register, verification, profile).
///
/// Accepts: 0912345678, 912345678, +251912345678, 251912345678, etc.
/// Returns: "251" + exactly 9 digits (e.g. 251912345678), or original if empty.
String normalizePhoneToBackend(String? phone) {
  if (phone == null || phone.trim().isEmpty) return phone?.trim() ?? '';
  final String digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return phone.trim();

  // Already 251 + 9 digits
  if (digits.startsWith('251') && digits.length >= 12) {
    return digits.substring(0, 12);
  }
  if (digits.startsWith('251') && digits.length > 3) {
    final rest = digits.substring(3);
    return '251${rest.padRight(9, '0').substring(0, 9)}';
  }

  // Leading 0 + 9 digits (e.g. 0912345678)
  if (digits.startsWith('0') && digits.length >= 10) {
    return '251${digits.substring(1, 10)}';
  }

  // Exactly 9 digits (e.g. 912345678)
  if (digits.length == 9) {
    return '251$digits';
  }

  // More than 9 digits: take last 9 (e.g. 25191234567899 -> 251912345678)
  if (digits.length > 9) {
    return '251${digits.substring(digits.length - 9)}';
  }

  // Fewer than 9: pad with leading zeros to get 9 digits
  return '251${digits.padLeft(9, '0')}';
}
