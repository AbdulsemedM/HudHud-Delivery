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
      if (paymentMethod.isEmpty) {
        throw Exception('Payment method is required');
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

  Future<Map<String, dynamic>> initiatePayment({
    required String paymentMethodCode,
    required int orderId,
    required double amount,
    required String currency,
    String type = 'order',
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      if (paymentMethodCode.isEmpty) {
        throw Exception('Payment method is required');
      }
      if (orderId <= 0) {
        throw Exception('Invalid order id: $orderId');
      }
      if (amount <= 0) {
        throw Exception('Invalid payment amount: $amount');
      }

      return await paymentDataProvider.initiatePayment(
        paymentMethodCode: paymentMethodCode,
        orderId: orderId,
        amount: amount,
        currency: currency,
        type: type,
        paymentDetails: paymentDetails,
      );
    } catch (e) {
      throw Exception('Payment initiation failed: $e');
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
}
