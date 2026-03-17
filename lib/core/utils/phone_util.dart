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
