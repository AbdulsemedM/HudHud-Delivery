/// Display helpers for Ethiopian Birr — never use `$`.
///
/// - Short code: `ETB 12.50`
/// - Compact sign: `Br 12.50`
String formatEtbAmount(
  num amount, {
  int fractionDigits = 2,
  bool compactSign = false,
}) {
  final value = amount.toStringAsFixed(fractionDigits);
  return compactSign ? 'Br $value' : 'ETB $value';
}

/// Formats a raw price string (may include `$`, `ETB`, or `Br` from the API).
String formatEtbPriceString(
  String? raw, {
  bool compactSign = false,
}) {
  if (raw == null) return compactSign ? 'Br 0.00' : 'ETB 0.00';
  var cleaned = raw.trim();
  if (cleaned.isEmpty) return compactSign ? 'Br 0.00' : 'ETB 0.00';

  cleaned = cleaned
      .replaceAll('\$', '')
      .replaceAll(RegExp(r'^(ETB|etb|Br|br|Birr|birr)\s*', caseSensitive: false), '')
      .trim();

  final parsed = double.tryParse(cleaned);
  if (parsed != null) {
    return formatEtbAmount(parsed, compactSign: compactSign);
  }
  return compactSign ? 'Br $cleaned' : 'ETB $cleaned';
}
