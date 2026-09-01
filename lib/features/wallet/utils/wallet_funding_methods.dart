/// Methods allowed for wallet top-up / withdraw (no wallet, no COD).
const Set<String> kWalletFundingMethodCodes = {
  'qpay',
  'waafi',
  'edahab',
  'sahay',
  'ebirr',
  'ebirr_kaafi',
  'ebirr_coop',
};

/// Display order for wallet top-up (QPay first, then eBirr Coop / Kaafi).
const List<String> kWalletFundingMethodOrder = [
  'qpay',
  'ebirr_coop',
  'ebirr_kaafi',
  'waafi',
  'edahab',
  'sahay',
  'ebirr',
];

const List<Map<String, dynamic>> kDefaultWalletFundingMethods = [
  {'id': 'qpay', 'name': 'QPay', 'enabled': true, 'can_use': true},
  {'id': 'ebirr_coop', 'name': 'eBirr (Coop)', 'enabled': true},
  {'id': 'ebirr_kaafi', 'name': 'eBirr (Kaafi)', 'enabled': true},
  {'id': 'waafi', 'name': 'Waafi Pay', 'enabled': true},
  {'id': 'edahab', 'name': 'eDahab', 'enabled': true},
  {'id': 'sahay', 'name': 'Sahay', 'enabled': true},
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

/// QPay is hidden only when the backend explicitly marks it unavailable.
bool isQPayMethodAvailable(Map<String, dynamic> method) {
  final id = method['id']?.toString();
  if (id != 'qpay') return true;

  final availability = method['availability_code']?.toString();
  if (availability == 'QPAY_NOT_CONFIGURED') return false;

  if (method['can_use'] == false || method['enabled'] == false) return false;

  return true;
}

int _walletFundingMethodRank(String? id) {
  if (id == null || id.isEmpty) return kWalletFundingMethodOrder.length;
  final index = kWalletFundingMethodOrder.indexOf(id);
  return index == -1 ? kWalletFundingMethodOrder.length : index;
}

List<Map<String, dynamic>> sortWalletFundingMethods(
  List<Map<String, dynamic>> methods,
) {
  final sorted = List<Map<String, dynamic>>.from(methods);
  sorted.sort(
    (a, b) => _walletFundingMethodRank(a['id']?.toString())
        .compareTo(_walletFundingMethodRank(b['id']?.toString())),
  );
  return sorted;
}

/// Ensures QPay appears in the list when the API omits it (legacy endpoints).
List<Map<String, dynamic>> ensureQPayInWalletMethods(
  List<Map<String, dynamic>> methods,
) {
  if (methods.any((m) => m['id']?.toString() == 'qpay')) {
    return methods;
  }
  return [
    Map<String, dynamic>.from(kDefaultWalletFundingMethods.first),
    ...methods,
  ];
}

List<Map<String, dynamic>> applyQPayAvailabilityRules(
  List<Map<String, dynamic>> methods,
) {
  return methods.where(isQPayMethodAvailable).toList(growable: false);
}

bool _registryHasQPay(List<Map<String, dynamic>> methods) {
  return methods.any((m) => m['id']?.toString() == 'qpay');
}

/// Loads wallet funding methods with registry fallbacks per QPay guide.
Future<List<Map<String, dynamic>>> loadWalletFundingMethods({
  required Future<List<Map<String, dynamic>>> Function({String? type})
      fetchRegistry,
  required Future<List<Map<String, dynamic>>> Function() fetchLegacy,
}) async {
  List<Map<String, dynamic>> registryMethods = [];
  try {
    registryMethods = await fetchRegistry(type: 'wallet');
    if (!_registryHasQPay(registryMethods)) {
      final deliveryMethods = await fetchRegistry(type: 'delivery');
      final qpayOnly = deliveryMethods
          .where((m) => m['id']?.toString() == 'qpay')
          .toList(growable: false);
      if (qpayOnly.isNotEmpty) {
        registryMethods = [...registryMethods, ...qpayOnly];
      }
    }
    if (!_registryHasQPay(registryMethods)) {
      final allMethods = await fetchRegistry();
      final qpayOnly = allMethods
          .where((m) => m['id']?.toString() == 'qpay')
          .toList(growable: false);
      if (qpayOnly.isNotEmpty) {
        registryMethods = [...registryMethods, ...qpayOnly];
      }
    }
  } catch (_) {
    registryMethods = [];
  }

  List<Map<String, dynamic>> methods;
  if (registryMethods.isNotEmpty) {
    methods = registryMethods;
  } else {
    try {
      methods = await fetchLegacy();
    } catch (_) {
      methods = [];
    }
  }

  var filtered = applyQPayAvailabilityRules(
    filterWalletFundingMethods(methods),
  );
  if (filtered.isEmpty) {
    filtered = List<Map<String, dynamic>>.from(kDefaultWalletFundingMethods);
  } else {
    filtered = ensureQPayInWalletMethods(filtered);
  }
  return sortWalletFundingMethods(filtered);
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
  required String currency,
  required int walletId,
  Map<String, dynamic>? paymentDetails,
}) {
  return {
    'wallet_id': walletId,
    'amount': amount,
    'currency': currency,
    'payment_method_code': paymentMethodCode,
    'payment_details': paymentDetails ?? {},
  };
}
