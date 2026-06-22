enum PaymentInitiateUiMode {
  success,
  ussdPending,
  qrCode,
  failure,
}

/// Parses POST /api/payments/initiate responses (and Ebirr RCS_SUCCESS quirk).
class PaymentInitiateResult {
  const PaymentInitiateResult({
    required this.isSuccess,
    required this.uiMode,
    this.paymentId,
    this.status,
    this.nextAction,
    this.message,
    this.qrCodeBase64,
    this.qrPayload,
    this.transactionId,
    this.customerMessage,
    this.referenceNumber,
    this.phone,
    this.amount,
    this.currency,
    this.raw,
  });

  final bool isSuccess;
  final PaymentInitiateUiMode uiMode;
  final int? paymentId;
  final String? status;
  final String? nextAction;
  final String? message;
  final String? qrCodeBase64;
  final String? qrPayload;
  final String? transactionId;
  final String? customerMessage;
  final String? referenceNumber;
  final String? phone;
  final String? amount;
  final String? currency;
  final Map<String, dynamic>? raw;

  static bool isEbirrRcsSuccess(Map<String, dynamic> json) {
    final message = json['message']?.toString();
    if (message == 'RCS_SUCCESS') return true;
    final errors = json['errors'];
    if (errors is Map) {
      final paymentErrors = errors['payment'];
      if (paymentErrors is List &&
          paymentErrors.any((e) => e?.toString() == 'RCS_SUCCESS')) {
        return true;
      }
    }
    return false;
  }

  static PaymentInitiateUiMode uiModeFromNextAction(String? nextAction) {
    switch (nextAction) {
      case 'poll_status':
        return PaymentInitiateUiMode.ussdPending;
      case 'show_qr_code':
        return PaymentInitiateUiMode.qrCode;
      default:
        return PaymentInitiateUiMode.success;
    }
  }

  factory PaymentInitiateResult.fromJson(Map<String, dynamic> json) {
    final ebirrSuccess = isEbirrRcsSuccess(json);
    final success = json['success'] == true || ebirrSuccess;

    if (!success) {
      final errorMessage = json['message']?.toString() ??
          _firstErrorMessage(json['errors']) ??
          'Payment initiation failed';
      return PaymentInitiateResult(
        isSuccess: false,
        uiMode: PaymentInitiateUiMode.failure,
        message: errorMessage,
        raw: json,
      );
    }

    final data = json['data'];
    final dataMap =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

    final payment = dataMap['payment'];
    final paymentMap =
        payment is Map ? Map<String, dynamic>.from(payment) : <String, dynamic>{};

    final paymentDetails = paymentMap['payment_details'];
    final detailsMap = paymentDetails is Map
        ? Map<String, dynamic>.from(paymentDetails)
        : <String, dynamic>{};

    final nextAction = dataMap['next_action']?.toString();
    final message = json['message']?.toString() ??
        (ebirrSuccess ? 'RCS_SUCCESS' : null) ??
        'Payment initiated';

    return PaymentInitiateResult(
      isSuccess: true,
      uiMode: uiModeFromNextAction(nextAction),
      paymentId: int.tryParse(paymentMap['id']?.toString() ?? ''),
      status: paymentMap['status']?.toString(),
      nextAction: nextAction,
      message: message,
      qrCodeBase64: detailsMap['qpay_qr_code']?.toString(),
      qrPayload: detailsMap['qpay_qr_id']?.toString(),
      transactionId: paymentMap['transaction_id']?.toString(),
      customerMessage: dataMap['customer_message']?.toString(),
      referenceNumber: detailsMap['sahay_reference_number']?.toString() ??
          detailsMap['qpay_awb']?.toString(),
      phone: paymentMap['phone_number']?.toString() ??
          detailsMap['phone']?.toString(),
      amount: paymentMap['amount']?.toString(),
      currency: paymentMap['currency']?.toString(),
      raw: json,
    );
  }

  static String? _firstErrorMessage(dynamic errors) {
    if (errors is! Map) return null;
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        return value.first?.toString();
      }
      if (value != null) return value.toString();
    }
    return null;
  }
}

bool paymentMethodSkipsInitiate(String? code) {
  if (code == null || code.isEmpty) return false;
  return code == 'wallet' || code == 'cash_on_delivery';
}

bool paymentMethodNeedsDetailsForm(String? code) {
  if (code == null || code.isEmpty) return false;
  return code == 'sahay' ||
      code == 'edahab' ||
      code == 'waafi' ||
      code == 'ebirr';
}
