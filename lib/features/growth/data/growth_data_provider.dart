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

  Future<Map<String, dynamic>> getConfig() =>
      _wrap(() => apiService.get(_url(ApiConstants.growthConfig)));

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
}
