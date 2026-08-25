class WishlistPriceDropModel {
  final int productId;
  final String? productName;
  final String? originalPrice;
  final String? currentPrice;
  final bool hasDropped;
  final num dropPercentage;
  final num savings;

  const WishlistPriceDropModel({
    required this.productId,
    this.productName,
    this.originalPrice,
    this.currentPrice,
    this.hasDropped = false,
    this.dropPercentage = 0,
    this.savings = 0,
  });

  factory WishlistPriceDropModel.fromJson(Map<String, dynamic> json) {
    return WishlistPriceDropModel(
      productId: _parseInt(json['product_id']) ?? 0,
      productName: json['product_name']?.toString(),
      originalPrice: json['original_price']?.toString(),
      currentPrice: json['current_price']?.toString(),
      hasDropped: json['has_dropped'] == true,
      dropPercentage: _parseNum(json['drop_percentage']),
      savings: _parseNum(json['savings']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }
}
