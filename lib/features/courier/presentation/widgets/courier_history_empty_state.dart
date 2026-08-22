import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

/// Empty delivery-history panel for Home courier and full history screens.
class CourierHistoryEmptyState extends StatelessWidget {
  const CourierHistoryEmptyState({
    super.key,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.compact = true,
  });

  /// Optional CTA (e.g. start instant delivery).
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  /// Home preview uses compact layout; full history uses a larger icon.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final iconSize = compact ? 40.0 : 52.0;
    final circleSize = compact ? 80.0 : 112.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppColors.spaceMD,
        vertical: compact ? 28 : 36,
      ),
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: HomeColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HomeColors.violet.withValues(alpha: 0.22),
                  AuthScreenColors.orange.withValues(alpha: 0.14),
                ],
              ),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: iconSize,
              color: HomeColors.violet.withValues(alpha: 0.95),
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          Text(
            l10n.courierNoHistory,
            textAlign: TextAlign.center,
            style: (compact
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.titleMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: HomeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.courierHistoryEmptySubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: HomeColors.textMuted,
              height: 1.4,
            ),
          ),
          if (onPrimaryAction != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(
                  primaryActionLabel ?? l10n.courierInstantTitle,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AuthScreenColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
