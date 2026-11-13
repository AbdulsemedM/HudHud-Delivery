import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../cancellation_policy_controller.dart';
import '../data/cancellation_models.dart';
import 'cancellation_standing_screen.dart';

/// Colour for a points total: green below half the fine line, amber up to
/// it, red at / over it.
Color cancellationPointsColor(int points, int fineThreshold) {
  if (points >= fineThreshold) return AppColors.errorColor;
  if (points * 2 >= fineThreshold) return AppColors.warningColor;
  return AppColors.successColor;
}

/// Horizontal 0 → [banThreshold] meter with a "Fine" tick and a "Pause" end.
/// When [pointsAfter] > [points] the extra part (what this cancel would
/// add) is drawn hatched-light on top.
class CancellationPointsMeter extends StatelessWidget {
  const CancellationPointsMeter({
    super.key,
    required this.points,
    required this.fineThreshold,
    required this.banThreshold,
    this.pointsAfter,
  });

  final int points;
  final int? pointsAfter;
  final int fineThreshold;
  final int banThreshold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final max = banThreshold <= 0 ? 100 : banThreshold;
    final after = (pointsAfter ?? points).clamp(0, max);
    final now = points.clamp(0, max);
    final shown = after > now ? after : now;
    final color = cancellationPointsColor(shown, fineThreshold);
    final finePos = (fineThreshold / max).clamp(0.0, 1.0);
    final limit = shown < fineThreshold ? fineThreshold : banThreshold;

    return Semantics(
      label: l10n.cpPointsOfLimit(shown, limit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                l10n.cpPointsOfLimit(shown, limit),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return SizedBox(
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: HomeColors.borderOf(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    if (after > now)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: w * after / max,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color, width: 1.5),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: w * now / max,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // Fine tick.
                    Positioned(
                      left: (w * finePos - 1).clamp(0.0, w - 2),
                      top: -3,
                      child: Container(
                        width: 2,
                        height: 18,
                        color: HomeColors.textPrimaryOf(context),
                      ),
                    ),
                    Positioned(
                      left: (w * finePos - 30).clamp(0.0, w - 60),
                      top: 17,
                      width: 60,
                      child: Text(
                        '${l10n.cpMarkerFine} $fineThreshold',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: HomeColors.textMutedOf(context),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 17,
                      child: Text(
                        '${l10n.cpMarkerPause} $banThreshold',
                        style: TextStyle(
                          fontSize: 11,
                          color: HomeColors.textMutedOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Short title for a standing status.
String cancellationStatusTitle(
  BuildContext context,
  CancellationStandingStatus status,
) {
  final l10n = context.l10n;
  switch (status) {
    case CancellationStandingStatus.good:
      return l10n.cpStandingGood;
    case CancellationStandingStatus.warning:
      return l10n.cpStandingWarning;
    case CancellationStandingStatus.fineDue:
      return l10n.cpStandingFineDue;
    case CancellationStandingStatus.suspended:
      return l10n.cpStandingSuspended;
  }
}

IconData cancellationStatusIcon(CancellationStandingStatus status) {
  switch (status) {
    case CancellationStandingStatus.good:
      return Icons.verified_rounded;
    case CancellationStandingStatus.warning:
      return Icons.warning_amber_rounded;
    case CancellationStandingStatus.fineDue:
      return Icons.receipt_long_rounded;
    case CancellationStandingStatus.suspended:
      return Icons.block_rounded;
  }
}

Color cancellationStatusColor(CancellationStandingStatus status) {
  switch (status) {
    case CancellationStandingStatus.good:
      return AppColors.successColor;
    case CancellationStandingStatus.warning:
      return AppColors.warningColor;
    case CancellationStandingStatus.fineDue:
    case CancellationStandingStatus.suspended:
      return AppColors.errorColor;
  }
}

/// Banner shown on booking surfaces (courier home, checkout) when the
/// customer is close to / over a penalty line. Invisible otherwise, and
/// invisible when the server has penalties switched off.
class CancellationStandingBanner extends StatefulWidget {
  const CancellationStandingBanner({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  final EdgeInsetsGeometry padding;

  @override
  State<CancellationStandingBanner> createState() =>
      _CancellationStandingBannerState();
}

class _CancellationStandingBannerState
    extends State<CancellationStandingBanner> {
  final _controller = CancellationPolicyController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final standing = _controller.standing;
    if (standing == null || !standing.needsAttention) {
      return const SizedBox.shrink();
    }
    final color = cancellationStatusColor(standing.status);
    final l10n = context.l10n;
    return Padding(
      padding: widget.padding,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CancellationStandingScreen(),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(cancellationStatusIcon(standing.status),
                      color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cancellationStatusTitle(context, standing.status),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                        Text(
                          l10n.cpPointsOfLimit(
                            standing.points,
                            standing.nextThreshold,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: HomeColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: HomeColors.textMutedOf(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
