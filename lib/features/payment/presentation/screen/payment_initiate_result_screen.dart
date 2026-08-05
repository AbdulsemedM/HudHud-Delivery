import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../checkout/data/models/create_order_result.dart';
import '../../data/data_provider/payment_data_provider.dart';
import '../../data/repository/payment_repository.dart';
import '../../model/payment_initiate_result.dart';
import '../../model/payment_status_result.dart';
import 'payment_hpp_screen.dart';

class PaymentInitiateResultScreen extends StatefulWidget {
  final PaymentInitiateResult result;
  final String orderId;
  final PaymentRepository? paymentRepository;

  const PaymentInitiateResultScreen({
    super.key,
    required this.result,
    required this.orderId,
    this.paymentRepository,
  });

  @override
  State<PaymentInitiateResultScreen> createState() =>
      _PaymentInitiateResultScreenState();
}

class _PaymentInitiateResultScreenState
    extends State<PaymentInitiateResultScreen> {
  static const _pollInterval = Duration(seconds: 3);
  static const _defaultTimeout = Duration(minutes: 5);

  late final PaymentRepository _paymentRepository;
  Timer? _pollTimer;
  PaymentStatusResult? _polledStatus;
  var _checking = false;
  var _timedOut = false;
  DateTime? _pollDeadline;

  @override
  void initState() {
    super.initState();
    _paymentRepository = widget.paymentRepository ??
        PaymentRepository(
          paymentDataProvider: PaymentDataProvider(
            apiService: ApiService.instance,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final result = widget.result;
      if (result.isSuccess &&
          result.uiMode == PaymentInitiateUiMode.redirectToHpp &&
          result.redirectUrl != null &&
          result.redirectUrl!.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentHppScreen(
              redirectUrl: result.redirectUrl!,
            ),
          ),
        );
      }
      _maybeStartPolling();
    });
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  PaymentInitiateResult get result => widget.result;
  String get orderId => widget.orderId;

  bool get _shouldPoll => shouldPollPaymentStatus(
        isSuccess: result.isSuccess,
        nextAction: result.nextAction,
        status: result.status,
        method: result.method,
      );

  bool get _isPollingActive =>
      _shouldPoll &&
      (_polledStatus == null || !_polledStatus!.isTerminal);

  void _maybeStartPolling() {
    if (!_shouldPoll || result.paymentId == null) return;
    _pollDeadline = _resolveDeadline();
    _checkStatus(manual: false);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      _checkStatus(manual: false);
    });
  }

  DateTime _resolveDeadline() {
    final now = DateTime.now();
    final defaultEnd = now.add(_defaultTimeout);
    final expiresRaw = result.expiresAt;
    if (expiresRaw == null || expiresRaw.isEmpty) return defaultEnd;
    final expires = DateTime.tryParse(expiresRaw);
    if (expires == null) return defaultEnd;
    return expires.isBefore(defaultEnd) ? expires : defaultEnd;
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkStatus({required bool manual}) async {
    final paymentId = result.paymentId;
    if (paymentId == null || paymentId <= 0) return;
    if (_polledStatus?.isTerminal == true) return;

    if (!manual &&
        _pollDeadline != null &&
        DateTime.now().isAfter(_pollDeadline!)) {
      _stopPolling();
      if (mounted) {
        setState(() {
          _timedOut = true;
          _checking = false;
        });
      }
      return;
    }

    if (manual && _timedOut) {
      _timedOut = false;
      _pollDeadline = DateTime.now().add(_defaultTimeout);
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(_pollInterval, (_) {
        if (!mounted) return;
        _checkStatus(manual: false);
      });
    }

    if (_checking) return;
    if (mounted) setState(() => _checking = true);

    try {
      final status = await _paymentRepository.getPaymentStatus(paymentId);
      if (!mounted) return;
      setState(() {
        _polledStatus = status;
        _checking = false;
      });
      if (status.isTerminal) {
        _stopPolling();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh payment status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(child: _buildBody(context)),
              if (_isPollingActive) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checking
                        ? null
                        : () => _checkStatus(manual: true),
                    icon: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_checking ? 'Checking…' : 'Check status'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    result.isSuccess ||
                            (_polledStatus?.isCompleted ?? false)
                        ? 'Done'
                        : 'Go back',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final polled = _polledStatus;
    if (polled != null && polled.isSuccess && polled.isTerminal) {
      if (polled.isCompleted) {
        return _StatusContent(
          icon: Icons.check_circle,
          iconColor: AppColors.primaryColor,
          title: 'Payment successful',
          message: 'Your payment was confirmed.',
          children: [
            if (polled.relatedOrderStatus != null)
              _InfoRow(label: 'Order status', value: polled.relatedOrderStatus!),
            if (polled.transactionId != null)
              _InfoRow(label: 'Transaction', value: polled.transactionId!),
            if (polled.reference != null)
              _InfoRow(label: 'Reference', value: polled.reference!),
            if (polled.amount != null)
              _InfoRow(
                label: 'Amount',
                value: '${polled.amount} ${polled.currency ?? ''}'.trim(),
              ),
            _InfoRow(
              label: 'Order',
              value: '#${polled.relatedOrderId ?? orderId}',
            ),
          ],
        );
      }
      return _StatusContent(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Payment ${polled.status ?? 'failed'}',
        message: polled.message ??
            'Payment was not completed. Please try again.',
        children: [
          if (polled.relatedOrderStatus != null)
            _InfoRow(label: 'Order status', value: polled.relatedOrderStatus!),
          _InfoRow(label: 'Order', value: '#$orderId'),
        ],
      );
    }

    if (!result.isSuccess) {
      return _StatusContent(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Payment failed',
        message: result.message ?? 'Could not initiate payment.',
      );
    }

    final waitingChildren = <Widget>[
      if (_isPollingActive) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_checking)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.hourglass_top,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            const SizedBox(width: 8),
            Text(
              _timedOut
                  ? 'Status check timed out. Tap Check status to retry.'
                  : 'Waiting for payment confirmation…',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      if (polled?.status != null)
        _InfoRow(label: 'Payment status', value: polled!.status!),
    ];

    switch (result.uiMode) {
      case PaymentInitiateUiMode.ussdPending:
      case PaymentInitiateUiMode.userActionRequired:
        return _StatusContent(
          icon: Icons.phone_android,
          iconColor: AppColors.primaryColor,
          title: 'Complete on your phone',
          message: result.customerMessage ??
              result.message ??
              'Please check your phone and enter your PIN to complete the payment.',
          children: [
            ...waitingChildren,
            _InfoRow(
              label: 'Order status',
              value: expectedOrderStatusAfterPayment(result.method),
            ),
            if (result.referenceNumber != null)
              _InfoRow(label: 'Reference', value: result.referenceNumber!),
            if (result.phone != null)
              _InfoRow(label: 'Phone', value: result.phone!),
            if (result.amount != null)
              _InfoRow(
                label: 'Amount',
                value: '${result.amount} ${result.currency ?? ''}'.trim(),
              ),
            _InfoRow(label: 'Order', value: '#$orderId'),
          ],
        );
      case PaymentInitiateUiMode.qrCode:
        return _QrContent(
          result: result,
          orderId: orderId,
          extraChildren: waitingChildren,
        );
      case PaymentInitiateUiMode.redirectToHpp:
        return _StatusContent(
          icon: Icons.open_in_browser,
          iconColor: AppColors.primaryColor,
          title: 'Hosted payment',
          message: result.customerMessage ??
              result.message ??
              'Complete payment on the hosted page.',
          children: [
            ...waitingChildren,
            _InfoRow(
              label: 'Order status',
              value: expectedOrderStatusAfterPayment(result.method),
            ),
            _InfoRow(label: 'Order', value: '#$orderId'),
            const SizedBox(height: 16),
            if (result.redirectUrl != null && result.redirectUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentHppScreen(
                          redirectUrl: result.redirectUrl!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open payment page'),
                ),
              ),
          ],
        );
      case PaymentInitiateUiMode.success:
        final isCompleted =
            result.status == 'completed' || result.method == 'wallet';
        final isCod = result.method == 'cash_on_delivery';
        final orderStatus = result.orderStatus ??
            expectedOrderStatusAfterPayment(result.method);
        return _StatusContent(
          icon: isCompleted ? Icons.check_circle : Icons.receipt_long,
          iconColor: AppColors.primaryColor,
          title: isCompleted
              ? 'Payment successful'
              : (isCod ? 'Order confirmed' : 'Payment initiated'),
          message: result.customerMessage ??
              result.message ??
              (isCompleted
                  ? 'Your order is paid.'
                  : (isCod
                      ? 'Pay upon delivery. Your order is confirmed.'
                      : 'Your order is processing while payment confirms.')),
          children: [
            if (_shouldPoll) ...waitingChildren,
            _InfoRow(label: 'Order status', value: orderStatus),
            if (result.transactionId != null)
              _InfoRow(label: 'Transaction', value: result.transactionId!),
            if (result.amount != null)
              _InfoRow(
                label: 'Amount',
                value: '${result.amount} ${result.currency ?? ''}'.trim(),
              ),
            _InfoRow(label: 'Order', value: '#$orderId'),
          ],
        );
      case PaymentInitiateUiMode.failure:
        return _StatusContent(
          icon: Icons.error_outline,
          iconColor: Colors.red,
          title: 'Payment failed',
          message: result.message ?? 'Could not initiate payment.',
        );
    }
  }
}

class _StatusContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<Widget> children;

  const _StatusContent({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _QrContent extends StatelessWidget {
  final PaymentInitiateResult result;
  final String orderId;
  final List<Widget> extraChildren;

  const _QrContent({
    required this.result,
    required this.orderId,
    this.extraChildren = const [],
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    final raw = result.qrCodeBase64;
    if (raw != null && raw.isNotEmpty) {
      try {
        imageBytes = base64Decode(raw);
      } catch (_) {}
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            result.customerMessage ??
                result.message ??
                'Scan the QR code to complete payment.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          if (imageBytes != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Image.memory(imageBytes, width: 260, height: 260),
            )
          else
            const Icon(Icons.qr_code_2,
                size: 120, color: AppColors.primaryColor),
          const SizedBox(height: 20),
          ...extraChildren,
          _InfoRow(
            label: 'Order status',
            value: expectedOrderStatusAfterPayment(result.method),
          ),
          if (result.amount != null)
            _InfoRow(
              label: 'Amount',
              value: '${result.amount} ${result.currency ?? ''}'.trim(),
            ),
          if (result.expiresAt != null)
            _InfoRow(label: 'Expires', value: result.expiresAt!),
          if (result.qrId != null) _InfoRow(label: 'QR ID', value: result.qrId!),
          _InfoRow(label: 'Order', value: '#$orderId'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
