import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';

import '../../data/growth_repository.dart';
import '../../data/models/referral_summary.dart';

/// "Invite friends, get 50 ETB" card. Renders nothing until the
/// referral summary loads with `enabled: true` and a code — so with the
/// feature off (or on any error) Profile looks exactly as before.
class ReferralCard extends StatefulWidget {
  const ReferralCard({super.key, this.repository, this.padding});

  final GrowthRepository? repository;

  /// Applied only when the card is visible.
  final EdgeInsetsGeometry? padding;

  @override
  State<ReferralCard> createState() => ReferralCardState();
}

class ReferralCardState extends State<ReferralCard> {
  late final GrowthRepository _repo =
      widget.repository ?? GrowthRepository.create();
  ReferralSummary? _summary;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    try {
      final summary = await _repo.fetchReferralSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (_) {
      if (!mounted) return;
      setState(() => _summary = null);
    }
  }

  Future<void> _copy(ReferralSummary s) async {
    await Clipboard.setData(ClipboardData(text: s.referralCode));
    if (!mounted) return;
    AuthSnackBar.success(context, context.l10n.growthReferralCopied);
  }

  void _share(ReferralSummary s) {
    final l10n = context.l10n;
    final text = s.shareText ??
        l10n.growthReferralShareFallback(
          formatEtbAmount(s.rewardAmount, fractionDigits: 0),
          s.referralCode,
          s.bestLink ?? '',
        );
    Share.share(text.trim(), subject: l10n.growthReferralShareSubject);
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    if (s == null || !s.enabled || !s.hasCode) return const SizedBox.shrink();
    final l10n = context.l10n;
    final reward = formatEtbAmount(s.rewardAmount, fractionDigits: 0);
    final dark = AuthScreenColors.isDark(context);
    final radius = BorderRadius.circular(20);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: AuthScreenColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark
              ? BorderSide(color: AuthScreenColors.surfaceBorderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.brandOrange
                          .withValues(alpha: dark ? 0.2 : 0.11),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.brandOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.growthReferralTitle(reward),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AuthScreenColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.growthReferralSubtitle(reward),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AuthScreenColors.textMutedOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.brandOrange.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        s.referralCode,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: AuthScreenColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _copy(s),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.growthReferralCopy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _share(s),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(l10n.growthReferralShare),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(label: l10n.growthReferralInvited, value: '${s.invited}'),
                  _Stat(
                    label: l10n.growthReferralRewarded,
                    value: '${s.rewarded}',
                  ),
                  _Stat(label: l10n.growthReferralPending, value: '${s.pending}'),
                  _Stat(
                    label: l10n.growthReferralEarned,
                    value: formatEtbAmount(s.earnedTotal, fractionDigits: 0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final padding = widget.padding;
    return padding == null ? card : Padding(padding: padding, child: card);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AuthScreenColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthScreenColors.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
