import 'growth_json.dart';

/// Feature flags from `GET /api/growth/config`.
///
/// Every growth feature is OFF unless the server says otherwise. When the
/// config call fails, [GrowthConfig.disabled] is used so the app looks and
/// behaves exactly like it did before Phase 2.
class GrowthConfig {
  /// True only when the config was parsed from a successful server response.
  final bool loaded;
  final String currency;
  final bool promoCodesEnabled;
  final bool freeDeliveryEnabled;
  final double freeDeliveryThreshold;
  final bool rewardsEnabled;
  final int rewardsRedeemPoints;
  final double rewardsRedeemValue;
  final int rewardsMinRedeemPoints;
  final bool referralEnabled;
  final double referralRewardAmount;
  final int referralMaxPerUser;
  final bool onTimeEnabled;
  final double onTimeCreditAmount;
  final int onTimeGraceMinutes;
  final bool homeFeedEnabled;

  /// Reorder has no admin setting in the contract. It is available once the
  /// Phase 2 backend is reachable (config [loaded]); an explicit
  /// `reorder.enabled` key from the server wins if it is ever added.
  final bool reorderEnabled;

  /// Phase 3: `"market":{"code","currency"}` when the server resolved one
  /// (from `?market=` or the signed-in user). Null otherwise.
  final String? marketCode;
  final String? marketCurrency;

  /// Phase 3 sponsored listings. There is no config flag in the contract;
  /// an explicit `ads.enabled` key wins if the server ever sends one.
  /// Sponsored items still only appear when the server returns them.
  final bool adsEnabled;

  /// Phase 6 diaspora gifting. The server keeps `gifting.enabled` in its
  /// launch settings and does not publish it in this config today, so this
  /// is null ("not said") unless a `gifting: {enabled}` block is ever sent.
  final bool? giftingEnabled;

  const GrowthConfig({
    required this.loaded,
    this.currency = 'ETB',
    this.promoCodesEnabled = false,
    this.freeDeliveryEnabled = false,
    this.freeDeliveryThreshold = 0,
    this.rewardsEnabled = false,
    this.rewardsRedeemPoints = 100,
    this.rewardsRedeemValue = 0,
    this.rewardsMinRedeemPoints = 100,
    this.referralEnabled = false,
    this.referralRewardAmount = 0,
    this.referralMaxPerUser = 0,
    this.onTimeEnabled = false,
    this.onTimeCreditAmount = 0,
    this.onTimeGraceMinutes = 0,
    this.homeFeedEnabled = false,
    this.reorderEnabled = false,
    this.marketCode,
    this.marketCurrency,
    this.adsEnabled = false,
    this.giftingEnabled,
  });

  static const GrowthConfig disabled = GrowthConfig(loaded: false);

  /// Whether checkout should ask the server for a priced quote.
  bool get checkoutQuoteEnabled =>
      loaded && (promoCodesEnabled || freeDeliveryEnabled || rewardsEnabled);

  /// Parses the `data` object of the config response.
  factory GrowthConfig.fromJson(Map<String, dynamic> json) {
    final promo = growthMap(json['promo_codes']) ?? const {};
    final free = growthMap(json['free_delivery']) ?? const {};
    final rewards = growthMap(json['rewards']) ?? const {};
    final referral = growthMap(json['referral']) ?? const {};
    final onTime = growthMap(json['on_time']) ?? const {};
    final feed = growthMap(json['home_feed']) ?? const {};
    final reorder = growthMap(json['reorder']);
    final market = growthMap(json['market']);
    final ads = growthMap(json['ads']);
    final gifting = growthMap(json['gifting']);

    final redeemPoints = growthInt(rewards['redeem_points'], 100);
    return GrowthConfig(
      loaded: true,
      currency: growthString(json['currency']) ?? 'ETB',
      promoCodesEnabled: growthBool(promo['enabled']),
      freeDeliveryEnabled: growthBool(free['enabled']),
      freeDeliveryThreshold: growthDouble(free['threshold']),
      rewardsEnabled: growthBool(rewards['enabled']),
      rewardsRedeemPoints: redeemPoints > 0 ? redeemPoints : 100,
      rewardsRedeemValue: growthDouble(rewards['redeem_value']),
      rewardsMinRedeemPoints: growthInt(rewards['min_redeem_points'], 100),
      referralEnabled: growthBool(referral['enabled']),
      referralRewardAmount: growthDouble(referral['reward_amount']),
      referralMaxPerUser: growthInt(referral['max_per_user']),
      onTimeEnabled: growthBool(onTime['enabled']),
      onTimeCreditAmount: growthDouble(onTime['credit_amount']),
      onTimeGraceMinutes: growthInt(onTime['grace_minutes']),
      homeFeedEnabled: growthBool(feed['enabled']),
      reorderEnabled:
          reorder == null ? true : growthBool(reorder['enabled'], true),
      marketCode: growthString(market?['code'])?.toLowerCase(),
      marketCurrency: growthString(market?['currency'])?.toUpperCase(),
      adsEnabled: ads == null ? true : growthBool(ads['enabled'], true),
      giftingEnabled: gifting == null || !gifting.containsKey('enabled')
          ? null
          : growthBool(gifting['enabled']),
    );
  }

  /// Parses a full `{success, data}` response body; returns [disabled] when
  /// the body is not a successful envelope.
  static GrowthConfig fromResponseBody(dynamic body) {
    final data = growthEnvelopeData(body);
    if (data == null) return disabled;
    return GrowthConfig.fromJson(data);
  }
}
