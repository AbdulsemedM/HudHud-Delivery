/// History filter keys used by [CourierScreen].
const kDeliveryHistoryFilterAll = 'all';
const kDeliveryHistoryFilterActive = 'active';
const kDeliveryHistoryFilterCompleted = 'completed';
const kDeliveryHistoryFilterCancelled = 'cancelled';

String normalizeDeliveryStatus(String? raw) {
  return (raw ?? '').toLowerCase().trim().replaceAll(' ', '_');
}

bool isCancelledDeliveryStatus(String? raw) {
  final status = normalizeDeliveryStatus(raw);
  if (status.isEmpty) return false;
  return status == 'cancelled' ||
      status == 'canceled' ||
      status.contains('cancel');
}

bool isCompletedDeliveryStatus(String? raw) {
  final status = normalizeDeliveryStatus(raw);
  // Exact match only — do not use contains('deliver'), which wrongly
  // classifies active statuses like `out_for_delivery` as completed.
  return status == 'delivered' || status == 'completed';
}

bool isActiveDeliveryStatus(String? raw) {
  final status = normalizeDeliveryStatus(raw);
  if (status.isEmpty) return false;
  return !isCompletedDeliveryStatus(status) &&
      !isCancelledDeliveryStatus(status);
}

bool matchesDeliveryHistoryFilter(String? rawStatus, String filter) {
  switch (filter) {
    case kDeliveryHistoryFilterAll:
      return true;
    case kDeliveryHistoryFilterActive:
      return isActiveDeliveryStatus(rawStatus);
    case kDeliveryHistoryFilterCompleted:
      return isCompletedDeliveryStatus(rawStatus);
    case kDeliveryHistoryFilterCancelled:
      return isCancelledDeliveryStatus(rawStatus);
    default:
      return true;
  }
}
