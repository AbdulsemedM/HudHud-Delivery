import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/payment/data/data_provider/payment_data_provider.dart';
import '../../features/payment/data/repository/payment_repository.dart';
import '../../features/payment/model/payment_status_result.dart';
import '../api/api_service.dart';

typedef PaymentStatusCallback = void Function(PaymentStatusResult result);

/// Adaptive poll schedule for wallet top-ups: 3s for 30s, then 10s up to 5 min.
class PaymentPoller {
  PaymentPoller({
    required this.paymentId,
    required this.onStatus,
    this.onTerminal,
    this.onFatalError,
    this.onTimeout,
    PaymentRepository? paymentRepository,
    WidgetsBinding? binding,
  })  : _paymentRepository = paymentRepository ??
            PaymentRepository(
              paymentDataProvider: PaymentDataProvider(
                apiService: ApiService.instance,
              ),
            ),
        _binding = binding ?? WidgetsBinding.instance;

  static const _fastInterval = Duration(seconds: 3);
  static const _slowInterval = Duration(seconds: 10);
  static const _fastPhase = Duration(seconds: 30);
  static const _maxDuration = Duration(minutes: 5);

  final int paymentId;
  final PaymentStatusCallback onStatus;
  final void Function(PaymentStatusResult result)? onTerminal;
  final void Function(PaymentStatusResult result)? onFatalError;
  final VoidCallback? onTimeout;
  final PaymentRepository _paymentRepository;
  final WidgetsBinding _binding;

  Timer? _timer;
  DateTime? _startedAt;
  var _paused = false;
  var _stopped = false;
  var _polling = false;

  void start() {
    if (_stopped) return;
    _startedAt ??= DateTime.now();
    _binding.addObserver(_lifecycleObserver);
    _scheduleNext(immediate: true);
  }

  void stop() {
    if (_stopped) return;
    _stopped = true;
    _timer?.cancel();
    _timer = null;
    _binding.removeObserver(_lifecycleObserver);
  }

  void _scheduleNext({bool immediate = false}) {
    if (_stopped || _paused) return;
    _timer?.cancel();
    final delay = immediate ? Duration.zero : _currentInterval();
    _timer = Timer(delay, _tick);
  }

  Duration _currentInterval() {
    final started = _startedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _fastPhase) return _fastInterval;
    return _slowInterval;
  }

  Future<void> _tick() async {
    if (_stopped || _paused || _polling) return;
    final started = _startedAt ?? DateTime.now();
    if (DateTime.now().difference(started) > _maxDuration) {
      stop();
      onTimeout?.call();
      return;
    }

    _polling = true;
    try {
      final result = await _paymentRepository.getPaymentStatus(paymentId);
      onStatus(result);

      if (result.isQpayFatalPollError) {
        stop();
        onFatalError?.call(result);
        return;
      }

      if (result.isWalletTopUpSettled) {
        stop();
        onTerminal?.call(result);
        return;
      }

      if (result.isWalletTopUpTerminalFailure) {
        stop();
        onTerminal?.call(result);
        return;
      }

      if (!shouldContinueWalletTopUpPoll(result)) {
        stop();
        onTerminal?.call(result);
        return;
      }
    } catch (_) {
      // Transient network errors — keep polling.
    } finally {
      _polling = false;
      if (!_stopped && !_paused) {
        _scheduleNext();
      }
    }
  }

  final _lifecycleObserver = _PaymentPollerLifecycleObserver();

  void _onLifecycle(AppLifecycleState state) {
    if (_stopped) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _paused = true;
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed) {
      _paused = false;
      _scheduleNext(immediate: true);
    }
  }

  /// Starts a wallet top-up poller and returns a handle to [stop] it.
  static PaymentPoller startWalletTopUp({
    required int paymentId,
    required PaymentStatusCallback onStatus,
    void Function(PaymentStatusResult result)? onTerminal,
    void Function(PaymentStatusResult result)? onFatalError,
    VoidCallback? onTimeout,
    PaymentRepository? paymentRepository,
  }) {
    final poller = PaymentPoller(
      paymentId: paymentId,
      onStatus: onStatus,
      onTerminal: onTerminal,
      onFatalError: onFatalError,
      onTimeout: onTimeout,
      paymentRepository: paymentRepository,
    );
    poller._lifecycleObserver._bind(poller);
    poller.start();
    return poller;
  }
}

class _PaymentPollerLifecycleObserver with WidgetsBindingObserver {
  PaymentPoller? _poller;

  void _bind(PaymentPoller poller) => _poller = poller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _poller?._onLifecycle(state);
  }
}
