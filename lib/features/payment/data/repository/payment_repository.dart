import '../../../../core/api/api_service.dart';
import '../data_provider/payment_data_provider.dart';
import '../../model/payment_initiate_result.dart';
import '../../model/payment_status_result.dart';
import '../../utils/qpay_method.dart';
import '../../utils/service_payment_mapping.dart';

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

  Future<List<Map<String, dynamic>>> getPaymentMethods({String? type}) async {
    try {
      final methods = await paymentDataProvider.getPaymentMethods(type: type);
      final enabled = methods.where((method) => method['enabled'] == true);
      return filterAllowedPaymentMethods(enabled.toList());
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  /// Finds a usable QPay method: wallet registry → delivery → untyped.
  Future<Map<String, dynamic>?> resolveUsableQpay() async {
    for (final type in ['wallet', 'delivery', null]) {
      try {
        final methods = await getPaymentMethods(type: type);
        for (final method in methods) {
          if (canInitiateQpay(method)) return method;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Service convenience payment (POST /api/payments/service/...).
  Future<Map<String, dynamic>> processServicePayment({
    required String methodCode,
    required int serviceRequestId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      if (!kServicePaymentMethodCodes.contains(methodCode)) {
        throw Exception('Unsupported service payment method: $methodCode');
      }
      if (serviceRequestId <= 0) {
        throw Exception('Invalid service request id: $serviceRequestId');
      }

      final path = servicePaymentPathForMethod(methodCode);
      final body = buildServicePaymentBody(
        methodCode: methodCode,
        serviceRequestId: serviceRequestId,
        paymentDetails: paymentDetails,
      );

      return await paymentDataProvider.processServicePayment(
        path: path,
        body: body,
      );
    } catch (e) {
      throw Exception('Service payment failed: $e');
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
    String? idempotencyKey,
  }) async {
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

    try {
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
        idempotencyKey: idempotencyKey,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Payment initiation failed: $e');
    }
  }

  Future<PaymentStatusResult> getPaymentStatus(int paymentId) async {
    try {
      if (paymentId <= 0) {
        throw Exception('Invalid payment id: $paymentId');
      }
      final raw = await paymentDataProvider.getPaymentStatus(paymentId);
      return PaymentStatusResult.fromJson(raw);
    } catch (e) {
      throw Exception('Payment status fetch failed: $e');
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
