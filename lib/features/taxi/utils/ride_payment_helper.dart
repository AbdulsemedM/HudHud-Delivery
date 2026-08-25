import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';

/// Initiates payment for a completed ride via POST /api/payments/initiate (type=ride).
Future<PaymentInitiateResult> initiateRidePayment({
  required PaymentRepository repo,
  required int rideId,
  required String paymentMethodCode,
  required double amount,
  required String currency,
  Map<String, dynamic>? paymentDetails,
  String? idempotencyKey,
}) async {
  final details = buildInitiatePaymentDetails(
    paymentMethodCode: paymentMethodCode,
    collectedDetails: paymentDetails ?? {},
    orderId: rideId,
  );

  final key = idempotencyKey ??
      createPaymentIdempotencyKey(type: 'ride', entityId: rideId);

  final raw = await repo.initiatePayment(
    paymentMethodCode: paymentMethodCode,
    type: 'ride',
    rideId: rideId,
    amount: amount,
    currency: currency,
    paymentDetails: details,
    idempotencyKey: key,
  );

  return PaymentInitiateResult.fromJson(raw);
}
