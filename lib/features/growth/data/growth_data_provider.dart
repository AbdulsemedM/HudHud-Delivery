import 'package:dio/dio.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

/// Raw HTTP calls for Phase 2 growth endpoints.
///
/// Returns the `{statusCode, data, errorMessage, code}` map shape used by the
/// other data providers in this app; never throws.
class GrowthDataProvider {
  final ApiService apiService;

  GrowthDataProvider({required this.apiService});

  Future<Map<String, dynamic>> _wrap(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
        'code': null,
      };
    } on ApiException catch (e) {
      final data = e.data;
      String? code = e.code;
      if (code == null && data is Map) {
        final raw = data['code']?.toString();
        if (raw != null && raw.isNotEmpty) code = raw;
      }
      String message = e.message;
      if (data is Map && data['message'] is String) {
        final m = (data['message'] as String).trim();
        if (m.isNotEmpty) message = m;
      }
      return {
        'statusCode': e.statusCode,
        'data': data,
        'errorMessage': message,
        'code': code,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': e.toString(),
        'code': null,
      };
    }
  }

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  /// [market] (Phase 3) adds `?market=`; omitted when null/empty so the
  /// request is byte-for-byte the Phase 2 one.
  Future<Map<String, dynamic>> getConfig({String? market}) => _wrap(
        () => apiService.get(
          _url(ApiConstants.growthConfig),
          queryParameters:
              market == null || market.isEmpty ? null : {'market': market},
        ),
      );

  Future<Map<String, dynamic>> getHomeFeed({String? serviceType}) => _wrap(
        () => apiService.get(
          _url(ApiConstants.homeFeed),
          queryParameters: serviceType == null || serviceType.isEmpty
              ? null
              : {'service_type': serviceType},
        ),
      );

  Future<Map<String, dynamic>> postCheckoutQuote(Map<String, dynamic> body) =>
      _wrap(
        () => apiService.post(
          _url(ApiConstants.customerCheckoutQuote),
          data: body,
        ),
      );

  Future<Map<String, dynamic>> postPromoPreview({
    required String code,
    required double subtotal,
    int? vendorId,
    String? serviceType,
  }) =>
      _wrap(
        () => apiService.post(
          _url(ApiConstants.customerPromoPreview),
          data: {
            'code': code,
            'subtotal': subtotal,
            if (vendorId != null && vendorId > 0) 'vendor_id': vendorId,
            if (serviceType != null && serviceType.isNotEmpty)
              'service_type': serviceType,
          },
        ),
      );

  Future<Map<String, dynamic>> getReferralSummary() =>
      _wrap(() => apiService.get(_url(ApiConstants.customerReferralSummary)));

  Future<Map<String, dynamic>> getRewardsSummary() =>
      _wrap(() => apiService.get(_url(ApiConstants.customerRewardsSummary)));

  Future<Map<String, dynamic>> getReorderSuggestions() => _wrap(
        () => apiService.get(_url(ApiConstants.customerReorderSuggestions)),
      );

  Future<Map<String, dynamic>> postReorder(int orderId) => _wrap(
        () => apiService.post(
          _url(
            ApiConstants.replacePathParams(
              ApiConstants.customerOrderReorder,
              {'id': orderId},
            ),
          ),
        ),
      );

  // ── Phase 3 ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMarkets() =>
      _wrap(() => apiService.get(_url(ApiConstants.markets)));

  Future<Map<String, dynamic>> getResolveMarket({
    required double lat,
    required double lng,
  }) =>
      _wrap(
        () => apiService.get(
          _url(ApiConstants.marketsResolve),
          queryParameters: {'lat': lat, 'lng': lng},
        ),
      );

  Future<Map<String, dynamic>> putCustomerMarket(String marketCode) => _wrap(
        () => apiService.put(
          _url(ApiConstants.customerMarket),
          data: {'market_code': marketCode},
        ),
      );

  Future<Map<String, dynamic>> getPlus() =>
      _wrap(() => apiService.get(_url(ApiConstants.customerPlus)));

  Future<Map<String, dynamic>> postPlusSubscribe() =>
      _wrap(() => apiService.post(_url(ApiConstants.customerPlusSubscribe)));

  Future<Map<String, dynamic>> postPlusCancel() =>
      _wrap(() => apiService.post(_url(ApiConstants.customerPlusCancel)));

  Future<Map<String, dynamic>> postPlusResume() =>
      _wrap(() => apiService.post(_url(ApiConstants.customerPlusResume)));

  Future<Map<String, dynamic>> getSponsored({
    required String placement,
    String? query,
    double? lat,
    double? lng,
  }) =>
      _wrap(
        () => apiService.get(
          _url(ApiConstants.adsSponsored),
          queryParameters: {
            'placement': placement,
            if (query != null && query.isNotEmpty) 'q': query,
            if (lat != null && lng != null) 'lat': lat,
            if (lat != null && lng != null) 'lng': lng,
          },
        ),
      );

  Future<Map<String, dynamic>> postAdClick({
    required int adId,
    required String impressionToken,
    required String placement,
  }) =>
      _wrap(
        () => apiService.post(
          _url(ApiConstants.adsClick),
          data: {
            'ad_id': adId,
            'impression_token': impressionToken,
            'placement': placement,
          },
        ),
      );
}
