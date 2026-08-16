/// Parsed GET /api/wallet payload.
class WalletBalance {
  const WalletBalance({
    required this.balance,
    required this.currency,
    this.id,
    this.lastUpdated,
  });

  final int? id;
  final double balance;
  final String currency;
  final String? lastUpdated;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      id: _parseInt(json['id']),
      balance: _parseDouble(json['balance']) ?? 0,
      currency: json['currency']?.toString() ?? 'ETB',
      lastUpdated: json['last_updated']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletBalance &&
          id == other.id &&
          balance == other.balance &&
          currency == other.currency &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(id, balance, currency, lastUpdated);
}

/// Unwraps `{ success, data: { balance, currency } }` or nested `data.wallet`.
WalletBalance parseWalletBalanceResponse(dynamic response) {
  final root = _asMap(response);
  if (root.isEmpty) {
    throw const FormatException('Invalid wallet balance response');
  }
  final nested = _asMap(root['data']);
  final wallet = _asMap(nested['wallet']);
  final payload = wallet.isNotEmpty
      ? wallet
      : (nested.isNotEmpty ? nested : root);
  if (!payload.containsKey('balance') &&
      !payload.containsKey('currency') &&
      !payload.containsKey('id')) {
    throw const FormatException('Invalid wallet balance response');
  }
  return WalletBalance.fromJson(payload);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
