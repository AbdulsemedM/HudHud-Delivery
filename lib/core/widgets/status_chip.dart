import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  static Color colorForStatus(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
        return AppColors.pending;
      case 'confirmed':
      case 'accepted':
        return AppColors.confirmed;
      case 'preparing':
        return AppColors.preparing;
      case 'on_the_way':
      case 'out_for_delivery':
      case 'picked_up':
      case 'ready_for_pickup':
        return AppColors.onTheWay;
      case 'delivered':
      case 'completed':
        return AppColors.delivered;
      case 'cancelled':
      case 'canceled':
        return AppColors.cancelled;
      case 'active':
      case 'in_progress':
        return AppColors.infoColor;
      default:
        return AppColors.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = colorForStatus(status);
    final displayStatus = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
        border: Border.all(color: chipColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}
