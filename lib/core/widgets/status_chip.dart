import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
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

  /// Translated label for food-order and parcel statuses; unknown statuses
  /// fall back to [displayLabel].
  static String localizedLabel(BuildContext context, String status) =>
      localizedLabelFor(context.l10n, status);

  static String localizedLabelFor(AppLocalizations l10n, String status) {
    final raw = status.trim().toLowerCase().replaceAll(' ', '_');
    switch (raw) {
      case 'pending':
        return l10n.orderStatusPending;
      case 'confirmed':
        return l10n.orderStatusConfirmed;
      case 'preparing':
        return l10n.orderStatusPreparing;
      case 'ready':
      case 'ready_for_pickup':
        return l10n.orderStatusReadyForPickup;
      case 'out_for_delivery':
        return l10n.orderStatusOutForDelivery;
      case 'in_progress':
        return l10n.courierDeliveryStatusInProgress;
    }
    switch (normalizeDeliveryStatus(raw)) {
      case 'searching':
      case 'finding_courier':
      case 'looking_for_courier':
        return l10n.deliveryStatusSearching;
      case 'pickup_assigned':
        return l10n.deliveryStatusAssigned;
      case 'en_route_pickup':
        return l10n.deliveryStatusToPickup;
      case 'at_pickup':
        return l10n.deliveryStatusAtPickup;
      case 'en_route_dropoff':
      case 'picked_up':
        return l10n.deliveryStatusOnTheWay;
      case 'at_dropoff':
        return l10n.deliveryStatusAtDropoff;
      case 'delivered':
        return l10n.orderStatusDelivered;
      case 'cancelled':
      case 'canceled':
        return l10n.orderStatusCancelled;
      case 'failed':
        return l10n.deliveryStatusFailed;
      case 'returned':
        return l10n.deliveryStatusReturned;
    }
    return displayLabel(status);
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
            localizedLabel(context, status),
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
