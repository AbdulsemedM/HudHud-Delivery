import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

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
    final dark = HomeColors.isDark(context);
    final circleSize = compact ? 80.0 : 96.0;
    final iconSize = compact ? 38.0 : 46.0;
    final radius = BorderRadius.circular(24);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HomeColors.violetTintOf(context),
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            size: iconSize,
            color: HomeColors.violetOf(context),
          ),
        ),
        SizedBox(height: compact ? 16 : 20),
        Text(
          l10n.courierNoHistory,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 17 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.courierHistoryEmptySubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: HomeColors.textMutedOf(context),
          ),
        ),
        if (onPrimaryAction != null) ...[
          const SizedBox(height: 22),
          _EmptyStatePrimaryButton(
            label: primaryActionLabel ?? l10n.courierInstantTitle,
            onPressed: onPrimaryAction!,
          ),
        ],
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: compact ? 28 : 36,
        ),
        decoration: BoxDecoration(
          color: HomeColors.surfaceOf(context),
          borderRadius: radius,
          border: dark ? Border.all(color: HomeColors.borderOf(context)) : null,
        ),
        child: content,
      ),
    );
  }
}

class _EmptyStatePrimaryButton extends StatelessWidget {
  const _EmptyStatePrimaryButton(
      {required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: HomeColors.orange,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
