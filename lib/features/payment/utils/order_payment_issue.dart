import '../../../core/api/api_service.dart';

/// Server answers to `POST /api/payments/initiate` (PaymentController::
/// processPayment) for an order that already exists, which must keep the
/// customer on that order instead of showing a generic "payment failed".
enum OrderPaymentIssue {
  /// 409 "A payment for this order is already in progress…"
  inProgress,

  /// 409 "This order has already been paid." → treat as paid.
  alreadyPaid,

  /// 422 "Payment currency must match the order currency." or
  /// "Payment amount does not match the order total." → refresh totals.
  totalsChanged,

  /// 422 "This order cannot be paid for." (e.g. delivered / cancelled).
  notPayable,
}

/// Classifies [statusCode] + server [message] (+ optional error [data]).
/// Returns null for anything else (generic failure handling applies).
OrderPaymentIssue? classifyOrderPaymentIssue({
  int? statusCode,
  String? message,
  dynamic data,
}) {
  final lower = (message ?? '').toLowerCase();
  final map = data is Map ? data : const {};
  if (statusCode == 409) {
    if (lower.contains('already in progress')) {
      return OrderPaymentIssue.inProgress;
    }
    if (lower.contains('already been paid')) {
      return OrderPaymentIssue.alreadyPaid;
    }
    return null;
  }
  if (statusCode == 422) {
    if (lower.contains('currency must match') ||
        map.containsKey('expected_currency')) {
      return OrderPaymentIssue.totalsChanged;
    }
    if ((lower.contains('payment amount') && lower.contains('does not match')) ||
        map.containsKey('expected_amount')) {
      return OrderPaymentIssue.totalsChanged;
    }
    if (lower.contains('cannot be paid')) {
      return OrderPaymentIssue.notPayable;
    }
  }
  return null;
}

/// Same as [classifyOrderPaymentIssue] for a thrown error (ApiException).
OrderPaymentIssue? classifyOrderPaymentError(Object error) {
  if (error is! ApiException) return null;
  // ApiException.message is the parsed display text; the raw `message`
  // from the body is checked too (displayMessage may append details).
  final data = error.data;
  final raw = data is Map ? data['message']?.toString() : null;
  return classifyOrderPaymentIssue(
        statusCode: error.statusCode,
        message: raw,
        data: data,
      ) ??
      classifyOrderPaymentIssue(
        statusCode: error.statusCode,
        message: error.message,
        data: data,
      );
}
