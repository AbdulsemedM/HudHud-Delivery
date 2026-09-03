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
    this.walletTopupSettlement,
    this.qpayStatus,
    this.errorCode,
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
  final String? walletTopupSettlement;
  final String? qpayStatus;
  final String? errorCode;
  final Map<String, dynamic>? raw;

  bool get isTerminal => isTerminalPaymentStatus(status);
  bool get isCompleted => status == 'completed';

  bool get isWalletTopUpSettled {
    final settlement = walletTopupSettlement?.toLowerCase();
    if (settlement == 'credited' || settlement == 'already_credited') {
      return true;
    }
    if (walletTopupSettlement != null && walletTopupSettlement!.isNotEmpty) {
      return false;
    }
    final s = status?.toLowerCase();
    return s == 'completed' || s == 'paid' || s == 'settled';
  }

  bool get isWalletTopUpPending {
    final settlement = walletTopupSettlement?.toLowerCase();
    if (settlement == 'awaiting_provider_confirmation' ||
        settlement == 'awaiting_provider_amount') {
      return true;
    }
    return isPendingPaymentStatus(status);
  }

  bool get isWalletTopUpTerminalFailure {
    if (isWalletTopUpSettled) return false;
    final settlement = walletTopupSettlement?.toLowerCase();
    if (settlement == 'failed' || settlement == 'expired') return true;
    final s = status?.toLowerCase();
    if (s == 'failed' ||
        s == 'expired' ||
        s == 'cancelled' ||
        s == 'refunded') {
      return true;
    }
    final qpay = qpayStatus?.toUpperCase();
    return qpay == 'FAILED' || qpay == 'EXPIRED';
  }

  bool get isQpayFatalPollError =>
      errorCode == 'QPAY_TRANSACTION_REFERENCE_MISSING';

  bool get isQpayStatusUnavailable =>
      errorCode == 'QPAY_STATUS_UNAVAILABLE';

  bool get isFailed =>
      status == 'failed' || status == 'cancelled' || status == 'refunded';

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    if (!success) {
      final errors = json['errors'];
      String? code;
      if (errors is Map) {
        code = errors['code']?.toString() ?? errors['error_code']?.toString();
      }
      code ??= json['code']?.toString() ?? json['error_code']?.toString();
      return PaymentStatusResult(
        isSuccess: false,
        message: json['message']?.toString() ?? 'Failed to fetch payment status',
        errorCode: code,
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

    final settlement = dataMap['wallet_topup_settlement']?.toString() ??
        paymentMap['wallet_topup_settlement']?.toString();
    final qpayStatus = dataMap['qpay_status']?.toString() ??
        paymentMap['qpay_status']?.toString();

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
      walletTopupSettlement: settlement,
      qpayStatus: qpayStatus,
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
  'expired',
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
    case 'ussd':
    case 'approve_ussd':
    case 'poll_status':
      return true;
  }

  return isPendingPaymentStatus(status);
}

/// Whether wallet top-up polling should continue for this status result.
bool shouldContinueWalletTopUpPoll(PaymentStatusResult result) {
  if (!result.isSuccess) {
    return result.isQpayStatusUnavailable;
  }
  if (result.isQpayFatalPollError) return false;
  if (result.isWalletTopUpSettled) return false;
  if (result.isWalletTopUpTerminalFailure) return false;
  return result.isWalletTopUpPending || !result.isTerminal;
}
