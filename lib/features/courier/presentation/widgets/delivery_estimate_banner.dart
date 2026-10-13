import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:shimmer/shimmer.dart';

/// Server estimate summary shown on location/vehicle selection screens.
class DeliveryEstimateBanner extends StatelessWidget {
  const DeliveryEstimateBanner({
    super.key,
    required this.isVisible,
    required this.isLoading,
    this.error,
    this.estimatedCost,
    this.estimatedDistance,
    this.estimatedDuration,
    this.currency = 'ETB',
  });

  final bool isVisible;
  final bool isLoading;
  final String? error;
  final double? estimatedCost;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final hasError = error != null && !isLoading;

    String costText = '—';
    if (!isLoading && error == null && estimatedCost != null) {
      costText = '$currency ${estimatedCost!.toStringAsFixed(2)}';
    }

    final showMeta = !isLoading && error == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: dark ? Border.all(color: HomeColors.borderOf(context)) : null,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasError
                        ? AppColors.errorColor.withValues(alpha: 0.12)
                        : (dark
                            ? AppColors.orangeTintDark
                            : AppColors.orangeTint),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.payments_rounded,
                    size: 26,
                    color: hasError ? AppColors.errorColor : HomeColors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.labelEstimatedCost,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: HomeColors.textMutedOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isLoading)
                        Shimmer.fromColors(
                          baseColor: HomeColors.surfaceElevatedOf(context),
                          highlightColor: HomeColors.surfaceElevatedOf(context)
                              .withValues(alpha: 0.6),
                          child: Container(
                            width: 110,
                            height: 26,
                            decoration: BoxDecoration(
                              color: HomeColors.surfaceElevatedOf(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      else
                        Text(
                          costText,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (showMeta) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (estimatedDistance != null)
                    _MetaPill(
                      icon: Icons.route_rounded,
                      text: '${estimatedDistance!.toStringAsFixed(1)} km',
                    ),
                  if (estimatedDuration != null)
                    _MetaPill(
                      icon: Icons.schedule_rounded,
                      text: '${estimatedDuration!} min',
                    ),
                  const _MetaPill(
                    icon: Icons.scale_rounded,
                    text: 'Based on 1 kg package',
                  ),
                ],
              ),
            ],
            if (hasError) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.errorColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HomeColors.violetTintOf(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: HomeColors.violetOf(context)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
