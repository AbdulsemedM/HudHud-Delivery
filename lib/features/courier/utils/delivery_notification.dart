/// Delivery lifecycle statuses, ordering, and notification deduplication helpers.

/// Canonical delivery lifecycle statuses from the Aug 2026 API handoff.
const deliveryLifecycleStatuses = [
  'pickup_assigned',
  'en_route_pickup',
  'at_pickup',
  'en_route_dropoff',
  'at_dropoff',
  'delivered',
];

/// Maps legacy/alternate status names to canonical lifecycle statuses.
const deliveryStatusAliases = {
  'rider_assigned': 'pickup_assigned',
  'courier_assigned': 'pickup_assigned',
  'driver_assigned': 'pickup_assigned',
  'assigned': 'pickup_assigned',
  'rider_en_route_pickup': 'en_route_pickup',
  'on_the_way_to_pickup': 'en_route_pickup',
  'rider_arrived_pickup': 'at_pickup',
  'arrived_at_pickup': 'at_pickup',
  'package_picked_up': 'en_route_dropoff',
  'delivery_started': 'en_route_dropoff',
  'in_transit': 'en_route_dropoff',
  'out_for_delivery': 'en_route_dropoff',
  'rider_nearby': 'en_route_dropoff',
  'rider_arrived_destination': 'at_dropoff',
  'arrived_at_dropoff': 'at_dropoff',
  'delivery_completed': 'delivered',
  'completed': 'delivered',
  'accepted': 'pickup_assigned',
};

/// Rank used to compare lifecycle progress (higher = further along).
int deliveryStatusRank(String? rawStatus) {
  final status = normalizeDeliveryStatus(rawStatus);
  if (status.isEmpty) return -1;

  const ranks = {
    'pending': 0,
    'pending_payment': 1,
    'searching': 2,
    'finding_courier': 2,
    'looking_for_courier': 2,
    'pickup_assigned': 10,
    'en_route_pickup': 20,
    'at_pickup': 30,
    'en_route_dropoff': 40,
    'at_dropoff': 50,
    'delivered': 60,
    'cancelled': 70,
    'canceled': 70,
    'failed': 65,
    'returned': 68,
  };

  return ranks[status] ?? -1;
}

/// True when the delivery is closed and OTP verification is no longer valid.
bool isDeliveryTerminalStatus(String? rawStatus) {
  final status = normalizeDeliveryStatus(rawStatus);
  return status == 'delivered' ||
      status == 'cancelled' ||
      status == 'canceled' ||
      status == 'failed' ||
      status == 'returned';
}

/// True once a driver has accepted and exact location may be shown.
bool isDeliveryAcceptedForTracking(String? rawStatus) {
  if (isDeliveryTerminalStatus(rawStatus)) return false;
  return deliveryStatusRank(rawStatus) >= 10;
}

/// True while nearest-first dispatch is still offering the job.
bool isDeliverySearchingForDriver(String? rawStatus) {
  if (isDeliveryAcceptedForTracking(rawStatus)) return false;
  if (isDeliveryTerminalStatus(rawStatus)) return false;
  final status = normalizeDeliveryStatus(rawStatus);
  const searching = {
    'searching',
    'pending',
    'pending_payment',
    'requested',
    'looking_for_driver',
    'looking_for_courier',
    'finding_courier',
    'created',
    'request_received',
  };
  return status.isEmpty || searching.contains(status);
}

/// Normalises a delivery status to lowercase snake_case with alias resolution.
String normalizeDeliveryStatus(String? rawStatus) {
  if (rawStatus == null || rawStatus.trim().isEmpty) return '';
  final normalized = rawStatus
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
  return deliveryStatusAliases[normalized] ?? normalized;
}

bool isDeliveryLifecycleStatus(String? rawStatus) {
  final status = normalizeDeliveryStatus(rawStatus);
  if (status.isEmpty) return false;
  return deliveryLifecycleStatuses.contains(status) ||
      deliveryStatusRank(status) >= deliveryStatusRank('pickup_assigned');
}

/// Returns true when [incoming] is older than the already-known [current] status.
bool isStaleDeliveryStatus(String? incoming, String? current) {
  final incomingRank = deliveryStatusRank(incoming);
  final currentRank = deliveryStatusRank(current);
  if (incomingRank < 0 || currentRank < 0) return false;
  return incomingRank < currentRank;
}

/// Dedup key for visible delivery notifications: delivery id + normalised status.
String? deliveryNotificationDedupKey(Map<String, String> data) {
  final deliveryId = _readDeliveryId(data);
  if (deliveryId == null) return null;

  final status = normalizeDeliveryStatus(
    data['new_status'] ?? data['status'] ?? data['event'] ?? data['type'],
  );
  if (status.isEmpty) {
    final type = data['type']?.trim().toLowerCase();
    if (type == 'otp_required') {
      return '${deliveryId}_otp_required';
    }
    final screen = data['screen']?.trim().toLowerCase();
    if (screen != null && screen.isNotEmpty) {
      return '${deliveryId}_$screen';
    }
    return '${deliveryId}_generic';
  }
  return '${deliveryId}_$status';
}

int? _readDeliveryId(Map<String, String> data) {
  for (final key in const ['delivery_id', 'deliveryId']) {
    final parsed = int.tryParse(data[key] ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

/// Keeps the newest notification per [deliveryNotificationDedupKey].
List<T> dedupeDeliveryNotificationsByKey<T>({
  required List<T> items,
  required Map<String, String> Function(T item) routingDataFor,
  required DateTime Function(T item) createdAtFor,
}) {
  final bestByKey = <String, T>{};

  for (final item in items) {
    final data = routingDataFor(item);
    final key = deliveryNotificationDedupKey(data);
    if (key == null) continue;

    final existing = bestByKey[key];
    if (existing == null ||
        createdAtFor(item).isAfter(createdAtFor(existing))) {
      bestByKey[key] = item;
    }
  }

  final dedupedIds = bestByKey.values.map((e) => e).toSet();
  final output = <T>[];

  for (final item in items) {
    final data = routingDataFor(item);
    final key = deliveryNotificationDedupKey(data);
    if (key == null) {
      output.add(item);
      continue;
    }
    if (dedupedIds.contains(item)) {
      output.add(item);
    }
  }

  return output;
}

/// Drops stale lifecycle notifications when a newer status exists for the same delivery.
List<T> filterStaleDeliveryNotifications<T>({
  required List<T> items,
  required Map<String, String> Function(T item) routingDataFor,
}) {
  final latestRankByDelivery = <int, int>{};

  for (final item in items) {
    final data = routingDataFor(item);
    final deliveryId = _readDeliveryId(data);
    if (deliveryId == null) continue;

    final rank = deliveryStatusRank(
      data['new_status'] ?? data['status'] ?? data['event'],
    );
    if (rank < 0) continue;

    final current = latestRankByDelivery[deliveryId] ?? -1;
    if (rank > current) {
      latestRankByDelivery[deliveryId] = rank;
    }
  }

  return items.where((item) {
    final data = routingDataFor(item);
    final deliveryId = _readDeliveryId(data);
    if (deliveryId == null) return true;

    final rank = deliveryStatusRank(
      data['new_status'] ?? data['status'] ?? data['event'],
    );
    if (rank < 0) return true;

    final latest = latestRankByDelivery[deliveryId] ?? rank;
    return rank >= latest;
  }).toList(growable: false);
}
