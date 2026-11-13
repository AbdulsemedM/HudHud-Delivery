import 'package:hudhud_delivery/features/courier/data/models/delivery_stop.dart';
import 'package:latlong2/latlong.dart';

/// All drop-offs of a booking in route order: stop 1 (the screen's normal
/// drop-off + recipient) followed by [extraStops].
List<DeliveryStopDraft> allDeliveryStops({
  required String firstLocation,
  required LatLng firstPosition,
  required String firstReceiverName,
  required String firstReceiverPhone,
  List<DeliveryStopDraft> extraStops = const [],
}) {
  return [
    DeliveryStopDraft(
      location: firstLocation,
      position: firstPosition,
      receiverName: firstReceiverName,
      receiverPhone: firstReceiverPhone,
    ),
    ...extraStops,
  ];
}

/// `stops` for `POST /services/delivery/estimate`, or null for a single
/// drop-off (then the body must not contain `stops`).
List<Map<String, dynamic>>? estimateStopsJson(List<DeliveryStopDraft> stops) {
  if (stops.length < 2) return null;
  return [
    for (var i = 0; i < stops.length; i++) stops[i].toEstimateJson(i + 1),
  ];
}

/// Adds multi-stop fields to a `POST /services/delivery/request` body in
/// place. No-op for a single drop-off, so single-stop bodies are unchanged.
///
/// Stop 1 stays in the top-level `receiver_*`; `dropoff_*` and
/// `delivery_address` move to the LAST stop (route end); `stops` lists all.
void applyMultiStopToRequestBody(
  Map<String, dynamic> body,
  List<DeliveryStopDraft> stops, {
  String Function(String)? normalizePhone,
}) {
  if (stops.length < 2) return;
  final last = stops.last;
  body['dropoff_location'] = last.location;
  body['dropoff_latitude'] = last.position.latitude;
  body['dropoff_longitude'] = last.position.longitude;
  body['delivery_address'] = {
    'latitude': last.position.latitude,
    'longitude': last.position.longitude,
    'address': last.location,
  };
  body['stops'] = [
    for (var i = 0; i < stops.length; i++)
      stops[i].toRequestJson(i + 1, normalizePhone: normalizePhone),
  ];
}
