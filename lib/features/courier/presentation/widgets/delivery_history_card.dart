import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Delivery row used on courier home history and the full history screen.
class DeliveryHistoryCard extends StatelessWidget {
  final String orderId;
  final String recipient;
  final String location;
  final String dateTime;
  final String status;
  final Color borderColor;
  final VoidCallback? onTap;

  const DeliveryHistoryCard({
    super.key,
    required this.orderId,
    required this.recipient,
    required this.location,
    required this.dateTime,
    required this.status,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusChip.colorForStatus(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          child: Container(
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                      ),
                      Text(
                        recipient,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HomeColors.textMuted,
                            ),
                      ),
                      Text(
                        dateTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HomeColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatDeliveryHistoryDate(dynamic value) {
  if (value == null) return '—';
  final str = value.toString();
  try {
    final dt = DateTime.tryParse(str);
    if (dt != null) {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  } catch (_) {}
  return str;
}
