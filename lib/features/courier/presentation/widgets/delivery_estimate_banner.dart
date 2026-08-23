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
    final theme = Theme.of(context);
    const borderColor = HomeColors.border;

    final metaParts = <String>[];
    if (estimatedDistance != null) {
      metaParts.add('${estimatedDistance!.toStringAsFixed(1)} km');
    }
    if (estimatedDuration != null) {
      metaParts.add('${estimatedDuration!} min');
    }
    final metaText = metaParts.isEmpty ? null : metaParts.join(' · ');

    String costText = '—';
    if (!isLoading && error == null && estimatedCost != null) {
      costText = '$currency ${estimatedCost!.toStringAsFixed(2)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.labelEstimatedCost,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: HomeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on 1 kg package',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: HomeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Shimmer.fromColors(
                    baseColor: HomeColors.surfaceElevated,
                    highlightColor:
                        HomeColors.surfaceElevated.withValues(alpha: 0.6),
                    child: Container(
                      width: 88,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                else
                  Text(
                    costText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: HomeColors.violet,
                    ),
                  ),
              ],
            ),
            if (metaText != null && !isLoading && error == null) ...[
              const SizedBox(height: 8),
              Text(
                metaText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: HomeColors.textMuted,
                ),
              ),
            ],
            if (error != null && !isLoading) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
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
