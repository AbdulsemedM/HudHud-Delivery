import 'dart:math';

import '../api/api_service.dart';

/// Generates a RFC 4122 version-4 UUID (no external dependency).
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int value) => value.toRadixString(16).padLeft(2, '0');

  return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
      '${hex(bytes[4])}${hex(bytes[5])}-'
      '${hex(bytes[6])}${hex(bytes[7])}-'
      '${hex(bytes[8])}${hex(bytes[9])}-'
      '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}'
      '${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
}

/// Stable key for one logical payment attempt, e.g. `delivery-123-attempt-<uuid>`.
String createPaymentIdempotencyKey({
  required String type,
  required int entityId,
}) {
  final normalizedType = type.trim().isEmpty ? 'payment' : type.trim();
  return '$normalizedType-$entityId-attempt-${generateUuidV4()}';
}

/// Wallet mutation keys: `wallet-topup-<uuid>` / `withdraw-<uuid>`.
String createWalletIdempotencyKey({required String operation}) {
  final op = operation.trim().isEmpty ? 'wallet' : operation.trim();
  if (op == 'topup') {
    return 'wallet-topup-${generateUuidV4()}';
  }
  return '$op-${generateUuidV4()}';
}

/// True when the server rejected a reused Idempotency-Key with a different payload.
bool isIdempotencyConflictError(Object error) {
  final text = error is ApiException
      ? error.message
      : error.toString();
  final lower = text.toLowerCase();
  return lower.contains('idempotency') &&
      (lower.contains('already used') ||
          lower.contains('conflict') ||
          lower.contains('different payload'));
}

/// True for timeouts / connection failures where the same Idempotency-Key
/// should be reused on a safe retry (avoid duplicate gateway initiation).
bool isTransientPaymentNetworkError(Object error) {
  final text = error is ApiException
      ? error.message
      : error.toString();
  final lower = text.toLowerCase();
  return lower.contains('timeout') ||
      lower.contains('connection error') ||
      lower.contains('connection timeout');
}
