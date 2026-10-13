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
      case 'paid':
      case 'success':
      case 'successful':
        return AppColors.delivered;
      case 'unpaid':
      case 'awaiting_payment':
      case 'payment_pending':
        return AppColors.pending;
      case 'cancelled':
      case 'canceled':
      case 'failed':
      case 'rejected':
      case 'expired':
        return AppColors.cancelled;
      case 'active':
      case 'in_progress':
        return AppColors.infoColor;
      default:
        return AppColors.offline;
    }
  }

  /// "out_for_delivery" -> "Out for delivery".
  static String displayLabel(String status) {
    final t = status.replaceAll('_', ' ').trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = colorForStatus(status);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: dark ? 0.2 : 0.11),
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            displayLabel(status),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: dark ? Color.lerp(chipColor, Colors.white, 0.25) : chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
