/// Parsed fields from POST /api/services/ride/request success payload.
class RideRequestResult {
  const RideRequestResult({
    required this.rideId,
    this.estimatedFare,
    this.currency,
    this.status,
    this.paymentStatus,
    this.raw = const {},
  });

  final int rideId;
  final double? estimatedFare;
  final String? currency;
  final String? status;
  final String? paymentStatus;
  final Map<String, dynamic> raw;

  bool get isValid => rideId > 0;
}

/// Unwraps API envelopes and extracts ride_id / estimated_fare / currency / payment_status.
///
/// Supports:
/// - `{ success, data: { ride_id, estimated_fare, currency, status, payment_status } }`
/// - `{ data: { ride: { id, ... } } }`
/// - Flat `{ ride_id, ... }` / `{ id, ... }`
RideRequestResult parseRideRequestResponse(
  dynamic response, {
  int fallbackRideId = 0,
}) {
  final root = _asMap(response);
  if (root.isEmpty) {
    return RideRequestResult(rideId: fallbackRideId);
  }

  final nestedData = _asMap(root['data']);
  Map<String, dynamic> payload = nestedData.isNotEmpty ? nestedData : root;

  final nestedRide = _asMap(payload['ride']);
  if (nestedRide.isNotEmpty) {
    payload = {...payload, ...nestedRide};
  }

  final rideId = _firstInt([
        payload['ride_id'],
        payload['id'],
        nestedRide['id'],
        nestedRide['ride_id'],
        root['ride_id'],
      ]) ??
      fallbackRideId;

  final estimatedFare = _firstDouble([
    payload['estimated_fare'],
    payload['fare'],
    payload['total_fare'],
    nestedRide['estimated_fare'],
  ]);

  final currency = _firstString([
    payload['currency'],
    nestedRide['currency'],
  ]);

  final status = _firstString([
    payload['status'],
    nestedRide['status'],
  ]);

  final paymentStatus = _firstString([
    payload['payment_status'],
    nestedRide['payment_status'],
  ]);

  return RideRequestResult(
    rideId: rideId,
    estimatedFare: estimatedFare,
    currency: currency,
    status: status,
    paymentStatus: paymentStatus,
    raw: payload,
  );
}

/// Parsed cancel-ride refund fields.
class RideCancelRefundResult {
  const RideCancelRefundResult({
    this.message,
    this.refundAmount,
    this.refundStatus,
    this.estimatedTime,
  });

  final String? message;
  final double? refundAmount;
  final String? refundStatus;
  final String? estimatedTime;

  bool get hasRefund => refundAmount != null && refundAmount! > 0;
}

RideCancelRefundResult parseRideCancelRefundResponse(dynamic response) {
  final root = _asMap(response);
  final data = _asMap(root['data']);
  final payload = data.isNotEmpty ? data : root;

  return RideCancelRefundResult(
    message: _firstString([
      root['message'],
      payload['message'],
    ]),
    refundAmount: _firstDouble([
      payload['refund_amount'],
      root['refund_amount'],
    ]),
    refundStatus: _firstString([
      payload['refund_status'],
      root['refund_status'],
    ]),
    estimatedTime: _firstString([
      payload['estimated_time'],
      root['estimated_time'],
    ]),
  );
}

/// User-facing cancel/refund snackbar or dialog text.
String formatRideCancelRefundMessage(RideCancelRefundResult refund) {
  final base = refund.message ?? 'Ride cancelled successfully.';
  if (!refund.hasRefund) return base;

  final amount = refund.refundAmount!.toStringAsFixed(2);
  final status = refund.refundStatus ?? 'processing';
  final eta = refund.estimatedTime;
  final buffer = StringBuffer(base);
  buffer.write(' Refund $amount — $status');
  if (eta != null && eta.isNotEmpty) {
    buffer.write(' ($eta)');
  }
  if (status == 'processing' || status == 'completed') {
    buffer.write('. Wallet balance will be restored when the refund completes.');
  }
  return buffer.toString();
}

/// Final fare from an active/completed ride payload.
double? parseRideFare(Map<String, dynamic> ride) {
  return _firstDouble([
    ride['total_fare'],
    ride['fare'],
    ride['final_fare'],
    ride['estimated_fare'],
  ]);
}

String parseRideCurrency(Map<String, dynamic> ride, {String fallback = 'KES'}) {
  return _firstString([ride['currency']]) ?? fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int? _firstInt(List<dynamic> candidates) {
  for (final c in candidates) {
    if (c == null) continue;
    final parsed = int.tryParse(c.toString());
    if (parsed != null && parsed > 0) return parsed;
  }
  return null;
}

double? _firstDouble(List<dynamic> candidates) {
  for (final c in candidates) {
    if (c == null) continue;
    if (c is num) return c.toDouble();
    final parsed = double.tryParse(c.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String? _firstString(List<dynamic> candidates) {
  for (final c in candidates) {
    final s = c?.toString();
    if (s != null && s.isNotEmpty) return s;
  }
  return null;
}
