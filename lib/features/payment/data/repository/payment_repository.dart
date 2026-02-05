import '../data_provider/payment_data_provider.dart';

class PaymentRepository {
  final PaymentDataProvider paymentDataProvider;

  PaymentRepository({required this.paymentDataProvider});

  Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required double amount,
    required String orderId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      // Validate payment method (allow API-returned methods: wallet, card, cash_on_delivery, mpesa, etc.)
      final validMethods = [
        'wallet',
        'card',
        'cash_on_delivery',
        'mpesa',
        'telebirr',
        'chapa',
        'cbe',
        'ebirr',
        'amole',
      ];
      if (!validMethods.contains(paymentMethod)) {
        throw Exception('Invalid payment method: $paymentMethod');
      }

      // Validate amount
      if (amount <= 0) {
        throw Exception('Invalid payment amount: $amount');
      }

      // Process payment through data provider
      final result = await paymentDataProvider.processPayment(
        paymentMethod: paymentMethod,
        amount: amount,
        orderId: orderId,
        paymentDetails: paymentDetails,
      );

      return result;
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final methods = await paymentDataProvider.getPaymentMethods();

      // Filter enabled payment methods
      return methods.where((method) => method['enabled'] == true).toList();
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  Future<Map<String, dynamic>> validatePayment({
    required String transactionId,
    required String paymentMethod,
  }) async {
    try {
      return await paymentDataProvider.validatePayment(
        transactionId: transactionId,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      throw Exception('Payment validation failed: $e');
    }
  }

  // Mock payment processing for demo purposes
  Future<Map<String, dynamic>> mockProcessPayment({
    required String paymentMethod,
    required double amount,
    required String orderId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock successful payment
    return {
      'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'success',
      'message': 'Payment processed successfully via $paymentMethod',
      'amount': amount,
      'order_id': orderId,
      'payment_method': paymentMethod,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
