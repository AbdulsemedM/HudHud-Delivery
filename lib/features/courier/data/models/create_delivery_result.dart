/// Parsed fields from POST /api/services/delivery/request success payload.
class CreateDeliveryResult {
  const CreateDeliveryResult({
    required this.deliveryId,
    this.totalAmount,
    this.currency,
    this.trackingNumber,
    this.status,
    this.raw = const {},
  });

  final int deliveryId;
  final double? totalAmount;
  final String? currency;
  final String? trackingNumber;
  final String? status;
  final Map<String, dynamic> raw;

  bool get isValid => deliveryId > 0;

  bool get isPendingPayment => status == 'pending_payment';
}

/// Unwraps API envelopes and extracts delivery_id / total_amount / currency.
///
/// Supports:
/// - `{ success, data: { delivery_id, total_amount, currency, tracking_number, status } }`
/// - `{ data: { delivery: { id, ... } } }`
/// - Flat `{ delivery_id, ... }` / `{ id, ... }` / `{ order_id, ... }`
CreateDeliveryResult parseCreateDeliveryResponse(
  dynamic response, {
  int fallbackDeliveryId = 0,
}) {
  final root = _asMap(response);
  if (root.isEmpty) {
    return CreateDeliveryResult(deliveryId: fallbackDeliveryId);
  }

  final nestedData = _asMap(root['data']);
  Map<String, dynamic> payload = nestedData.isNotEmpty ? nestedData : root;

  final nestedDelivery = _asMap(payload['delivery']);
  if (nestedDelivery.isNotEmpty) {
    payload = {...payload, ...nestedDelivery};
  }

  final deliveryId = _firstInt([
        payload['delivery_id'],
        payload['id'],
        payload['order_id'],
        nestedDelivery['id'],
        nestedDelivery['delivery_id'],
        root['delivery_id'],
        root['order_id'],
      ]) ??
      fallbackDeliveryId;

  final totalAmount = _firstDouble([
    payload['total_amount'],
    payload['estimated_cost'],
    payload['total'],
    payload['amount'],
    nestedDelivery['total_amount'],
    nestedDelivery['estimated_cost'],
  ]);

  final currency = _firstString([
    payload['currency'],
    nestedDelivery['currency'],
  ]);

  final trackingNumber = _firstString([
    payload['tracking_number'],
    payload['trackingNumber'],
    nestedDelivery['tracking_number'],
  ]);

  final status = _firstString([
    payload['status'],
    nestedDelivery['status'],
  ]);

  return CreateDeliveryResult(
    deliveryId: deliveryId,
    totalAmount: totalAmount,
    currency: currency,
    trackingNumber: trackingNumber,
    status: status,
    raw: payload,
  );
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

/// Expected delivery status label after payment initiation (display only).
String expectedDeliveryStatusAfterPayment(String? paymentMethodCode) {
  switch (paymentMethodCode) {
    case 'wallet':
      return 'paid';
    case 'cash_on_delivery':
      return 'confirmed';
    case 'waafi':
    case 'edahab':
    case 'sahay':
    case 'ebirr':
      return 'processing';
    default:
      return 'processing';
  }
}
