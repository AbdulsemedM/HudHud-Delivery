import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  Color _statusColor(BuildContext context) {
    final normalized = status.toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'pending':
        return AppColors.pending;
      case 'confirmed':
        return AppColors.confirmed;
      case 'preparing':
        return AppColors.preparing;
      case 'on_the_way':
      case 'on the way':
        return AppColors.onTheWay;
      case 'delivered':
      case 'completed':
        return AppColors.delivered;
      case 'cancelled':
      case 'canceled':
        return AppColors.cancelled;
      default:
        return Theme.of(context).brightness == Brightness.dark
            ? AppColors.mutedDark
            : AppColors.mutedLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppColors.rFull),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
