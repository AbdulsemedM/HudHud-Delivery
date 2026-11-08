import 'growth_json.dart';

/// `GET /api/customer/growth/referral-summary`
class ReferralSummary {
  final String referralCode;
  final String? referralLink;
  final String? shareUrl;
  final String? shareText;
  final bool enabled;
  final double rewardAmount;
  final int maxPerUser;
  final int invited;
  final int rewarded;
  final int pending;
  final double earnedTotal;
  final bool pendingVerification;

  const ReferralSummary({
    required this.referralCode,
    this.referralLink,
    this.shareUrl,
    this.shareText,
    required this.enabled,
    required this.rewardAmount,
    required this.maxPerUser,
    required this.invited,
    required this.rewarded,
    required this.pending,
    required this.earnedTotal,
    required this.pendingVerification,
  });

  bool get hasCode => referralCode.isNotEmpty;

  /// Link used in the share sheet (prefers the Phase 2 `share_url`).
  String? get bestLink => shareUrl ?? referralLink;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final stats = growthMap(json['stats']) ?? const {};
    return ReferralSummary(
      referralCode: growthString(json['referral_code']) ?? '',
      referralLink: growthString(json['referral_link']),
      shareUrl: growthString(json['share_url']),
      shareText: growthString(json['share_text']),
      // Legacy responses have no `enabled`; treat as off.
      enabled: growthBool(json['enabled']),
      rewardAmount: growthDouble(json['reward_amount']),
      maxPerUser: growthInt(json['max_per_user']),
      invited: growthInt(stats['invited']),
      rewarded: growthInt(stats['rewarded']),
      pending: growthInt(stats['pending']),
      earnedTotal: growthDouble(stats['earned_total']),
      pendingVerification: growthBool(json['pending_verification']),
    );
  }
}
