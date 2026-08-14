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

/// True when the customer can retry payment from delivery details.
bool canRetryDeliveryPayment({
  String? paymentStatus,
  String? paymentMethod,
  String? deliveryStatus,
}) {
  final method = (paymentMethod ?? '').toLowerCase().trim();
  if (method == 'cash_on_delivery' || method == 'cash') return false;

  final delivery =
      (deliveryStatus ?? '').toLowerCase().trim().replaceAll(' ', '_');
  if (delivery.contains('cancel')) return false;

  final status =
      (paymentStatus ?? '').toLowerCase().trim().replaceAll(' ', '_');
  const paid = {'paid', 'completed', 'success', 'successful'};
  if (paid.contains(status)) return false;

  return true;
}

/// Payment phone for retry in backend format (`2519xxxxxxxx` for eBirr/Sahay).
String retryPaymentPhone({
  required String paymentMethod,
  String? paymentPhone,
  String? senderPhone,
}) {
  if (!paymentMethodNeedsDetailsForm(paymentMethod)) return '';
  final raw = (paymentPhone != null && paymentPhone.trim().isNotEmpty)
      ? paymentPhone
      : senderPhone;
  return normalizePaymentPhone(raw, paymentMethod);
}

/// Human-readable label for API payment method codes.
String formatPaymentMethodLabel(String? code) {
  if (code == null || code.trim().isEmpty) return '—';
  final normalized = code.trim();
  for (final method in kDefaultAllowedPaymentMethods) {
    if (method['id'] == normalized) {
      return method['name'] as String? ?? normalized;
    }
  }
  return normalized
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
