import '../../../../core/api/api_constants.dart';
import '../../../../core/api/api_service.dart';
import '../../utils/payment_methods_parser.dart';

class PaymentDataProvider {
  final ApiService apiService;

  PaymentDataProvider({required this.apiService});

  /// GET /api/payment-methods - fetches available payment methods.
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final response = await apiService.get(
      '${ApiConstants.baseUrl}${ApiConstants.paymentMethods}',
    );
    final data = response.data;

    if (data == null || data is! Map) {
      return [];
    }

    final map = Map<String, dynamic>.from(data);
    return parsePaymentMethodsList(map['data']);
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String paymentMethodCode,
    required int orderId,
    required double amount,
    required String currency,
    String type = 'order',
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.paymentsInitiate}',
        data: {
          'payment_method_code': paymentMethodCode,
          'order_id': orderId,
          'amount': amount,
          'type': type,
          'currency': currency,
          'payment_details': paymentDetails ?? {},
        },
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'success': false, 'message': 'Invalid payment response'};
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
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
