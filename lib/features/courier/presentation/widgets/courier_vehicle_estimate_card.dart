import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:shimmer/shimmer.dart';

/// Horizontal booking card: vehicle, ETA, and “from” placeholder price.
///
/// Picture-first choice tile. Selected = indigo border, indigo tint fill and
/// a small check badge in the corner.
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

  static const double width = 140;
  static const double height = 164;
  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minutes = etaMinutes ?? estimate?.estimatedDuration;
    final cost = estimate?.estimatedCost;
    final accent = HomeColors.violetOf(context);
    final tint = HomeColors.violetTintOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: isSelected ? const [] : AppColors.softShadow(context),
        ),
        child: Material(
          color: isSelected ? tint : HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(
              color: isSelected ? accent : HomeColors.borderOf(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? HomeColors.surfaceOf(context) : tint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, size: 30, color: accent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: HomeColors.textPrimaryOf(context),
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      if (isLoading)
                        Shimmer.fromColors(
                          baseColor: HomeColors.surfaceElevatedOf(context),
                          highlightColor: HomeColors.surfaceElevatedOf(context)
                              .withValues(alpha: 0.6),
                          child: Container(
                            width: 76,
                            height: 30,
                            decoration: BoxDecoration(
                              color: HomeColors.surfaceElevatedOf(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: HomeColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                minutes != null
                                    ? l10n.courierEstimateMinutes(minutes)
                                    : '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: HomeColors.textMutedOf(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cost != null
                              ? l10n.courierEstimateFromPrice(
                                  _currencySymbol(estimate?.currency ?? 'ETB'),
                                  _formatAmount(cost),
                                )
                              : '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
