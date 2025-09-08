import '../../../../core/api/api_service.dart';

class PaymentDataProvider {
  final ApiService apiService;

  PaymentDataProvider({required this.apiService});

  Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required double amount,
    required String orderId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final response = await apiService.post(
        '/payments/process',
        data: {
          'payment_method': paymentMethod,
          'amount': amount,
          'order_id': orderId,
          'payment_details': paymentDetails ?? {},
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      // Mock Ethiopian payment methods for now
      // In a real app, this would come from the API
      return [
        {
          'id': 'telebirr',
          'name': 'Telebirr',
          'icon': 'assets/images/telebirr.png',
          'description': 'Pay with Telebirr mobile wallet',
          'enabled': true,
        },
        {
          'id': 'chapa',
          'name': 'Chapa',
          'icon': 'assets/images/chapa.png',
          'description': 'Pay with Chapa payment gateway',
          'enabled': true,
        },
        {
          'id': 'cbe',
          'name': 'CBE Birr',
          'icon': 'assets/images/cbe.png',
          'description': 'Commercial Bank of Ethiopia mobile banking',
          'enabled': true,
        },
        {
          'id': 'ebirr',
          'name': 'E-birr',
          'icon': 'assets/images/ebirr.png',
          'description': 'Pay with E-birr digital wallet',
          'enabled': true,
        },
        {
          'id': 'amole',
          'name': 'Amole',
          'icon': 'assets/images/amole.png',
          'description': 'Pay with Amole mobile money',
          'enabled': true,
        },
      ];
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
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