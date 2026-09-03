import 'package:dio/dio.dart';

import '../../../../core/api/api_constants.dart';
import '../../../../core/api/api_service.dart';
import '../../utils/payment_methods_parser.dart';

class PaymentDataProvider {
  final ApiService apiService;

  PaymentDataProvider({required this.apiService});

  /// GET /api/payment-methods (or /payments/methods) — optional [type] filter.
  Future<List<Map<String, dynamic>>> getPaymentMethods({String? type}) async {
    final query = <String, dynamic>{};
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }

    for (final path in [
      ApiConstants.paymentMethods,
      ApiConstants.paymentsMethods,
    ]) {
      try {
        final response = await apiService.get(
          '${ApiConstants.baseUrl}$path',
          queryParameters: query.isEmpty ? null : query,
        );
        final data = response.data;
        if (data == null || data is! Map) continue;
        final map = Map<String, dynamic>.from(data);
        final methods = parsePaymentMethodsList(map['data']);
        if (methods.isNotEmpty || type == null) return methods;
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String paymentMethodCode,
    required String type,
    required double amount,
    String? currency,
    int? orderId,
    int? rideId,
    int? serviceRequestId,
    int? packageDeliveryId,
    Map<String, dynamic>? paymentDetails,
    bool? isSandbox,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'payment_method_code': paymentMethodCode,
      'type': type,
      'amount': amount,
      'payment_details': paymentDetails ?? {},
    };
    if (currency != null && currency.isNotEmpty) {
      body['currency'] = currency;
    }
    if (orderId != null) body['order_id'] = orderId;
    if (rideId != null) body['ride_id'] = rideId;
    if (serviceRequestId != null) {
      body['service_request_id'] = serviceRequestId;
    }
    if (packageDeliveryId != null) {
      body['package_delivery_id'] = packageDeliveryId;
    }
    if (isSandbox != null) body['is_sandbox'] = isSandbox;

    final headers = <String, dynamic>{};
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    // Provider gateways (eBirr/Waafi) often exceed the default 30s receive timeout.
    // Rethrow ApiException / Dio errors so callers can branch (422, timeouts).
    final response = await apiService.post(
      '${ApiConstants.baseUrl}${ApiConstants.paymentsInitiate}',
      data: body,
      options: Options(
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 3),
        headers: headers.isEmpty ? null : headers,
      ),
    );
    final data = response.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'success': false, 'message': 'Invalid payment response'};
  }

  Future<Map<String, dynamic>> getPaymentStatus(int paymentId) async {
    try {
      final path = ApiConstants.paymentsStatus.replaceAll(
        '{id}',
        paymentId.toString(),
      );
      final response = await apiService.get(
        '${ApiConstants.baseUrl}$path',
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'success': false, 'message': 'Invalid payment status response'};
    } catch (e) {
      throw Exception('Failed to fetch payment status: $e');
    }
  }

  /// POST /api/payments/service/{wallet|waafipay|edahab|sahay|ebirr}
  Future<Map<String, dynamic>> processServicePayment({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}$path',
        data: body,
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'success': false, 'message': 'Invalid service payment response'};
    } catch (e) {
      throw Exception('Failed to process service payment: $e');
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required double amount,
    required String orderId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.payments.replaceFirst('/', '')}/process',
        data: {
          'payment_method': paymentMethod,
          'amount': amount,
          'order_id': orderId,
          'payment_details': paymentDetails ?? {},
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<Map<String, dynamic>> validatePayment({
    required String transactionId,
    required String paymentMethod,
  }) async {
    try {
      final response = await apiService.post(
        '/payments/validate',
        data: {
          'transaction_id': transactionId,
          'payment_method': paymentMethod,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to validate payment: $e');
    }
  }
}
