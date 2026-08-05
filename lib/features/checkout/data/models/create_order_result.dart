/// Parsed fields from POST /api/customer/orders success payload.
class CreateOrderResult {
  const CreateOrderResult({
    required this.orderId,
    this.totalAmount,
    this.currency,
    this.status,
    this.raw = const {},
  });

  final int orderId;
  final double? totalAmount;
  final String? currency;
  final String? status;
  final Map<String, dynamic> raw;

  bool get isValid => orderId > 0;
}

/// Unwraps API envelopes and extracts order_id / total_amount / currency.
///
/// Supports:
/// - `{ success, data: { order_id, total_amount, currency, status } }`
/// - `{ data: { order: { id, ... } } }`
/// - Flat `{ order_id, ... }` / `{ id, ... }`
CreateOrderResult parseCreateOrderResponse(
  dynamic response, {
  int fallbackOrderId = 0,
}) {
  final root = _asMap(response);
  if (root.isEmpty) {
    return CreateOrderResult(orderId: fallbackOrderId);
  }

  // Prefer nested `data` when present (common API envelope).
  final nestedData = _asMap(root['data']);
  Map<String, dynamic> payload = nestedData.isNotEmpty ? nestedData : root;

  // Prefer nested `order` object when present.
  final nestedOrder = _asMap(payload['order']);
  if (nestedOrder.isNotEmpty) {
    payload = {...payload, ...nestedOrder};
  }

  final orderId = _firstInt([
    payload['order_id'],
    payload['id'],
    nestedOrder['id'],
    nestedOrder['order_id'],
    root['order_id'],
  ]) ?? fallbackOrderId;

  final totalAmount = _firstDouble([
    payload['total_amount'],
    payload['total'],
    payload['amount'],
    nestedOrder['total_amount'],
  ]);

  final currency = _firstString([
    payload['currency'],
    nestedOrder['currency'],
  ]);

  final status = _firstString([
    payload['status'],
    nestedOrder['status'],
  ]);

  return CreateOrderResult(
    orderId: orderId,
    totalAmount: totalAmount,
    currency: currency,
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

/// Expected order status label after payment initiation (display only).
String expectedOrderStatusAfterPayment(String? paymentMethodCode) {
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
