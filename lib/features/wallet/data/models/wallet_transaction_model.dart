class WalletTransactionModel {
  final int id;
  final String? amount;
  final String? type;
  final String? description;
  final String? createdAt;
  final String? currency;
  final Map<String, dynamic>? meta;

  const WalletTransactionModel({
    required this.id,
    this.amount,
    this.type,
    this.description,
    this.createdAt,
    this.currency,
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
      meta: json['meta'] is Map<String, dynamic> ? json['meta'] as Map<String, dynamic> : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double get amountValue => double.tryParse(amount ?? '0') ?? 0.0;
}
