import 'growth_json.dart';

/// `GET /api/customer/rewards/summary`
class RewardsSummary {
  final int points;
  final double value;
  final int redeemPoints;
  final double redeemValue;
  final int minRedeemPoints;
  final bool enabled;
  final List<RewardsHistoryEntry> history;

  const RewardsSummary({
    required this.points,
    required this.value,
    required this.redeemPoints,
    required this.redeemValue,
    required this.minRedeemPoints,
    required this.enabled,
    required this.history,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      points: growthInt(json['points']),
      value: growthDouble(json['value']),
      redeemPoints: growthInt(json['redeem_points'], 100),
      redeemValue: growthDouble(json['redeem_value']),
      minRedeemPoints: growthInt(json['min_redeem_points'], 100),
      enabled: growthBool(json['enabled']),
      history: growthList(json['history'])
          .map(growthMap)
          .whereType<Map<String, dynamic>>()
          .map(RewardsHistoryEntry.fromJson)
          .toList(),
    );
  }
}

class RewardsHistoryEntry {
  final int id;
  final int points;

  /// earned | redeemed | restored | expired
  final String type;
  final int? orderId;
  final String? note;
  final DateTime? createdAt;

  const RewardsHistoryEntry({
    required this.id,
    required this.points,
    required this.type,
    this.orderId,
    this.note,
    this.createdAt,
  });

  /// Points leaving the balance are shown as negative.
  bool get isDebit => type == 'redeemed' || type == 'expired';

  factory RewardsHistoryEntry.fromJson(Map<String, dynamic> json) {
    final created = growthString(json['created_at']);
    return RewardsHistoryEntry(
      id: growthInt(json['id']),
      points: growthInt(json['points']).abs(),
      type: (growthString(json['type']) ?? 'earned').toLowerCase(),
      orderId: growthIntOrNull(json['order_id']),
      note: growthString(json['note']),
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }
}
