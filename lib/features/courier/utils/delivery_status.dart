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
