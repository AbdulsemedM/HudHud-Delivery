import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';

/// Initiates payment for a parcel delivery via POST /api/payments/initiate (type=delivery).
Future<PaymentInitiateResult> initiateDeliveryPayment({
  required PaymentRepository repo,
  required int packageDeliveryId,
  required String paymentMethodCode,
  required double amount,
  required String currency,
  Map<String, dynamic>? paymentDetails,
}) async {
  final details = buildInitiatePaymentDetails(
    paymentMethodCode: paymentMethodCode,
    collectedDetails: paymentDetails ?? {},
    orderId: packageDeliveryId,
  );

  final raw = await repo.initiatePayment(
    paymentMethodCode: paymentMethodCode,
    type: 'delivery',
    packageDeliveryId: packageDeliveryId,
    amount: amount,
    currency: currency,
    paymentDetails: details,
  );

  return PaymentInitiateResult.fromJson(raw);
}
