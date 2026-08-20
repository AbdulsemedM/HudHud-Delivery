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

  const DriverContactCard({
    super.key,
    required this.driverName,
    required this.onMessage,
    required this.borderColor,
    this.onCall,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: HomeColors.surface,
            child: Icon(
              Icons.person,
              size: 30,
              color: HomeColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (details == null || details!.isEmpty) ? 'Driver' : details!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: HomeColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onCall != null)
            IconButton(
              tooltip: 'Call',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: HomeColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: HomeColors.orange,
                ),
              ),
              onPressed: onCall,
            ),
          IconButton(
            tooltip: 'Message',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: HomeColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: HomeColors.textPrimary,
              ),
            ),
            onPressed: onMessage,
          ),
        ],
      ),
    );
  }
}
