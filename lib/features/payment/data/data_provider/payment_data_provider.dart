import '../../../../core/api/api_constants.dart';
import '../../../../core/api/api_service.dart';

class PaymentDataProvider {
  final ApiService apiService;

  PaymentDataProvider({required this.apiService});

  /// GET /api/payment-methods - fetches available payment methods.
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final response = await apiService.get(
      '${ApiConstants.baseUrl}${ApiConstants.paymentMethods}',
    );
    final data = response.data;

    if (data == null || data is! Map<String, dynamic>) {
      return [];
    }

    final list = data['data'];
    if (list == null || list is! List) {
      return [];
    }

    final List<Map<String, dynamic>> methods = [];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final isActive = item['is_active'] == true;
        final code = item['code']?.toString();
        final name = item['name']?.toString() ?? code ?? 'Unknown';
        final description = item['description']?.toString() ?? 'Pay with $name';
        final sortOrder =
            int.tryParse(item['sort_order']?.toString() ?? '0') ?? 0;

        if (code != null && code.isNotEmpty) {
          methods.add({
            'id': code,
            'name': name,
            'description': description,
            'icon': item['icon'],
            'enabled': isActive,
            '_sortOrder': sortOrder,
          });
        }
      }
    }

    methods.sort(
        (a, b) => (a['_sortOrder'] as int).compareTo(b['_sortOrder'] as int));
    for (final m in methods) {
      m.remove('_sortOrder');
    }

    return methods;
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
