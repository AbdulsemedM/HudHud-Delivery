import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/features/payment/utils/qpay_method.dart';

/// Builds `payment_details` for POST /api/wallet/topup.
Map<String, dynamic> buildWalletTopUpPaymentDetails({
  required String paymentMethodCode,
  Map<String, dynamic> collectedDetails = const {},
  int orderId = 0,
}) {
  if (isQpay(paymentMethodCode)) {
    return const {'channel': 'qr'};
  }
  return buildInitiatePaymentDetails(
    paymentMethodCode: paymentMethodCode,
    collectedDetails: collectedDetails,
    orderId: orderId,
  );
}
