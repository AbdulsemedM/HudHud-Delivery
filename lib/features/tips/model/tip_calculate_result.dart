class TipCalculateResult {
  final num amount;
  final num percentage;
  final int tipOptionId;
  final bool isCustom;

  const TipCalculateResult({
    required this.amount,
    required this.percentage,
    required this.tipOptionId,
    this.isCustom = false,
  });

  factory TipCalculateResult.fromJson(Map<String, dynamic> json) {
    return TipCalculateResult(
      amount: _parseNum(json['amount']),
      percentage: _parseNum(json['percentage']),
      tipOptionId: _parseInt(json['tip_option_id']) ?? 0,
      isCustom: json['is_custom'] == true,
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
