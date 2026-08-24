import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';

import '../data/models/create_delivery_result.dart';

/// Server-persisted delivery total only — never fall back to a client estimate.
double? resolveServerDeliveryPaymentAmount(CreateDeliveryResult created) {
  final amount = created.totalAmount;
  if (amount == null || amount <= 0) return null;
  return amount;
}

/// Cash-on-delivery and canonical cash — no online payment initiation.
bool isOfflineDeliveryPayment(String? method) {
  final m = (method ?? '').toLowerCase().trim();
  return m == 'cash_on_delivery' || m == 'cash';
}

/// Booking / confirm UI — never offer cash on delivery.
List<Map<String, dynamic>> excludeCashOnDeliveryPaymentMethods(
  List<Map<String, dynamic>> methods,
) {
  return methods
      .where((m) {
        final id = m['id']?.toString() ?? '';
        return id.isNotEmpty &&
            !isOfflineDeliveryPayment(id) &&
            m['enabled'] != false;
      })
      .toList(growable: false);
}

/// Initiates payment for a parcel delivery via POST /api/payments/initiate (type=delivery).
Future<PaymentInitiateResult> initiateDeliveryPayment({
  required PaymentRepository repo,
  required int packageDeliveryId,
  required String paymentMethodCode,
  required double amount,
  required String currency,
  Map<String, dynamic>? paymentDetails,
  String? idempotencyKey,
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
    idempotencyKey: idempotencyKey,
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
