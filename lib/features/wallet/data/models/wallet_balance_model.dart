/// Parsed GET /api/wallet payload.
class WalletBalance {
  const WalletBalance({
    required this.balance,
    required this.currency,
    this.lastUpdated,
  });

  final double balance;
  final String currency;
  final String? lastUpdated;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: _parseDouble(json['balance']) ?? 0,
      currency: json['currency']?.toString() ?? 'ETB',
      lastUpdated: json['last_updated']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletBalance &&
          balance == other.balance &&
          currency == other.currency &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(balance, currency, lastUpdated);
}

/// Unwraps `{ success, data: { balance, currency, last_updated } }`.
WalletBalance parseWalletBalanceResponse(dynamic response) {
  final root = _asMap(response);
  if (root.isEmpty) {
    return const WalletBalance(balance: 0, currency: 'ETB');
  }
  final nested = _asMap(root['data']);
  final payload = nested.isNotEmpty ? nested : root;
  return WalletBalance.fromJson(payload);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
