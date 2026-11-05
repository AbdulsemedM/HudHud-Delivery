/// Display helpers for Ethiopian Birr — never use `$` for ETB.
///
/// US dollar amounts (Hargeisa market) go through [formatMoneyAmount] and
/// do use `$`.
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

/// Display prefix for [currency]: `$` for US dollars (Hargeisa), otherwise
/// the ISO code and a space (`ETB `, `KES `). Blank means ETB.
String moneyPrefix(String? currency) {
  final code = normalizeCurrencyCode(currency) ?? 'ETB';
  if (code == 'USD') return r'$';
  return '$code ';
}

/// Formats [amount] in [currency] (Phase 3 multi-market).
///
/// ETB / blank produces exactly [formatEtbAmount]'s output, so existing
/// Addis Ababa screens render unchanged. US dollars use the sign (`$12.50`,
/// `-$3.00`); other currencies use the code as a prefix: `KES 12.50`.
String formatMoneyAmount(
  num amount, {
  String? currency,
  int fractionDigits = 2,
}) {
  if (isEtbCurrency(currency)) {
    return formatEtbAmount(amount, fractionDigits: fractionDigits);
  }
  final prefix = moneyPrefix(currency);
  if (amount < 0 && prefix == r'$') {
    return '-$prefix${(-amount).toStringAsFixed(fractionDigits)}';
  }
  return '$prefix${amount.toStringAsFixed(fractionDigits)}';
}

/// Like [formatEtbPriceString] but in [currency]: ETB / blank output is
/// unchanged; for other currencies any `$` / code / `Br` the API put in the
/// string is replaced by [moneyPrefix] (`$12.50`).
String formatMoneyPriceString(
  String? raw, {
  String? currency,
}) {
  if (isEtbCurrency(currency)) return formatEtbPriceString(raw);
  final cleaned = (raw ?? '')
      .trim()
      .replaceAll('\$', '')
      .replaceAll(
        RegExp(r'^(USD|ETB|Br|Birr)\s*', caseSensitive: false),
        '',
      )
      .trim();
  if (cleaned.isEmpty) return formatMoneyAmount(0, currency: currency);
  final parsed = double.tryParse(cleaned.replaceAll(',', ''));
  if (parsed != null) return formatMoneyAmount(parsed, currency: currency);
  return '${moneyPrefix(currency)}$cleaned';
}
