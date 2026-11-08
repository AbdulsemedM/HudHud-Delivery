import '../growth/data/models/market.dart';

/// Recipient mobile-number rules for a market (Phase 6 diaspora gifting).
///
/// Mirrors the API's `App\Support\MarketPhone`: the market's `phone_prefix`
/// gives the country code, `settings.phone` gives the national number length
/// and mobile prefixes. `GET /api/markets` does not publish `settings.phone`,
/// so Hargeisa falls back to the plan the API ships in `config/hargeisa.php`
/// (9 digits, 63 / 65 / 66) and any other market to a 7–10 digit check.
/// The server re-validates against the vendor's market either way.
class GiftPhonePlan {
  const GiftPhonePlan({
    required this.countryCode,
    this.nationalLength,
    this.mobilePrefixes = const [],
  });

  /// Digits only, without `+` (e.g. `252`).
  final String countryCode;
  final int? nationalLength;
  final List<String> mobilePrefixes;

  static const String fallbackCountryCode = '252';

  /// Somaliland numbering used by the API when a Hargeisa market row has no
  /// `settings.phone` (63 = Telesom, 65/66 = Somtel).
  static const GiftPhonePlan hargeisa = GiftPhonePlan(
    countryCode: '252',
    nationalLength: 9,
    mobilePrefixes: ['63', '65', '66'],
  );

  String get dialPrefix => '+$countryCode';

  /// Example national number for the input hint (`63 1234567`).
  String get exampleNational {
    final length = nationalLength ?? 9;
    final lead = mobilePrefixes.isNotEmpty ? mobilePrefixes.first : '';
    final rest = length - lead.length;
    if (rest <= 0) return lead;
    final digits = List.generate(rest, (i) => '${(i + 1) % 10}').join();
    return lead.isEmpty ? digits : '$lead $digits';
  }

  factory GiftPhonePlan.forMarket(Market? market) {
    final cc = (market?.phonePrefix ?? '').replaceAll(RegExp(r'\D'), '');
    final countryCode = cc.isNotEmpty
        ? cc
        : (market?.code == Market.hargeisaCode ? '252' : fallbackCountryCode);
    if (market != null &&
        (market.phoneNationalLength != null ||
            market.phoneMobilePrefixes.isNotEmpty)) {
      return GiftPhonePlan(
        countryCode: countryCode,
        nationalLength: market.phoneNationalLength,
        mobilePrefixes: market.phoneMobilePrefixes,
      );
    }
    if (market == null || market.code == Market.hargeisaCode) {
      return GiftPhonePlan(
        countryCode: countryCode,
        nationalLength: hargeisa.nationalLength,
        mobilePrefixes: hargeisa.mobilePrefixes,
      );
    }
    return GiftPhonePlan(countryCode: countryCode);
  }

  /// Returns `+<country><national>` (e.g. `+252634123456`) or null when the
  /// number does not fit the plan. Accepts `063…`, `63…`, `252…`, `+252…`
  /// and `00252…`, with spaces or dashes.
  String? normalize(String? raw) {
    var digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);

    String national;
    if (digits.startsWith(countryCode) &&
        digits.length > countryCode.length + 5) {
      national = digits.substring(countryCode.length);
    } else if (digits.startsWith('0')) {
      national = digits.substring(1);
    } else {
      national = digits;
    }

    final length = nationalLength;
    if (length != null) {
      if (national.length != length) return null;
    } else if (national.length < 7 || national.length > 10) {
      return null;
    }
    if (mobilePrefixes.isNotEmpty &&
        !mobilePrefixes.any((prefix) => national.startsWith(prefix))) {
      return null;
    }
    return '+$countryCode$national';
  }

  bool isValid(String? raw) => normalize(raw) != null;
}
