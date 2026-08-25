class WalletTransactionModel {
  final int id;
  final String? amount;
  final String? type;
  final String? description;
  final String? createdAt;
  final String? currency;
  final double? balanceAfter;
  final Map<String, dynamic>? meta;

  const WalletTransactionModel({
    required this.id,
    this.amount,
    this.type,
    this.description,
    this.createdAt,
    this.currency,
    this.balanceAfter,
    this.meta,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: _parseInt(json['id']) ?? 0,
      amount: json['amount']?.toString(),
      type: json['type']?.toString(),
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString(),
      currency: json['currency']?.toString(),
      balanceAfter: _parseDouble(json['balance']),
      meta: json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double get amountValue => double.tryParse(amount ?? '0') ?? 0.0;

  bool get isCredit => type?.toLowerCase() == 'credit';
  bool get isDebit => type?.toLowerCase() == 'debit';
}

class WalletTransactionsResponse {
  final List<WalletTransactionModel> transactions;
  final int currentPage;
  final int lastPage;
  final int total;

  const WalletTransactionsResponse({
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

/// Parses documented `{ data: { transactions, meta } }` with Laravel fallback.
WalletTransactionsResponse parseWalletTransactionsResponse(dynamic response) {
  final root = _asMap(response);
  if (root.isEmpty) {
    return const WalletTransactionsResponse(
      transactions: [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
  }

  final inner = _asMap(root['data']);
  final payload = inner.isNotEmpty ? inner : root;
  final meta = _asMap(payload['meta']);

  final listRaw = payload['transactions'] ?? payload['data'];
  final List<WalletTransactionModel> transactions = [];
  if (listRaw is List) {
    for (final item in listRaw) {
      if (item is Map<String, dynamic>) {
        transactions.add(WalletTransactionModel.fromJson(item));
      } else if (item is Map) {
        transactions.add(
          WalletTransactionModel.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
  }

  final currentPage = _parseInt(
        meta['current_page'] ?? payload['current_page'],
      ) ??
      1;
  final lastPage = _parseInt(
        meta['total_pages'] ?? payload['last_page'],
      ) ??
      1;
  final total = _parseInt(
        meta['total_records'] ?? payload['total'],
      ) ??
      0;

  return WalletTransactionsResponse(
    transactions: transactions,
    currentPage: currentPage,
    lastPage: lastPage,
    total: total,
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
