import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:shimmer/shimmer.dart';

/// Horizontal booking card: vehicle, ETA, and “from” placeholder price.
class CourierVehicleEstimateCard extends StatelessWidget {
  const CourierVehicleEstimateCard({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
    this.estimate,
    this.etaMinutes,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;
  final DeliveryEstimate? estimate;
  final int? etaMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minutes = etaMinutes ?? estimate?.estimatedDuration;
    final cost = estimate?.estimatedCost;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 132,
        height: 148,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: isSelected
              ? HomeColors.violet.withValues(alpha: 0.12)
              : HomeColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(
            color: isSelected ? HomeColors.violet : HomeColors.borderOf(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? HomeColors.violet : HomeColors.textPrimaryOf(context),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeColors.textPrimaryOf(context),
                height: 1.2,
              ),
            ),
            const Spacer(),
            if (isLoading)
              Shimmer.fromColors(
                baseColor: HomeColors.surfaceElevatedOf(context),
                highlightColor: HomeColors.surfaceElevatedOf(context).withValues(alpha: 0.6),
                child: Container(
                  width: 72,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )
            else ...[
              Text(
                minutes != null ? l10n.courierEstimateMinutes(minutes) : '—',
                style: TextStyle(
                  fontSize: 12,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cost != null
                    ? l10n.courierEstimateFromPrice(
                        _currencySymbol(estimate?.currency ?? 'ETB'),
                        _formatAmount(cost),
                      )
                    : '—',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _currencySymbol(String currency) {
    return currency.toUpperCase() == 'ETB' ? 'Br' : currency;
  }

  static String _formatAmount(double cost) {
    if (cost == cost.roundToDouble()) {
      return cost.toStringAsFixed(0);
    }
    return cost.toStringAsFixed(2);
  }
}
