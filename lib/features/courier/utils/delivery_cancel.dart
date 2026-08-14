/// Whether a courier delivery can still be cancelled by the customer.
///
/// Cancellation is blocked once the package is picked up (and for terminal
/// delivered / cancelled states).
bool canCancelCourierDelivery(String? status) {
  if (status == null || status.trim().isEmpty) return true;

  final normalized = status.toLowerCase().trim().replaceAll(' ', '_');

  const blockedExact = {
    'picked_up',
    'in_transit',
    'out_for_delivery',
    'delivered',
    'completed',
    'cancelled',
    'canceled',
  };

  if (blockedExact.contains(normalized)) return false;

  if (normalized.contains('picked_up') ||
      normalized.contains('in_transit') ||
      normalized.contains('out_for_delivery') ||
      normalized.contains('delivered') ||
      normalized.contains('completed') ||
      normalized.contains('cancel')) {
    return false;
  }

  return true;
}
