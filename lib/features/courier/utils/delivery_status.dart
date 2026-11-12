import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Resolves the display/lifecycle status for a delivery payload.
///
/// Prefers [status] (primary after cancel handoff). Uses [current_status] only
/// as a compatibility fallback when [status] is missing.
String? resolveDeliveryStatus(Map<String, dynamic>? delivery) {
  if (delivery == null) return null;
  final primary = delivery['status']?.toString().trim();
  if (primary != null && primary.isNotEmpty) return primary;
  final current = delivery['current_status']?.toString().trim();
  if (current != null && current.isNotEmpty) return current;
  return null;
}

/// Same as [resolveDeliveryStatus] with a non-null display fallback.
String resolveDeliveryStatusLabel(
  Map<String, dynamic>? delivery, {
  String fallback = '—',
}) {
  return resolveDeliveryStatus(delivery) ?? fallback;
}

/// Tracking-screen header for a delivery status.
///
/// Uses the lifecycle rank rather than substring matches: `pickup_assigned`
/// contains "pickup" but means the courier is still on the way, and
/// `cancelled` used to fall through to "Courier is coming".
String trackingHeadline(AppLocalizations l10n, String raw) {
  final status = normalizeDeliveryStatus(raw);
  if (status == 'cancelled' ||
      status == 'canceled' ||
      status == 'failed' ||
      status == 'returned') {
    return l10n.trackingStatusCancelled;
  }
  if (status == 'delivered' || status == 'done') {
    return l10n.trackingStatusDone;
  }
  if (status == 'at_pickup' || status == 'at_dropoff') {
    return l10n.trackingStatusArrived;
  }
  final rank = deliveryStatusRank(status);
  if (status == 'picked_up' || rank >= deliveryStatusRank('en_route_dropoff')) {
    return l10n.trackingStatusDelivering;
  }
  if (rank >= deliveryStatusRank('pickup_assigned')) {
    return l10n.trackingStatusOnTheWay;
  }
  if (isDeliverySearchingForDriver(status)) {
    return l10n.trackingStatusSearching;
  }
  return l10n.trackingStatusOnTheWay;
}
