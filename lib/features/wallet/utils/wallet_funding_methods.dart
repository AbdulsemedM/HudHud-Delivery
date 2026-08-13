/// Methods allowed for wallet top-up / withdraw (no wallet, no COD).
const Set<String> kWalletFundingMethodCodes = {
  'waafi',
  'edahab',
  'sahay',
  'ebirr',
  'ebirr_kaafi',
  'ebirr_coop',
};

const List<Map<String, dynamic>> kDefaultWalletFundingMethods = [
  {'id': 'waafi', 'name': 'Waafi Pay', 'enabled': true},
  {'id': 'edahab', 'name': 'eDahab', 'enabled': true},
  {'id': 'sahay', 'name': 'Sahay', 'enabled': true},
  {'id': 'ebirr_kaafi', 'name': 'eBirr (Kaafi)', 'enabled': true},
  {'id': 'ebirr_coop', 'name': 'eBirr (Coop)', 'enabled': true},
];

List<Map<String, dynamic>> filterWalletFundingMethods(
  List<Map<String, dynamic>> methods,
) {
  final filtered = methods.where((m) {
    final id = m['id']?.toString();
    return id != null && kWalletFundingMethodCodes.contains(id);
  }).toList();
  return filtered.isNotEmpty
      ? filtered
      : List<Map<String, dynamic>>.from(kDefaultWalletFundingMethods);
}

/// Builds POST /api/wallet/topup body.
Map<String, dynamic> buildWalletTopupBody({
  required String paymentMethodCode,
  required double amount,
  required String currency,
  Map<String, dynamic>? paymentDetails,
}) {
  return {
    'payment_method_code': paymentMethodCode,
    'amount': amount,
    'currency': currency,
    'payment_details': paymentDetails ?? {},
  };
}

/// Builds POST /api/wallet/withdraw body.
Map<String, dynamic> buildWalletWithdrawBody({
  required String paymentMethodCode,
  required double amount,
  Map<String, dynamic>? paymentDetails,
}) {
  return {
    'amount': amount,
    'payment_method_code': paymentMethodCode,
    'payment_details': paymentDetails ?? {},
  };
}
