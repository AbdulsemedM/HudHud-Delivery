import 'package:flutter/widgets.dart';

import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/wallet/data/wallet_topup_pending_store.dart';

/// Resumes pending wallet top-ups on launch and app resume.
class WalletTopUpRecoveryService extends ChangeNotifier
    with WidgetsBindingObserver {
  WalletTopUpRecoveryService._();

  static final WalletTopUpRecoveryService instance =
      WalletTopUpRecoveryService._();

  final WalletTopUpPendingStore _store = WalletTopUpPendingStore();
  late final PaymentRepository _paymentRepository = PaymentRepository(
    paymentDataProvider: PaymentDataProvider(apiService: ApiService.instance),
  );

  var _pendingCount = 0;
  var _initialized = false;

  int get pendingCount => _pendingCount;
  bool get hasPendingTopUp => _pendingCount > 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await refresh();
  }

  Future<void> refresh() async {
    final ids = await _store.readPendingPaymentIds();
    if (ids.isEmpty) {
      _setPendingCount(0);
      return;
    }

    final remaining = <int>[];
    for (final id in ids) {
      try {
        final status = await _paymentRepository.getPaymentStatus(id);
        if (status.isWalletTopUpSettled ||
            status.isWalletTopUpTerminalFailure ||
            status.isQpayFatalPollError) {
          await _store.removePendingPaymentId(id);
        } else {
          remaining.add(id);
        }
      } catch (_) {
        remaining.add(id);
      }
    }
    _setPendingCount(remaining.length);
  }

  void _setPendingCount(int count) {
    if (_pendingCount == count) return;
    _pendingCount = count;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
