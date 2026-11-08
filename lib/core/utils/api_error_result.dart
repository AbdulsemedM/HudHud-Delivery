/// Known API / payment error codes from the payment error contract.
const Set<String> kKnownApiErrorCodes = {
  'validation_error',
  'insufficient_balance',
  'payment_failed',
  'invalid_phone',
  'invalid_provider',
  'payment_method_unavailable',
  'order_not_found',
  'ride_not_found',
  'service_not_found',
  'delivery_not_found',
  'amount_mismatch',
  'SERVICE_COMING_SOON',
  'AUTH_ACCOUNT_LOCKED',
  'IDEMPOTENCY_CONFLICT',
  'DELIVERY_PAYMENT_RETRY_FAILED',
  'CITY_VEHICLE_NOT_SUPPORTED',
  'PICKUP_SERVICE_AREA_UNAVAILABLE',
  // Merchant store controls (StoreAvailabilityService / checkout pricing).
  'STORE_CLOSED',
  'STORE_PAUSED',
  'ITEM_SOLD_OUT',
  // Customer dues (CustomerDuesService::cashBlock).
  'OUTSTANDING_DUES',
  // One-city rule (CityScopeService).
  'CITY_OUTSIDE_SERVICE_AREA',
  'CITY_CROSS_MARKET',
  'CITY_MARKET_MISMATCH',
};

/// Server error codes the customer app explains in its own words.
const String kStoreClosedCode = 'STORE_CLOSED';
const String kStorePausedCode = 'STORE_PAUSED';
const String kItemSoldOutCode = 'ITEM_SOLD_OUT';
const String kOutstandingDuesCode = 'OUTSTANDING_DUES';
const String kCityOutsideCode = 'CITY_OUTSIDE_SERVICE_AREA';
const String kCityCrossMarketCode = 'CITY_CROSS_MARKET';
const String kCityMarketMismatchCode = 'CITY_MARKET_MISMATCH';

/// Structured parse of Laravel-style / payment API error envelopes.
class ApiErrorResult {
  const ApiErrorResult({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
    this.balance,
    this.requiredAmount,
    this.deficit,
    this.gatewayError,
    this.gatewayErrorCode,
    this.expectedAmount,
    this.providedAmount,
    this.amount,
    this.currency,
    this.productId,
    this.marketCode,
    this.storeStatus,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;
  final double? balance;
  final double? requiredAmount;
  final double? deficit;
  final String? gatewayError;
  final String? gatewayErrorCode;
  /// From payment amount-mismatch 422 (`expected_amount`).
  final double? expectedAmount;
  /// From payment amount-mismatch 422 (`provided_amount`).
  final double? providedAmount;

  /// `OUTSTANDING_DUES`: the amount owed and its currency.
  final double? amount;
  final String? currency;

  /// `ITEM_SOLD_OUT`: the product to remove from the cart.
  final int? productId;

  /// `CITY_MARKET_MISMATCH`: the city (market code) the points are in.
  final String? marketCode;

  /// `STORE_CLOSED` / `STORE_PAUSED`: the raw `store_status` block.
  final Map<String, dynamic>? storeStatus;

  bool get isStoreClosed => code == kStoreClosedCode;
  bool get isStorePaused => code == kStorePausedCode;

  /// The store cannot take an order right now (closed or busy).
  bool get isStoreUnavailable => isStoreClosed || isStorePaused;
  bool get isItemSoldOut => code == kItemSoldOutCode;
  bool get isOutstandingDues => code == kOutstandingDuesCode;

  /// One of the three one-city (`CITY_*`) refusals.
  bool get isCityScopeError =>
      code == kCityOutsideCode ||
      code == kCityCrossMarketCode ||
      code == kCityMarketMismatchCode;

  bool get isInsufficientBalance =>
      code == 'insufficient_balance' ||
      (balance != null && requiredAmount != null);

  bool get isGatewayError =>
      code == 'payment_failed' ||
      (gatewayError != null && gatewayError!.isNotEmpty);

  bool get isValidation =>
      code == 'validation_error' || fieldErrors.isNotEmpty;

  /// Payment amount does not match the stored delivery/order total.
  bool get isAmountMismatch {
    if (expectedAmount != null && providedAmount != null) return true;
    if (code == 'amount_mismatch') return true;
    final lower = message.toLowerCase();
    return statusCode == 422 &&
        lower.contains('payment amount') &&
        lower.contains('does not match');
  }

  /// Delivery retry-payment provider initiation failed (stable error code).
  bool get isDeliveryPaymentRetryFailed =>
      code == 'DELIVERY_PAYMENT_RETRY_FAILED' ||
      gatewayErrorCode == 'DELIVERY_PAYMENT_RETRY_FAILED';

  /// Route distance could not be resolved (503 `ROUTE_DISTANCE_*`).
  bool get isRouteDistanceError {
    if (_isRouteDistanceCode(code) || _isRouteDistanceCode(gatewayErrorCode)) {
      return true;
    }
    if (statusCode == 503) {
      final lower = message.toLowerCase();
      if (lower.contains('route_distance') || lower.contains('route distance')) {
        return true;
      }
    }
    return false;
  }

  /// Pickup city does not support the requested vehicle type (422).
  bool get isCityVehicleNotSupported => code == 'CITY_VEHICLE_NOT_SUPPORTED';

  /// Pickup is not in an enabled configured delivery service area (422).
  bool get isPickupServiceAreaUnavailable =>
      code == 'PICKUP_SERVICE_AREA_UNAVAILABLE';

  /// Validation failed specifically on `scheduled_pickup`.
  bool get hasScheduledPickupValidation =>
      fieldErrors.containsKey('scheduled_pickup');

  /// Primary user-facing text, with balance/gateway enrichment when present.
  String get displayMessage {
    final fieldMessage = _joinedFieldMessages(fieldErrors);
    final base = (fieldMessage != null &&
            fieldMessage.isNotEmpty &&
            _isGenericValidationEnvelope(message))
        ? fieldMessage
        : message;

    final parts = <String>[base];

    if (fieldMessage != null &&
        fieldMessage.isNotEmpty &&
        !_isGenericValidationEnvelope(message) &&
        !base.contains(fieldMessage)) {
      parts.add(fieldMessage);
    }

    if (isAmountMismatch && expectedAmount != null) {
      final expected = _formatAmount(expectedAmount!);
      if (providedAmount != null) {
        parts.add(
          'Expected: $expected · Provided: ${_formatAmount(providedAmount!)}',
        );
      } else {
        parts.add('Updated amount: $expected');
      }
    }

    if (isInsufficientBalance &&
        balance != null &&
        requiredAmount != null) {
      parts.add(
        'Balance: ${_formatAmount(balance!)} · Required: ${_formatAmount(requiredAmount!)}',
      );
    }

    if (deficit != null && deficit! > 0) {
      parts.add('Short by: ${_formatAmount(deficit!)}');
    }

    // Never surface raw gateway / provider payloads to customers.

    return parts.join('\n');
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

/// Parses documented payment / API error payloads.
ApiErrorResult parseApiErrorResult(
  dynamic data, {
  int? statusCode,
  String fallback = 'An error occurred',
}) {
  if (data is String && data.trim().isNotEmpty) {
    return ApiErrorResult(
      message: data.trim(),
      statusCode: statusCode,
      code: _inferCodeFromStatus(statusCode),
    );
  }

  if (data is! Map) {
    return ApiErrorResult(
      message: fallback,
      statusCode: statusCode,
      code: _inferCodeFromStatus(statusCode),
    );
  }

  final root = Map<String, dynamic>.from(data);
  final nestedData = _asMap(root['data']);
  final fieldErrors = _parseFieldErrors(root['errors']);

  final topMessage = _stringMessage(root['message']);
  final fieldMessage = _joinedFieldMessages(fieldErrors);
  // Prefer concrete field errors over generic envelopes like "Validation Error".
  final primaryMessage = (fieldMessage != null &&
          fieldMessage.isNotEmpty &&
          (topMessage == null ||
              topMessage.isEmpty ||
              _isGenericValidationEnvelope(topMessage)))
      ? fieldMessage
      : ((topMessage != null && topMessage.isNotEmpty)
          ? topMessage
          : (fieldMessage ?? fallback));

  final balance = _parseDouble(nestedData['balance'] ?? root['balance']);
  final requiredAmount =
      _parseDouble(nestedData['required'] ?? root['required']);
  final deficit = _parseDouble(nestedData['deficit'] ?? root['deficit']);
  final expectedAmount = _parseDouble(
    nestedData['expected_amount'] ?? root['expected_amount'],
  );
  final providedAmount = _parseDouble(
    nestedData['provided_amount'] ?? root['provided_amount'],
  );
  final gatewayError = _firstNonEmptyString([
    nestedData['gateway_error'],
    root['gateway_error'],
  ]);
  final gatewayErrorCode = _firstNonEmptyString([
    nestedData['error_code'],
    root['error_code'],
  ]);
  final amount = _parseDouble(root['amount'] ?? nestedData['amount']);
  final currency = _firstNonEmptyString([
    root['currency'],
    nestedData['currency'],
  ])?.toUpperCase();
  final productIdRaw = _parseDouble(
    root['product_id'] ?? nestedData['product_id'],
  );
  final market = root['market'] ?? nestedData['market'];
  final marketCode = market is String && market.trim().isNotEmpty
      ? market.trim().toLowerCase()
      : null;
  final storeStatusRaw = _asMap(root['store_status']);

  // First candidate that is a usable code: a free-text `error` (debug
  // message) no longer hides a real `code` next to it.
  String? code;
  for (final candidate in [
    root['error'],
    root['code'],
    nestedData['error'],
    nestedData['code'],
  ]) {
    final text = candidate?.toString().trim();
    if (text == null || text.isEmpty) continue;
    code = _normalizeCode(text);
    if (code != null) break;
  }

  // Provider `error_code` (e.g. DECLINED) is not the app error code unless known.
  final providerErrorCode = _firstNonEmptyString([
    root['error_code'],
    nestedData['error_code'],
  ]);
  if (code == null &&
      providerErrorCode != null &&
      kKnownApiErrorCodes.contains(providerErrorCode)) {
    code = providerErrorCode;
  }

  code ??= _inferCode(
    statusCode: statusCode,
    message: primaryMessage,
    fieldErrors: fieldErrors,
    balance: balance,
    requiredAmount: requiredAmount,
    expectedAmount: expectedAmount,
    providedAmount: providedAmount,
    gatewayError: gatewayError,
    gatewayErrorCode: gatewayErrorCode,
  );

  return ApiErrorResult(
    message: primaryMessage,
    code: code,
    statusCode: statusCode,
    fieldErrors: fieldErrors,
    balance: balance,
    requiredAmount: requiredAmount,
    deficit: deficit,
    gatewayError: gatewayError,
    gatewayErrorCode: gatewayErrorCode,
    expectedAmount: expectedAmount,
    providedAmount: providedAmount,
    amount: amount,
    currency: currency,
    productId: productIdRaw?.toInt(),
    marketCode: marketCode,
    storeStatus: storeStatusRaw.isEmpty ? null : storeStatusRaw,
  );
}

String? _inferCode({
  int? statusCode,
  required String message,
  required Map<String, List<String>> fieldErrors,
  double? balance,
  double? requiredAmount,
  double? expectedAmount,
  double? providedAmount,
  String? gatewayError,
  String? gatewayErrorCode,
}) {
  final lower = message.toLowerCase();

  if (expectedAmount != null && providedAmount != null) {
    return 'amount_mismatch';
  }
  if (lower.contains('payment amount') && lower.contains('does not match')) {
    return 'amount_mismatch';
  }
  if (balance != null && requiredAmount != null) {
    return 'insufficient_balance';
  }
  if (lower.contains('insufficient') && lower.contains('balance')) {
    return 'insufficient_balance';
  }
  if (gatewayError != null ||
      (gatewayErrorCode != null && gatewayErrorCode.isNotEmpty)) {
    return 'payment_failed';
  }
  if (lower.contains('invalid phone') || lower.contains('phone number format')) {
    return 'invalid_phone';
  }
  if (lower.contains('provider') && lower.contains('invalid')) {
    return 'invalid_provider';
  }
  if (lower.contains('unavailable') && lower.contains('payment method')) {
    return 'payment_method_unavailable';
  }
  if (fieldErrors.isNotEmpty || statusCode == 422) {
    return 'validation_error';
  }
  if (statusCode == 503 &&
      (lower.contains('route_distance') || lower.contains('route distance'))) {
    return 'ROUTE_DISTANCE_UNAVAILABLE';
  }
  if (statusCode == 404) {
    if (lower.contains('ride')) return 'ride_not_found';
    if (lower.contains('service')) return 'service_not_found';
    if (lower.contains('delivery')) return 'delivery_not_found';
    if (lower.contains('order')) return 'order_not_found';
  }
  return _inferCodeFromStatus(statusCode);
}

/// Keeps known ids, stable SCREAMING_SNAKE API codes (STORE_CLOSED,
/// FEATURE_DISABLED, PARCEL_QUOTE_EXPIRED, …) and lowercase snake_case ids;
/// folds an upper-case alias of a known id onto it; drops anything else
/// (free text, provider strings) so it is never shown or matched.
String? _normalizeCode(String code) {
  if (kKnownApiErrorCodes.contains(code)) return code;
  final lower = code.toLowerCase();
  if (kKnownApiErrorCodes.contains(lower)) return lower;
  if (_isRouteDistanceCode(code) ||
      RegExp(r'^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$').hasMatch(code)) {
    return code;
  }
  if (RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(code)) return code;
  return null;
}

bool _isRouteDistanceCode(String? code) {
  if (code == null || code.isEmpty) return false;
  return code.toUpperCase().startsWith('ROUTE_DISTANCE');
}

String? _inferCodeFromStatus(int? statusCode) {
  switch (statusCode) {
    case 422:
      return 'validation_error';
    default:
      return null;
  }
}

Map<String, List<String>> _parseFieldErrors(dynamic errors) {
  if (errors is! Map) return const {};
  final result = <String, List<String>>{};
  errors.forEach((key, value) {
    final field = key.toString();
    if (value is List) {
      final msgs = value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (msgs.isNotEmpty) result[field] = msgs;
    } else if (value != null) {
      final text = value.toString();
      if (text.isNotEmpty) result[field] = [text];
    }
  });
  return result;
}

String? _joinedFieldMessages(Map<String, List<String>> fieldErrors) {
  if (fieldErrors.isEmpty) return null;
  final parts = <String>[];
  for (final entry in fieldErrors.entries) {
    for (final msg in entry.value) {
      parts.add(msg);
    }
  }
  if (parts.isEmpty) return null;
  return parts.join(' ');
}

bool _isGenericValidationEnvelope(String message) {
  final normalized = message.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'validation error' ||
      normalized == 'validation failed' ||
      normalized == 'the given data was invalid' ||
      normalized == 'the given data was invalid.';
}

String? _stringMessage(dynamic message) {
  if (message is String && message.isNotEmpty) return message;
  if (message is Map) {
    return _joinedFieldMessages(_parseFieldErrors(message));
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final c in candidates) {
    final s = c?.toString();
    if (s != null && s.isNotEmpty) return s;
  }
  return null;
}
