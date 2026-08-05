import '../data_provider/payment_data_provider.dart';
import '../../model/payment_initiate_result.dart';

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

      if (amount <= 0) {
        throw Exception('Invalid payment amount: $amount');
      }

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
      final enabled = methods.where((method) => method['enabled'] == true);
      return filterAllowedPaymentMethods(enabled.toList());
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String paymentMethodCode,
    required double amount,
    String type = 'order',
    String? currency,
    int? orderId,
    int? rideId,
    int? serviceRequestId,
    int? packageDeliveryId,
    Map<String, dynamic>? paymentDetails,
    bool? isSandbox,
  }) async {
    try {
      if (paymentMethodCode.isEmpty) {
        throw Exception('Payment method is required');
      }
      if (amount <= 0) {
        throw Exception('Invalid payment amount: $amount');
      }

      switch (type) {
        case 'order':
          if (orderId == null || orderId <= 0) {
            throw Exception('Invalid order id: $orderId');
          }
        case 'ride':
          if (rideId == null || rideId <= 0) {
            throw Exception('Invalid ride id: $rideId');
          }
        case 'service':
          if (serviceRequestId == null || serviceRequestId <= 0) {
            throw Exception('Invalid service request id: $serviceRequestId');
          }
        case 'delivery':
          if (packageDeliveryId == null || packageDeliveryId <= 0) {
            throw Exception(
                'Invalid package delivery id: $packageDeliveryId');
          }
      }

      return await paymentDataProvider.initiatePayment(
        paymentMethodCode: paymentMethodCode,
        type: type,
        amount: amount,
        currency: currency,
        orderId: orderId,
        rideId: rideId,
        serviceRequestId: serviceRequestId,
        packageDeliveryId: packageDeliveryId,
        paymentDetails: paymentDetails,
        isSandbox: isSandbox,
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
