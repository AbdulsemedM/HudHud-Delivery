import '../../../../core/api/api_constants.dart';
import '../presentation/widgets/payment_details_form.dart';

/// Allowed payment methods for handyman/service convenience endpoints (no COD).
const Set<String> kServicePaymentMethodCodes = {
  'wallet',
  'waafi',
  'edahab',
  'sahay',
  'ebirr',
};

/// Fallback list when API methods are unavailable (excludes COD).
const List<Map<String, dynamic>> kDefaultServicePaymentMethods = [
  {'id': 'wallet', 'name': 'Wallet', 'enabled': true},
  {'id': 'waafi', 'name': 'Waafi Pay', 'enabled': true},
  {'id': 'edahab', 'name': 'eDahab', 'enabled': true},
  {'id': 'sahay', 'name': 'Sahay', 'enabled': true},
  {'id': 'ebirr', 'name': 'eBirr', 'enabled': true},
];

/// Filters API payment methods to service convenience allowlist.
List<Map<String, dynamic>> filterServicePaymentMethods(
  List<Map<String, dynamic>> methods,
) {
  final filtered = methods.where((m) {
    final id = m['id']?.toString();
    return id != null && kServicePaymentMethodCodes.contains(id);
  }).toList();
  return filtered.isNotEmpty
      ? filtered
      : List<Map<String, dynamic>>.from(kDefaultServicePaymentMethods);
}

/// Maps UI method code to convenience API path.
String servicePaymentPathForMethod(String methodCode) {
  switch (methodCode) {
    case 'wallet':
      return ApiConstants.paymentsServiceWallet;
    case 'waafi':
      return ApiConstants.paymentsServiceWaafipay;
    case 'edahab':
      return ApiConstants.paymentsServiceEdahab;
    case 'sahay':
      return ApiConstants.paymentsServiceSahay;
    case 'ebirr':
      return ApiConstants.paymentsServiceEbirr;
    default:
      throw ArgumentError('Unsupported service payment method: $methodCode');
  }
}

/// Builds request body for POST /api/payments/service/{method}.
///
/// For eBirr, always sends `provider: "ebirr"` per convenience API docs.
Map<String, dynamic> buildServicePaymentBody({
  required String methodCode,
  required int serviceRequestId,
  Map<String, dynamic>? paymentDetails,
}) {
  final body = <String, dynamic>{
    'service_request_id': serviceRequestId,
  };

  if (methodCode == 'wallet') {
    return body;
  }

  final details = paymentDetails ?? {};
  final phoneRaw = details['phone']?.toString();
  final phone = normalizePaymentPhone(phoneRaw, methodCode);
  if (phone.isNotEmpty) {
    body['phone'] = phone;
  }

  if (methodCode == 'waafi') {
    body['use_hpp'] = details['use_hpp'] == true;
  }

  if (methodCode == 'ebirr') {
    body['provider'] = 'ebirr';
  }

  return body;
}
