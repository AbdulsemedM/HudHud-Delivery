import 'package:hudhud_delivery/core/api/api_service.dart';

import 'growth_data_provider.dart';
import 'models/checkout_quote.dart';
import 'models/checkout_quote_request.dart';
import 'models/growth_config.dart';
import 'models/growth_json.dart';
import 'models/home_feed.dart';
import 'models/market.dart';
import 'models/plus.dart';
import 'models/referral_summary.dart';
import 'models/reorder.dart';
import 'models/rewards_summary.dart';
import 'models/sponsored.dart';

/// Error surfaced by growth calls; [message] is the server's text when given.
class GrowthException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const GrowthException(this.message, {this.statusCode, this.code});

  bool get isFeatureDisabled => code == 'FEATURE_DISABLED';

  @override
  String toString() => message;
}

/// Result of a promo-code preview.
class PromoPreviewResult {
  final bool valid;
  final String code;
  final String? message;
  final double discountAmount;
  final bool freeDelivery;

  const PromoPreviewResult({
    required this.valid,
    required this.code,
    this.message,
    this.discountAmount = 0,
    this.freeDelivery = false,
  });
}

/// Outcome of `PUT /api/customer/market`.
class MarketChangeResult {
  final bool ok;
  final String? code;
  final String? message;

  const MarketChangeResult({required this.ok, this.code, this.message});

  bool get isBlocked => code == 'MARKET_CHANGE_BLOCKED';
}

/// Outcome of a Plus subscribe / cancel / resume call.
class PlusActionResult {
  final bool ok;
  final String? code;
  final String? message;
  final PlusInsufficientFunds? insufficientFunds;

  const PlusActionResult({
    required this.ok,
    this.code,
    this.message,
    this.insufficientFunds,
  });

  bool get isInsufficientFunds => code == 'INSUFFICIENT_FUNDS';
}

/// Phase 2 growth API. All reads return safe fallbacks rather than throwing
/// unless documented otherwise.
class GrowthRepository {
  final GrowthDataProvider dataProvider;

  GrowthRepository({required this.dataProvider});

  factory GrowthRepository.create() => GrowthRepository(
        dataProvider: GrowthDataProvider(apiService: ApiService.instance),
      );

  bool _ok(Map<String, dynamic> r) {
    final s = r['statusCode'];
    return s == 200 || s == 201;
  }

  /// Never throws. Returns [GrowthConfig.disabled] on any failure.
  Future<GrowthConfig> fetchConfig({String? market}) async {
    final r = await dataProvider.getConfig(market: market);
    if (!_ok(r)) return GrowthConfig.disabled;
    return GrowthConfig.fromResponseBody(r['data']);
  }

  /// Never throws. Returns [HomeFeed.empty] on failure.
  Future<HomeFeed> fetchHomeFeed({String? serviceType}) async {
    final r = await dataProvider.getHomeFeed(serviceType: serviceType);
    if (!_ok(r)) return HomeFeed.empty;
    final data = growthEnvelopeData(r['data']);
    if (data == null) return HomeFeed.empty;
    try {
      return HomeFeed.fromJson(data);
    } catch (_) {
      return HomeFeed.empty;
    }
  }

  /// Returns `null` on any failure so checkout can fall back to the
  /// client-side display.
  Future<CheckoutQuote?> fetchCheckoutQuote(CheckoutQuoteRequest request) async {
    final r = await dataProvider.postCheckoutQuote(request.toJson());
    if (!_ok(r)) return null;
    return CheckoutQuote.tryParseResponseBody(r['data']);
  }

  /// Never throws; invalid codes return `valid: false` with the server reason.
  Future<PromoPreviewResult> previewPromo({
    required String code,
    required double subtotal,
    int? vendorId,
    String serviceType = 'restaurant',
  }) async {
    final r = await dataProvider.postPromoPreview(
      code: code,
      subtotal: subtotal,
      vendorId: vendorId,
      serviceType: serviceType,
    );
    final body = growthMap(r['data']);
    final serverMessage = growthString(body?['message']) ??
        growthString(r['errorMessage']);
    if (_ok(r) && body != null && body['success'] == true) {
      final data = growthMap(body['data']) ?? const {};
      return PromoPreviewResult(
        valid: true,
        code: growthString(data['code']) ?? code,
        message: serverMessage,
        discountAmount: growthDouble(data['discount_amount']),
        freeDelivery: growthBool(data['free_delivery']),
      );
    }
    return PromoPreviewResult(valid: false, code: code, message: serverMessage);
  }

  /// Throws [GrowthException] on failure (caller decides UI).
  Future<ReferralSummary> fetchReferralSummary() async {
    final r = await dataProvider.getReferralSummary();
    final data = _ok(r) ? growthEnvelopeData(r['data']) : null;
    if (data == null) {
      throw GrowthException(
        growthString(r['errorMessage']) ?? 'Unable to load referral details',
        statusCode: r['statusCode'] as int?,
        code: r['code'] as String?,
      );
    }
    return ReferralSummary.fromJson(data);
  }

  /// Throws [GrowthException] on failure.
  Future<RewardsSummary> fetchRewardsSummary() async {
    final r = await dataProvider.getRewardsSummary();
    final data = _ok(r) ? growthEnvelopeData(r['data']) : null;
    if (data == null) {
      throw GrowthException(
        growthString(r['errorMessage']) ?? 'Unable to load rewards',
        statusCode: r['statusCode'] as int?,
        code: r['code'] as String?,
      );
    }
    return RewardsSummary.fromJson(data);
  }

  /// Never throws; empty on failure.
  Future<List<ReorderSuggestion>> fetchReorderSuggestions() async {
    final r = await dataProvider.getReorderSuggestions();
    if (!_ok(r)) return const [];
    try {
      return ReorderSuggestion.listFromResponseBody(r['data']);
    } catch (_) {
      return const [];
    }
  }

  /// Throws [GrowthException] on failure.
  Future<ReorderResult> reorder(int orderId) async {
    final r = await dataProvider.postReorder(orderId);
    final result = _ok(r) ? ReorderResult.tryParseResponseBody(r['data']) : null;
    if (result == null) {
      throw GrowthException(
        growthString(r['errorMessage']) ?? 'Unable to reorder',
        statusCode: r['statusCode'] as int?,
        code: r['code'] as String?,
      );
    }
    return result;
  }

  // ── Phase 3: markets ───────────────────────────────────────────────────

  /// Never throws; empty on failure (pre-Phase-3 backend → single market).
  Future<List<Market>> fetchMarkets() async {
    final r = await dataProvider.getMarkets();
    if (!_ok(r)) return const [];
    try {
      return Market.listFromResponseBody(r['data']);
    } catch (_) {
      return const [];
    }
  }

  /// Never throws; `null` when no market is within range or on failure.
  Future<Market?> resolveMarket({
    required double lat,
    required double lng,
  }) async {
    final r = await dataProvider.getResolveMarket(lat: lat, lng: lng);
    if (!_ok(r)) return null;
    try {
      return Market.tryParseResolveBody(r['data']);
    } catch (_) {
      return null;
    }
  }

  /// Never throws.
  Future<MarketChangeResult> updateCustomerMarket(String marketCode) async {
    final r = await dataProvider.putCustomerMarket(marketCode);
    final body = growthMap(r['data']);
    if (_ok(r) && (body == null || body['success'] != false)) {
      return const MarketChangeResult(ok: true);
    }
    return MarketChangeResult(
      ok: false,
      code: growthString(r['code']) ?? growthString(body?['code']),
      message: growthString(r['errorMessage']) ??
          growthString(body?['message']),
    );
  }

  // ── Phase 3: HudHud Plus ───────────────────────────────────────────────

  /// Never throws. [PlusStatus.disabled] on failure, so Plus stays hidden.
  /// Customer-only endpoint: callers must skip it for guests.
  Future<PlusStatus> fetchPlus() async {
    final r = await dataProvider.getPlus();
    if (!_ok(r)) return PlusStatus.disabled;
    return PlusStatus.fromResponseBody(r['data']);
  }

  Future<PlusActionResult> subscribePlus() =>
      _plusAction(dataProvider.postPlusSubscribe);

  Future<PlusActionResult> cancelPlus() =>
      _plusAction(dataProvider.postPlusCancel);

  Future<PlusActionResult> resumePlus() =>
      _plusAction(dataProvider.postPlusResume);

  Future<PlusActionResult> _plusAction(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    final r = await call();
    final body = growthMap(r['data']);
    if (_ok(r) && (body == null || body['success'] != false)) {
      return const PlusActionResult(ok: true);
    }
    final code = growthString(r['code']) ?? growthString(body?['code']);
    return PlusActionResult(
      ok: false,
      code: code,
      message: growthString(r['errorMessage']) ??
          growthString(body?['message']),
      insufficientFunds: code == 'INSUFFICIENT_FUNDS'
          ? PlusInsufficientFunds.tryParse(body)
          : null,
    );
  }

  // ── Phase 3: sponsored listings ────────────────────────────────────────

  /// Set after a 404 so an older backend is not asked again this session.
  static bool _adsEndpointMissing = false;

  /// Never throws; empty on failure or when ads are off.
  Future<List<SponsoredItem>> fetchSponsored({
    required String placement,
    String? query,
    double? lat,
    double? lng,
  }) async {
    if (_adsEndpointMissing) return const [];
    final r = await dataProvider.getSponsored(
      placement: placement,
      query: query,
      lat: lat,
      lng: lng,
    );
    if (r['statusCode'] == 404) _adsEndpointMissing = true;
    if (!_ok(r)) return const [];
    try {
      return SponsoredItem.listFromResponseBody(
        r['data'],
        placement: placement,
      );
    } catch (_) {
      return const [];
    }
  }

  /// Fire-and-forget click report. Never throws; callers must not await it
  /// before navigating.
  Future<void> trackAdClick(SponsoredItem item) async {
    if (item.adId <= 0) return;
    try {
      await dataProvider.postAdClick(
        adId: item.adId,
        impressionToken: item.impressionToken,
        placement: item.placement,
      );
    } catch (_) {}
  }
}
