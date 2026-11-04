import 'package:intl/intl.dart';

/// `refund` block returned by order cancel endpoints
/// (OrderRefundService::refundCancelledOrder): `{status, amount?, currency?}`.
class OrderRefund {
  static const String refunded = 'refunded';
  static const String refundedToWallet = 'refunded_to_wallet';
  static const String manualRefundRequired = 'manual_refund_required';
  static const String notRequired = 'not_required';
  static const String alreadyRefunded = 'already_refunded';

  final String status;
  final double? amount;
  final String? currency;

  const OrderRefund({required this.status, this.amount, this.currency});

  /// Money went back to the customer's HudHud wallet (wallet payments are
  /// `refunded`, provider payments `refunded_to_wallet`).
  bool get isToWallet =>
      (status == refunded || status == refundedToWallet) &&
      (amount ?? 0) > 0.009;

  /// `ETB 1,005` / `USD 12.50` (currency defaults to ETB).
  String get formattedAmount {
    final value = amount ?? 0;
    final whole = (value - value.roundToDouble()).abs() < 0.005;
    final number =
        NumberFormat(whole ? '#,##0' : '#,##0.00', 'en_US').format(value);
    return '${currency ?? 'ETB'} $number';
  }

  /// Finance has to refund by hand (no exchange rate, payer missing, …).
  bool get isManual => status == manualRefundRequired;

  /// Parses the `refund` value; null when absent or not a refund object
  /// (e.g. the legacy string form).
  static OrderRefund? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final status = raw['status']?.toString().trim().toLowerCase();
    if (status == null || status.isEmpty) return null;
    final amountRaw = raw['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '');
    final currency = raw['currency']?.toString().trim().toUpperCase();
    return OrderRefund(
      status: status,
      amount: amount,
      currency: currency == null || currency.isEmpty ? null : currency,
    );
  }
}

/// Successful cancel: server message plus the refund outcome when the
/// endpoint reports one.
class OrderCancelResult {
  final String message;
  final OrderRefund? refund;

  const OrderCancelResult({required this.message, this.refund});

  /// Parses a cancel response body `{message, refund?, order?}` (also
  /// accepts `{data: {refund}}`).
  factory OrderCancelResult.fromResponseBody(dynamic body) {
    String message = 'Order cancelled successfully';
    OrderRefund? refund;
    if (body is Map) {
      final m = body['message']?.toString().trim();
      if (m != null && m.isNotEmpty) message = m;
      refund = OrderRefund.tryParse(body['refund']);
      final data = body['data'];
      if (refund == null && data is Map) {
        refund = OrderRefund.tryParse(data['refund']);
      }
    }
    return OrderCancelResult(message: message, refund: refund);
  }
}
