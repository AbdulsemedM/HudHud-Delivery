import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';

export 'package:hudhud_delivery/features/payment/utils/service_payment_mapping.dart';

/// Pays a service request via convenience endpoints; parses as [PaymentInitiateResult].
Future<PaymentInitiateResult> initiateServiceConveniencePayment({
  required PaymentRepository repo,
  required int serviceRequestId,
  required String paymentMethodCode,
  Map<String, dynamic>? paymentDetails,
}) async {
  final raw = await repo.processServicePayment(
    methodCode: paymentMethodCode,
    serviceRequestId: serviceRequestId,
    paymentDetails: paymentDetails,
  );
  return PaymentInitiateResult.fromJson(raw);
}
