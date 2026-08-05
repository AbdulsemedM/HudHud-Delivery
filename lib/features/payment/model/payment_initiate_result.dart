enum PaymentInitiateUiMode {
  success,
  qrCode,
  redirectToHpp,
  userActionRequired,
  failure,

  /// Legacy alias — treated as [userActionRequired] in UI.
  ussdPending,
}

/// Allowed payment method codes per ground rules.
const Set<String> kAllowedPaymentMethodCodes = {
  'wallet',
  'cash_on_delivery',
  'waafi',
  'edahab',
  'sahay',
  'ebirr',
};

/// Fallback display list when API methods are unavailable.
const List<Map<String, dynamic>> kDefaultAllowedPaymentMethods = [
  {'id': 'wallet', 'name': 'Wallet', 'enabled': true},
  {'id': 'cash_on_delivery', 'name': 'Cash on Delivery', 'enabled': true},
  {'id': 'waafi', 'name': 'Waafi Pay', 'enabled': true},
  {'id': 'edahab', 'name': 'eDahab', 'enabled': true},
  {'id': 'sahay', 'name': 'Sahay', 'enabled': true},
  {'id': 'ebirr', 'name': 'eBirr', 'enabled': true},
];

/// Parses POST /api/payments/initiate responses (and Ebirr RCS_SUCCESS quirk).
class PaymentInitiateResult {
  const PaymentInitiateResult({
    required this.isSuccess,
    required this.uiMode,
    this.paymentId,
    this.status,
    this.method,
    this.nextAction,
    this.message,
    this.qrCodeBase64,
    this.qrPayload,
    this.qrId,
    this.redirectUrl,
    this.expiresAt,
    this.transactionId,
    this.customerMessage,
    this.referenceNumber,
    this.phone,
    this.amount,
    this.currency,
    this.orderStatus,
    this.raw,
  });

  final bool isSuccess;
  final PaymentInitiateUiMode uiMode;
  final int? paymentId;
  final String? status;
  final String? method;
  final String? nextAction;
  final String? message;
  final String? qrCodeBase64;
  final String? qrPayload;
  final String? qrId;
  final String? redirectUrl;
  final String? expiresAt;
  final String? transactionId;
  final String? customerMessage;
  final String? referenceNumber;
  final String? phone;
  final String? amount;
  final String? currency;
  final String? orderStatus;
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
      case 'show_qr_code':
        return PaymentInitiateUiMode.qrCode;
      case 'redirect_to_hpp':
        return PaymentInitiateUiMode.redirectToHpp;
      case 'user_action_required':
        return PaymentInitiateUiMode.userActionRequired;
      case 'poll_status':
        return PaymentInitiateUiMode.ussdPending;
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

    final topLevelQr = dataMap['qr_code']?.toString();
    final nestedQr = detailsMap['qpay_qr_code']?.toString();
    final qrRaw = (topLevelQr != null && topLevelQr.isNotEmpty)
        ? topLevelQr
        : nestedQr;
    final qrCodeBase64 = _stripDataUriPrefix(qrRaw);

    return PaymentInitiateResult(
      isSuccess: true,
      uiMode: uiModeFromNextAction(nextAction),
      paymentId: int.tryParse(paymentMap['id']?.toString() ?? ''),
      status: paymentMap['status']?.toString(),
      method: paymentMap['method']?.toString(),
      nextAction: nextAction,
      message: message,
      qrCodeBase64: qrCodeBase64,
      qrPayload: detailsMap['qpay_qr_id']?.toString(),
      qrId: dataMap['qr_id']?.toString() ?? detailsMap['qpay_qr_id']?.toString(),
      redirectUrl: dataMap['redirect_url']?.toString(),
      expiresAt: dataMap['expires_at']?.toString(),
      transactionId: paymentMap['transaction_id']?.toString(),
      customerMessage: dataMap['customer_message']?.toString(),
      referenceNumber: paymentMap['reference']?.toString() ??
          detailsMap['sahay_reference_number']?.toString() ??
          detailsMap['qpay_awb']?.toString(),
      phone: paymentMap['phone_number']?.toString() ??
          detailsMap['phone']?.toString(),
      amount: paymentMap['amount']?.toString(),
      currency: paymentMap['currency']?.toString(),
      orderStatus: dataMap['order_status']?.toString(),
      raw: json,
    );
  }

  static String? _stripDataUriPrefix(String? value) {
    if (value == null || value.isEmpty) return value;
    final comma = value.indexOf(',');
    if (value.startsWith('data:') && comma != -1) {
      return value.substring(comma + 1);
    }
    return value;
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

/// Always initiate — wallet and COD go through POST /api/payments/initiate.
@Deprecated('All methods initiate; kept for call-site compatibility')
bool paymentMethodSkipsInitiate(String? code) => false;

bool paymentMethodNeedsDetailsForm(String? code) {
  if (code == null || code.isEmpty) return false;
  return code == 'sahay' ||
      code == 'edahab' ||
      code == 'waafi' ||
      code == 'ebirr';
}

bool isAllowedPaymentMethodCode(String? code) {
  if (code == null || code.isEmpty) return false;
  return kAllowedPaymentMethodCodes.contains(code);
}

List<Map<String, dynamic>> filterAllowedPaymentMethods(
  List<Map<String, dynamic>> methods,
) {
  return methods
      .where((m) => isAllowedPaymentMethodCode(m['id']?.toString()))
      .toList(growable: false);
}
