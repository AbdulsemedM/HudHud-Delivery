class WalletModel {
  final int id;
  final String userId;
  final String currency;
  final String name;
  final String type;
  final bool isPlatformWallet;
  final String balance;
  final String? createdAt;
  final String? updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.currency,
    required this.name,
    required this.type,
    required this.isPlatformWallet,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: _parseInt(json['id']) ?? 0,
      userId: json['user_id']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'personal',
      isPlatformWallet: json['is_platform_wallet'] == true,
      balance: json['balance']?.toString() ?? '0',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double get balanceAmount => double.tryParse(balance) ?? 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'currency': currency,
        'name': name,
        'type': type,
        'is_platform_wallet': isPlatformWallet,
        'balance': balance,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
