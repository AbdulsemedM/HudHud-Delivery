import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// Driver row with call and message actions for courier delivery tracking.
class DriverContactCard extends StatelessWidget {
  final String driverName;
  final String? details;
  final VoidCallback onMessage;
  final VoidCallback? onCall;
  final Color borderColor;

  /// Optional vehicle description (type / colour) shown under the name.
  final String? vehicle;

  /// Optional driver rating (0–5).
  final double? rating;

  const DriverContactCard({
    super.key,
    required this.driverName,
    required this.onMessage,
    required this.borderColor,
    this.onCall,
    this.details,
    this.vehicle,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(24);
    final muted = HomeColors.textMutedOf(context);
    final hasVehicle = vehicle != null && vehicle!.trim().isNotEmpty;
    final hasDetails = details != null && details!.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark ? BorderSide(color: borderColor) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: HomeColors.violetTintOf(context),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: HomeColors.violetOf(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                        if (hasVehicle) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.two_wheeler_rounded,
                                size: 16,
                                color: muted,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  vehicle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          hasDetails ? details! : 'Driver',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rating != null && rating! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ratingFilled.withValues(
                          alpha: dark ? 0.18 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusFull,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.ratingFilled,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: HomeColors.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onCall != null) ...[
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: onCall,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.successColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.call_rounded, size: 26),
                          label: const Text(
                            'Call',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: onMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: HomeColors.violetTintOf(context),
                          foregroundColor: HomeColors.violetOf(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 22),
                        label: const Text(
                          'Message',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
