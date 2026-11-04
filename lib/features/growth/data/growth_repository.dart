import 'package:hudhud_delivery/core/api/api_service.dart';

import 'growth_data_provider.dart';
import 'models/checkout_quote.dart';
import 'models/checkout_quote_request.dart';
import 'models/growth_config.dart';
import 'models/growth_json.dart';
import 'models/home_feed.dart';
import 'models/referral_summary.dart';
import 'models/reorder.dart';
import 'models/rewards_summary.dart';

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
  Future<GrowthConfig> fetchConfig() async {
    final r = await dataProvider.getConfig();
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
}
