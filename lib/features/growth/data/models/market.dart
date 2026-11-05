import 'growth_json.dart';

/// One city/market from `GET /api/markets` (Phase 3 §0).
///
/// `addis_ababa` is the implicit default everywhere: a missing market means
/// Addis Ababa / ETB, so the app behaves exactly as before Phase 3.
class Market {
  final String code;
  final String name;
  final String currency;
  final String? timezone;
  final bool isActive;
  final double? defaultLat;
  final double? defaultLng;
  final String? phonePrefix;
  final List<String> paymentMethods;

  /// Phase 6 phone plan (`settings.phone`): national number length and
  /// mobile prefixes. `GET /api/markets` does not send it today, so these
  /// stay empty and `GiftPhonePlan` falls back to known plans.
  final int? phoneNationalLength;
  final List<String> phoneMobilePrefixes;

  const Market({
    required this.code,
    required this.name,
    required this.currency,
    this.timezone,
    this.isActive = true,
    this.defaultLat,
    this.defaultLng,
    this.phonePrefix,
    this.paymentMethods = const [],
    this.phoneNationalLength,
    this.phoneMobilePrefixes = const [],
  });

  static const String defaultCode = 'addis_ababa';
  static const String hargeisaCode = 'hargeisa';

  bool get isDefault => code == defaultCode;

  factory Market.fromJson(Map<String, dynamic> json) {
    final code = (growthString(json['code']) ?? '').toLowerCase();
    final settings = growthMap(json['settings']);
    final phone = growthMap(json['phone']) ?? growthMap(settings?['phone']);
    return Market(
      code: code,
      name: growthString(json['name']) ?? code,
      currency: (growthString(json['currency']) ?? 'ETB').toUpperCase(),
      timezone: growthString(json['timezone']),
      isActive: growthBool(json['is_active'], true),
      defaultLat: growthDoubleOrNull(json['default_lat']),
      defaultLng: growthDoubleOrNull(json['default_lng']),
      phonePrefix: growthString(json['phone_prefix']),
      paymentMethods: growthList(json['payment_methods'])
          .map(growthString)
          .whereType<String>()
          .toList(),
      phoneNationalLength: growthIntOrNull(phone?['national_length']),
      phoneMobilePrefixes: growthList(phone?['mobile_prefixes'])
          .map(growthString)
          .whereType<String>()
          .toList(),
    );
  }

  /// Parses `{success, data: [...]}` (or `data: {markets: [...]}`); only
  /// active markets with a code are kept. Empty on any bad payload.
  static List<Market> listFromResponseBody(dynamic body) {
    final list = growthEnvelopeList(body, key: 'markets');
    if (list == null) return const [];
    final seen = <String>{};
    final out = <Market>[];
    for (final raw in list) {
      final map = growthMap(raw);
      if (map == null) continue;
      final m = Market.fromJson(map);
      if (m.code.isEmpty || !m.isActive || !seen.add(m.code)) continue;
      out.add(m);
    }
    return out;
  }

  /// Parses `GET /api/markets/resolve`: `data` is a market object, `null`,
  /// or `{market: {...}|null}`. Returns `null` when no market matched.
  static Market? tryParseResolveBody(dynamic body) {
    final data = growthEnvelopeData(body);
    if (data == null) return null;
    final nested = growthMap(data['market']);
    final map = nested ?? (data.containsKey('code') ? data : null);
    if (map == null) return null;
    final m = Market.fromJson(map);
    if (m.code.isEmpty || !m.isActive) return null;
    return m;
  }
}
