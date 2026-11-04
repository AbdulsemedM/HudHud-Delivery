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

/// Upper-cased ISO currency code, or `null` when blank.
String? normalizeCurrencyCode(String? currency) {
  final c = currency?.trim().toUpperCase();
  if (c == null || c.isEmpty) return null;
  return c;
}

/// True for ETB or an unknown (blank) currency — the pre-Phase-3 default.
bool isEtbCurrency(String? currency) {
  final c = normalizeCurrencyCode(currency);
  return c == null || c == 'ETB';
}

/// Formats [amount] in [currency] (Phase 3 multi-market).
///
/// ETB / blank produces exactly [formatEtbAmount]'s output, so existing
/// Addis Ababa screens render unchanged. Other currencies use the code as a
/// prefix: `USD 12.50`.
String formatMoneyAmount(
  num amount, {
  String? currency,
  int fractionDigits = 2,
}) {
  if (isEtbCurrency(currency)) {
    return formatEtbAmount(amount, fractionDigits: fractionDigits);
  }
  return '${normalizeCurrencyCode(currency)} ${amount.toStringAsFixed(fractionDigits)}';
}
