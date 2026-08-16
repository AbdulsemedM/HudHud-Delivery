/// Whether a courier delivery can still be cancelled by the customer.
///
/// Cancellation is blocked once the package is picked up (and for terminal
/// delivered / cancelled states).
bool canCancelCourierDelivery(String? status) {
  if (status == null || status.trim().isEmpty) return true;

  final normalized = status.toLowerCase().trim().replaceAll(' ', '_');

  const blockedExact = {
    'picked_up',
    'in_transit',
    'out_for_delivery',
    'delivered',
    'completed',
    'cancelled',
    'canceled',
  };

  if (blockedExact.contains(normalized)) return false;

  if (normalized.contains('picked_up') ||
      normalized.contains('in_transit') ||
      normalized.contains('out_for_delivery') ||
      normalized.contains('delivered') ||
      normalized.contains('completed') ||
      normalized.contains('cancel')) {
    return false;
  }

  return true;
}

/// Provider-confirmed payment statuses that may produce a wallet refund on cancel.
const Set<String> kCollectedDeliveryPaymentStatuses = {
  'completed',
  'paid',
  'succeeded',
  'success',
};

bool isCollectedDeliveryPaymentStatus(String? paymentStatus) {
  if (paymentStatus == null || paymentStatus.trim().isEmpty) return false;
  final normalized =
      paymentStatus.toLowerCase().trim().replaceAll(' ', '_');
  return kCollectedDeliveryPaymentStatuses.contains(normalized);
}

/// Confirm-dialog body. Mentions wallet refund only when payment was collected.
String cancelDeliveryConfirmMessage({String? paymentStatus}) {
  if (isCollectedDeliveryPaymentStatus(paymentStatus)) {
    return 'Are you sure you want to cancel this delivery? '
        'Confirmed payment will be refunded to your wallet.';
  }
  return 'Are you sure you want to cancel this delivery?';
}

/// Parsed cancel-delivery refund fields (when API includes them).
class DeliveryCancelRefundResult {
  const DeliveryCancelRefundResult({
    this.message,
    this.refundAmount,
    this.refundStatus,
  });

  final String? message;
  final double? refundAmount;
  final String? refundStatus;

  bool get hasRefund => refundAmount != null && refundAmount! > 0;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

double? _firstDouble(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String? _firstString(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

DeliveryCancelRefundResult parseDeliveryCancelRefundResponse(dynamic response) {
  final root = _asMap(response);
  final data = _asMap(root['data']);
  final payload = data.isNotEmpty ? data : root;

  return DeliveryCancelRefundResult(
    message: _firstString([
      root['message'],
      payload['message'],
    ]),
    refundAmount: _firstDouble([
      payload['refund_amount'],
      root['refund_amount'],
      payload['refunded_amount'],
      root['refunded_amount'],
    ]),
    refundStatus: _firstString([
      payload['refund_status'],
      root['refund_status'],
    ]),
  );
}

/// User-facing cancel snack text. Does not infer a refund from success alone.
String formatDeliveryCancelMessage(DeliveryCancelRefundResult refund) {
  final base = refund.message ?? 'Delivery cancelled successfully.';
  if (!refund.hasRefund) return base;

  final amount = refund.refundAmount!.toStringAsFixed(2);
  final status = refund.refundStatus ?? 'processing';
  return '$base Refund $amount ($status) will be credited to your wallet.';
}
