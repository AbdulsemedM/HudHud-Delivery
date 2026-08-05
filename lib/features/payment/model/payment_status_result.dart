/// Parsed GET /api/payments/{id}/status response.
class PaymentStatusResult {
  const PaymentStatusResult({
    required this.isSuccess,
    this.paymentId,
    this.status,
    this.method,
    this.type,
    this.amount,
    this.currency,
    this.transactionId,
    this.reference,
    this.paidAt,
    this.relatedOrderId,
    this.relatedOrderStatus,
    this.message,
    this.raw,
  });

  final bool isSuccess;
  final int? paymentId;
  final String? status;
  final String? method;
  final String? type;
  final String? amount;
  final String? currency;
  final String? transactionId;
  final String? reference;
  final String? paidAt;
  final int? relatedOrderId;
  final String? relatedOrderStatus;
  final String? message;
  final Map<String, dynamic>? raw;

  bool get isTerminal => isTerminalPaymentStatus(status);
  bool get isCompleted => status == 'completed';
  bool get isFailed =>
      status == 'failed' || status == 'cancelled' || status == 'refunded';

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    if (!success) {
      return PaymentStatusResult(
        isSuccess: false,
        message: json['message']?.toString() ?? 'Failed to fetch payment status',
        raw: json,
      );
    }

    final data = json['data'];
    final dataMap =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

    final payment = dataMap['payment'];
    final paymentMap =
        payment is Map ? Map<String, dynamic>.from(payment) : <String, dynamic>{};

    final related = dataMap['related'];
    final relatedMap =
        related is Map ? Map<String, dynamic>.from(related) : <String, dynamic>{};

    return PaymentStatusResult(
      isSuccess: true,
      paymentId: int.tryParse(paymentMap['id']?.toString() ?? ''),
      status: paymentMap['status']?.toString(),
      method: paymentMap['method']?.toString(),
      type: paymentMap['type']?.toString(),
      amount: paymentMap['amount']?.toString(),
      currency: paymentMap['currency']?.toString(),
      transactionId: paymentMap['transaction_id']?.toString(),
      reference: paymentMap['reference']?.toString(),
      paidAt: paymentMap['paid_at']?.toString(),
      relatedOrderId: int.tryParse(relatedMap['order_id']?.toString() ?? ''),
      relatedOrderStatus: relatedMap['order_status']?.toString(),
      message: json['message']?.toString(),
      raw: json,
    );
  }
}

const Set<String> kTerminalPaymentStatuses = {
  'completed',
  'failed',
  'refunded',
  'partially_refunded',
  'cancelled',
};

const Set<String> kPendingPaymentStatuses = {
  'pending',
  'processing',
};

bool isTerminalPaymentStatus(String? status) {
  if (status == null || status.isEmpty) return false;
  return kTerminalPaymentStatuses.contains(status);
}

bool isPendingPaymentStatus(String? status) {
  if (status == null || status.isEmpty) return false;
  return kPendingPaymentStatuses.contains(status);
}

/// Whether the initiate result should start status polling.
bool shouldPollPaymentStatus({
  required bool isSuccess,
  String? nextAction,
  String? status,
  String? method,
}) {
  if (!isSuccess) return false;
  if (method == 'cash_on_delivery') return false;
  if (status == 'completed') return false;
  if (isTerminalPaymentStatus(status) && status != 'completed') {
    // Failed initiate already shown; no poll needed.
    return false;
  }

  switch (nextAction) {
    case 'show_qr_code':
    case 'redirect_to_hpp':
    case 'user_action_required':
    case 'poll_status':
      return true;
  }

  return isPendingPaymentStatus(status);
}
