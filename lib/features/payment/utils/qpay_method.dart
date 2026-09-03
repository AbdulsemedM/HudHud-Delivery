import '../model/payment_initiate_result.dart';

const String kQpayMethodCode = 'qpay';
const String kQpayNotConfigured = 'QPAY_NOT_CONFIGURED';

bool isQpay(String? code) =>
    code != null && code.toLowerCase() == kQpayMethodCode;

/// True when the method list entry can initiate a QPay wallet top-up.
bool canInitiateQpay(Map<String, dynamic> method) {
  final code = method['id']?.toString() ?? method['code']?.toString();
  if (!isQpay(code)) return false;
  if (method['enabled'] == false) return false;
  if (method['can_use'] == false) return false;
  final availability = method['availability_code']?.toString();
  if (availability == kQpayNotConfigured) return false;
  return true;
}

/// True when initiate response is ready to show the QPay QR sheet.
bool qpayInitiateLooksValid(PaymentInitiateResult result) {
  if (!result.isSuccess) return false;
  if (result.nextAction != 'show_qr_code') return false;
  if (result.paymentId == null || result.paymentId! <= 0) return false;
  final qr = result.qrCodeBase64;
  return qr != null && qr.isNotEmpty;
}

/// Sort QPay to the top when present.
List<Map<String, dynamic>> sortQpayFirst(
  List<Map<String, dynamic>> methods,
) {
  final copy = List<Map<String, dynamic>>.from(methods);
  copy.sort((a, b) {
    final aQpay = isQpay(a['id']?.toString()) ? 0 : 1;
    final bQpay = isQpay(b['id']?.toString()) ? 0 : 1;
    return aQpay.compareTo(bQpay);
  });
  return copy;
}

bool hasUsableQpayInList(List<Map<String, dynamic>> methods) =>
    methods.any(canInitiateQpay);
