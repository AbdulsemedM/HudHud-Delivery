import 'delivery_estimate.dart';

/// Result of parallel placeholder estimates for booking vehicle cards.
class CourierVehicleEstimateSet {
  const CourierVehicleEstimateSet({
    required this.visibleIds,
    required this.byVehicle,
  });

  /// Vehicle ids with a valid quote, in [requestedIds] order.
  final List<String> visibleIds;

  /// Valid quotes only.
  final Map<String, DeliveryEstimate> byVehicle;
}

/// Keeps requested ids that have a valid quote. [alwaysVisible] ids stay even
/// without a quote (defaults to none — catalog comes from service-areas).
CourierVehicleEstimateSet mergeCourierVehicleEstimates({
  required List<String> requestedIds,
  required Map<String, DeliveryEstimate?> quotes,
  Set<String> alwaysVisible = const {},
}) {
  final visible = <String>[];
  final kept = <String, DeliveryEstimate>{};
  for (final id in requestedIds) {
    final quote = quotes[id];
    if (quote != null && quote.isValid) {
      visible.add(id);
      kept[id] = quote;
    } else if (alwaysVisible.contains(id)) {
      visible.add(id);
    }
  }
  return CourierVehicleEstimateSet(visibleIds: visible, byVehicle: kept);
}

/// Fetches placeholder estimates in parallel, then applies [mergeCourierVehicleEstimates].
Future<CourierVehicleEstimateSet> fetchCourierEstimatesForVehicles({
  required List<String> vehicleIds,
  required Future<Map<String, dynamic>> Function(String vehicleId)
      estimateForVehicle,
  Set<String> alwaysVisible = const {},
}) async {
  final entries = await Future.wait(
    vehicleIds.map((id) async {
      try {
        final raw = await estimateForVehicle(id);
        return MapEntry(id, deliveryEstimateFromRepositoryResult(raw));
      } catch (_) {
        return MapEntry<String, DeliveryEstimate?>(id, null);
      }
    }),
  );

  final quotes = <String, DeliveryEstimate?>{
    for (final e in entries) e.key: e.value,
  };
  return mergeCourierVehicleEstimates(
    requestedIds: vehicleIds,
    quotes: quotes,
    alwaysVisible: alwaysVisible,
  );
}
