import '../../../../core/utils/api_error_result.dart';

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
  'qpay',
  'waafi',
  'edahab',
  'sahay',
  'ebirr',
  'ebirr_kaafi',
  'ebirr_coop',
};

/// Fallback display list when API methods are unavailable.
/// What to offer when the server's own method list cannot be loaded.
///
/// This is a fallback, so every entry has to be something that actually works
/// without asking the server first. It used to list Sahay, eBirr (Kaafi) and
/// eBirr (Coop) alongside Waafi and eDahab — none of which are enabled. A
/// customer who opened checkout while the list request failed would be shown a
/// gateway that could not take their money, pick it, and fail at the provider.
///
/// Wallet and cash settle without a gateway. QPay is the one fully
/// credentialed gateway (the 11 Nov launch preflight found credentials missing
/// for every other one), so it is the only gateway safe to assume.
///
/// Adding a gateway back belongs on the server — PAYMENT_GATEWAYS_ENABLED plus
/// its credentials — and the live list will carry it. Add it here only once it
/// is genuinely always available, because this list is used precisely when the
/// server cannot be asked.
const List<Map<String, dynamic>> kDefaultAllowedPaymentMethods = [
  {'id': 'wallet', 'name': 'Wallet', 'enabled': true},
  {'id': 'cash_on_delivery', 'name': 'Cash on Delivery', 'enabled': true},
  {'id': 'qpay', 'name': 'QPay', 'enabled': true},
];

/// Display names for every payment code that can appear on a record.
///
/// Separate from the list above on purpose: these are two different questions.
/// What may a customer CHOOSE today is the fallback list, and it must shrink
/// when a gateway is retired. What is this code CALLED must keep covering
/// retired gateways forever, because deliveries paid with them still exist and
/// still have to render.
///
/// Narrowing the fallback list without this split relabelled historical eBirr
/// deliveries from "eBirr (Coop)" to "Ebirr Coop" — the title-cased fallback.
const Map<String, String> kPaymentMethodDisplayNames = {
  'wallet': 'Wallet',
  'cash': 'Cash',
  'cash_on_delivery': 'Cash on Delivery',
  'qpay': 'QPay',
  // Retired from checkout, kept here: past deliveries still reference them.
  'sahay': 'Sahay',
  'telebirr': 'Telebirr',
  'ebirr': 'eBirr',
  'ebirr_kaafi': 'eBirr (Kaafi)',
  'ebirr_coop': 'eBirr (Coop)',
  'waafi': 'Waafi Pay',
  'edahab': 'eDahab',
};

/// True for legacy `ebirr` and provider-specific API codes.
bool isEbirrPaymentMethodCode(String? code) {
  if (code == null || code.isEmpty) return false;
  return code == 'ebirr' || code == 'ebirr_kaafi' || code == 'ebirr_coop';
}

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
    this.qrCodeRaw,
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
    this.idempotentReplay = false,
    this.instantCredit = false,
    this.ussdDispatched = false,
    this.checkoutRequestId,
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
  /// Unmodified QR payload from API (plain EMVCo string, data URL, image URL, etc.).
  final String? qrCodeRaw;
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

  /// True when the API returned the original payment for a repeated Idempotency-Key.
  final bool idempotentReplay;

  /// True when the wallet was credited immediately (rare for USSD providers).
  final bool instantCredit;

  /// True when a USSD push was already sent to the customer phone.
  final bool ussdDispatched;

  /// Provider checkout / request id when present.
  final String? checkoutRequestId;

  final Map<String, dynamic>? raw;

  /// Cash on delivery: the server answers success with
  /// `next_action: pay_cash_on_delivery` and the payment stays pending until
  /// the cash is collected — never show it as "payment completed".
  bool get isCashOnDelivery =>
      method == 'cash_on_delivery' || nextAction == 'pay_cash_on_delivery';

  /// Prefer USSD / approve-on-phone copy instead of “payment completed”.
  bool get showUssdSuccessCopy =>
      ussdDispatched ||
      nextAction == 'ussd' ||
      nextAction == 'approve_ussd' ||
      nextAction == 'poll_status' ||
      nextAction == 'user_action_required';

  bool get isPendingPayment {
    final s = status?.toLowerCase();
    return s == 'pending' || s == 'processing' || s == null && showUssdSuccessCopy;
  }

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
      case 'ussd':
      case 'approve_ussd':
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
      final parsed = parseApiErrorResult(json);
      return PaymentInitiateResult(
        isSuccess: false,
        uiMode: PaymentInitiateUiMode.failure,
        message: parsed.displayMessage,
        raw: json,
      );
    }

    final data = json['data'];
    final dataMap =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

    final payment = dataMap['payment'] ?? json['payment'];
    final paymentMap = payment is Map
        ? Map<String, dynamic>.from(payment)
        : <String, dynamic>{};

    final delivery = dataMap['delivery'] ?? json['delivery'];
    final deliveryMap = delivery is Map
        ? Map<String, dynamic>.from(delivery)
        : <String, dynamic>{};

    final paymentDetails = paymentMap['payment_details'];
    final detailsMap = paymentDetails is Map
        ? Map<String, dynamic>.from(paymentDetails)
        : <String, dynamic>{};

    var nextAction = dataMap['next_action']?.toString() ??
        json['next_action']?.toString();
    final message = json['message']?.toString() ??
        paymentMap['message']?.toString() ??
        (ebirrSuccess ? 'RCS_SUCCESS' : null) ??
        'Payment initiated';

    final topLevelQr = dataMap['qr_code']?.toString();
    final dataQpayQr = dataMap['qpay_qr_code']?.toString();
    final nestedQr = detailsMap['qpay_qr_code']?.toString();
    final paymentQr = paymentMap['qr_code']?.toString();
    final qrRaw = _firstNonEmpty([
      topLevelQr,
      dataQpayQr,
      nestedQr,
      paymentQr,
    ]);
    final qrCodeBase64 = _stripDataUriPrefix(qrRaw);

    final ussdSent = dataMap['ussd_sent'] == true ||
        json['ussd_sent'] == true ||
        paymentMap['ussd_sent'] == true ||
        paymentMap['initiated'] == true;
    final ussdDispatched = dataMap['ussd_dispatched'] == true ||
        json['ussd_dispatched'] == true ||
        ussdSent;
    final instantCredit = dataMap['instant_credit'] == true ||
        json['instant_credit'] == true;

    if ((nextAction == null || nextAction.isEmpty) && ussdDispatched) {
      nextAction = 'approve_ussd';
    }

    final status = paymentMap['status']?.toString() ??
        deliveryMap['payment_status']?.toString();

    return PaymentInitiateResult(
      isSuccess: true,
      uiMode: uiModeFromNextAction(nextAction),
      paymentId: int.tryParse(paymentMap['id']?.toString() ?? ''),
      status: status,
      method: paymentMap['method']?.toString(),
      nextAction: nextAction,
      message: message,
      qrCodeBase64: qrCodeBase64,
      qrCodeRaw: qrRaw,
      qrPayload: detailsMap['qpay_qr_id']?.toString(),
      qrId:
          dataMap['qr_id']?.toString() ?? detailsMap['qpay_qr_id']?.toString(),
      redirectUrl: dataMap['redirect_url']?.toString(),
      expiresAt: dataMap['expires_at']?.toString(),
      transactionId: paymentMap['transaction_id']?.toString(),
      customerMessage: dataMap['customer_message']?.toString(),
      referenceNumber: paymentMap['reference']?.toString() ??
          paymentMap['reference_id']?.toString() ??
          detailsMap['sahay_reference_number']?.toString() ??
          detailsMap['qpay_awb']?.toString(),
      phone: paymentMap['phone_number']?.toString() ??
          detailsMap['phone']?.toString(),
      amount: paymentMap['amount']?.toString(),
      currency: paymentMap['currency']?.toString(),
      orderStatus: dataMap['order_status']?.toString(),
      idempotentReplay: json['idempotent_replay'] == true ||
          dataMap['idempotent_replay'] == true,
      instantCredit: instantCredit,
      ussdDispatched: ussdDispatched,
      checkoutRequestId: dataMap['checkout_request_id']?.toString() ??
          json['checkout_request_id']?.toString(),
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

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.isNotEmpty) return value;
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
      isEbirrPaymentMethodCode(code);
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
