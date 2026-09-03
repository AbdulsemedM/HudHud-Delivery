import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _pendingIdsKey = 'pending_wallet_topup_payment_ids';
const _lastPendingIdKey = 'last_pending_wallet_topup_payment_id';

/// Persists in-flight wallet top-up payment ids for recovery and resume.
class WalletTopUpPendingStore {
  WalletTopUpPendingStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<List<int>> readPendingPaymentIds() async {
    final raw = await _storage.read(key: _pendingIdsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int?> readLastPendingPaymentId() async {
    final raw = await _storage.read(key: _lastPendingIdKey);
    return int.tryParse(raw ?? '');
  }

  Future<void> addPendingPaymentId(int paymentId) async {
    if (paymentId <= 0) return;
    final ids = await readPendingPaymentIds();
    if (!ids.contains(paymentId)) {
      ids.add(paymentId);
    }
    await _writeIds(ids);
    await _storage.write(
      key: _lastPendingIdKey,
      value: paymentId.toString(),
    );
  }

  Future<void> removePendingPaymentId(int paymentId) async {
    final ids = await readPendingPaymentIds();
    ids.remove(paymentId);
    await _writeIds(ids);
    final last = await readLastPendingPaymentId();
    if (last == paymentId) {
      await _storage.delete(key: _lastPendingIdKey);
    }
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _pendingIdsKey);
    await _storage.delete(key: _lastPendingIdKey);
  }

  Future<void> _writeIds(List<int> ids) async {
    await _storage.write(
      key: _pendingIdsKey,
      value: jsonEncode(ids),
    );
  }
}
