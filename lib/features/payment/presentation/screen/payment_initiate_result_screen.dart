import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/payment_poller.dart';
import '../../../../core/utils/qpay_qr_payload.dart';
import '../../../checkout/data/models/create_order_result.dart';
import '../../../courier/data/models/create_delivery_result.dart';
import '../../../courier/presentation/theme/courier_theme.dart';
import '../../../home/presentation/theme/home_colors.dart';
import '../../data/data_provider/payment_data_provider.dart';
import '../../data/repository/payment_repository.dart';
import '../../model/payment_initiate_result.dart';
import '../../model/payment_status_result.dart';
import 'payment_hpp_screen.dart';

class PaymentInitiateResultScreen extends StatefulWidget {
  final PaymentInitiateResult result;
  final String orderId;
  final PaymentRepository? paymentRepository;

  /// When set, labels use Delivery/Tracking instead of Order.
  final String? trackingNumber;

  /// Called instead of popping to root when payment succeeds.
  /// Receives the result screen [BuildContext] for navigation.
  final void Function(BuildContext context)? onTerminalSuccess;

  /// Primary button label on success (default: Done).
  final String? successActionLabel;

  const PaymentInitiateResultScreen({
    super.key,
    required this.result,
    required this.orderId,
    this.paymentRepository,
    this.trackingNumber,
    this.onTerminalSuccess,
    this.successActionLabel,
  });

  @override
  State<PaymentInitiateResultScreen> createState() =>
      _PaymentInitiateResultScreenState();
}

class _PaymentInitiateResultScreenState
    extends State<PaymentInitiateResultScreen> with WidgetsBindingObserver {
  late final PaymentRepository _paymentRepository;
  Timer? _pollTimer;
  PaymentStatusResult? _polledStatus;
  var _checking = false;
  var _timedOut = false;
  DateTime? _pollStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPollingActive) {
      _checkStatus(manual: false);
    }
  }

  PaymentInitiateResult get result => widget.result;
  String get orderId => widget.orderId;
  bool get _isWalletTopUp => orderId == 'wallet-topup';
  bool get _isDeliveryContext => widget.trackingNumber != null;

  String get _entityLabel => _isDeliveryContext ? 'Delivery' : 'Order';
  String get _statusLabel =>
      _isDeliveryContext ? 'Delivery status' : 'Order status';

  String _expectedStatus(String? method) => _isDeliveryContext
      ? expectedDeliveryStatusAfterPayment(method)
      : expectedOrderStatusAfterPayment(method);

  bool get _isTerminalSuccess {
    final polled = _polledStatus;
    if (_isWalletTopUp && polled != null && polled.isSuccess) {
      return isWalletTopUpSettled(polled);
    }
    if (polled != null && polled.isSuccess && polled.isCompleted) return true;
    if (!result.isSuccess) return false;
    if (result.uiMode != PaymentInitiateUiMode.success) return false;
    return result.status == 'completed' ||
        result.method == 'wallet' ||
        result.method == 'cash_on_delivery' ||
        result.nextAction == null;
  }

  bool _shouldStopPolling(PaymentStatusResult status) {
    if (_isWalletTopUp) {
      return isWalletTopUpSettled(status) || isQPayTerminalFailure(status);
    }
    return status.isTerminal;
  }

  bool get _shouldPoll => shouldPollPaymentStatus(
        isSuccess: result.isSuccess,
        nextAction: result.nextAction,
        status: result.status,
        method: result.method,
      );

  bool get _isPollingActive {
    if (!_shouldPoll || result.paymentId == null) return false;
    final polled = _polledStatus;
    if (polled == null) return true;
    if (_isWalletTopUp) return shouldKeepPollingWalletTopUp(polled);
    return !polled.isTerminal;
  }

  void _maybeStartPolling() {
    if (!_shouldPoll || result.paymentId == null) return;
    _pollStartedAt = DateTime.now();
    _checkStatus(manual: false);
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    final started = _pollStartedAt;
    if (started == null || !_isPollingActive) return;
    final interval = PaymentPollSchedule.nextInterval(startedAt: started);
    _pollTimer = Timer(interval, () {
      if (!mounted) return;
      _checkStatus(manual: false);
      if (_isPollingActive) _scheduleNextPoll();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkStatus({required bool manual}) async {
    // Poll status only — never call payments/initiate again from this screen.
    final paymentId = result.paymentId;
    if (paymentId == null || paymentId <= 0) return;
    final polled = _polledStatus;
    if (polled != null && _shouldStopPolling(polled)) return;

    final started = _pollStartedAt ?? DateTime.now();
    if (!manual && PaymentPollSchedule.isPastDeadline(startedAt: started)) {
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
      _pollStartedAt = DateTime.now();
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
      if (_shouldStopPolling(status)) {
        _stopPolling();
      } else if (_isPollingActive) {
        _scheduleNextPoll();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      if (_isPollingActive) _scheduleNextPoll();
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.paymentRefreshFailed),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _finishScreen() {
    if (_isWalletTopUp) {
      if (_isTerminalSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      final polled = _polledStatus;
      if (polled != null && isQPayTerminalFailure(polled)) {
        Navigator.of(context).pop(false);
        return;
      }
      Navigator.of(context).pop(null);
      return;
    }

    final success =
        result.isSuccess || (_polledStatus?.isCompleted ?? false);
    if (success &&
        _isTerminalSuccess &&
        widget.onTerminalSuccess != null) {
      widget.onTerminalSuccess!(context);
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: HomeColors.backgroundOf(context),
            appBar: AppBar(
              title: Text(context.l10n.paymentScreenTitle),
              backgroundColor: HomeColors.surfaceOf(context),
              foregroundColor: HomeColors.textPrimaryOf(context),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppColors.spaceMD),
                child: Column(
                  children: [
                    Expanded(child: _buildBody(context)),
                    if (_isPollingActive) ...[
                      SizedBox(height: AppColors.spaceSM),
                      SizedBox(
                        width: double.infinity,
                        height: AppColors.buttonHeightMD,
                        child: OutlinedButton.icon(
                          onPressed: _checking
                              ? null
                              : () => _checkStatus(manual: true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HomeColors.textPrimaryOf(context),
                            side: BorderSide(color: HomeColors.borderOf(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusLG),
                            ),
                          ),
                          icon: _checking
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: HomeColors.violet,
                                  ),
                                )
                              : Icon(Icons.refresh),
                          label: Text(_checking ? 'Checking…' : 'Check status'),
                        ),
                      ),
                      SizedBox(height: AppColors.spaceSM),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: AppColors.buttonHeightMD,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeColors.violet,
                          foregroundColor: theme.colorScheme.onPrimary,
                          disabledBackgroundColor:
                              HomeColors.violet.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusLG),
                          ),
                        ),
                        onPressed: _finishScreen,
                        child: Text(
                          () {
                            final success = result.isSuccess ||
                                (_polledStatus?.isCompleted ?? false);
                            if (!success) return 'Go back';
                            if (_isTerminalSuccess &&
                                widget.successActionLabel != null) {
                              return widget.successActionLabel!;
                            }
                            return 'Done';
                          }(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final polled = _polledStatus;
    final tracking = widget.trackingNumber;

    List<Widget> entityRows({String? relatedId}) => [
          if (tracking != null && tracking.isNotEmpty)
            _InfoRow(label: 'Tracking', value: tracking),
          _InfoRow(
            label: _entityLabel,
            value: '#${relatedId ?? orderId}',
          ),
        ];

    if (polled != null && polled.isSuccess) {
      if (_isWalletTopUp && isWalletTopUpSettled(polled)) {
        return _StatusContent(
          icon: Icons.check_circle,
          iconColor: HomeColors.violet,
          title: 'Wallet credited',
          message: 'Your wallet balance has been updated.',
          children: [
            if (polled.amount != null)
              _InfoRow(
                label: 'Amount',
                value: '${polled.amount} ${polled.currency ?? ''}'.trim(),
              ),
            if (polled.transactionId != null)
              _InfoRow(label: 'Transaction', value: polled.transactionId!),
            if (polled.reference != null)
              _InfoRow(label: 'Reference', value: polled.reference!),
          ],
        );
      }
      if (_isWalletTopUp && isQPayTerminalFailure(polled)) {
        final expired = polled.qpayStatus?.toUpperCase() == 'EXPIRED';
        return _StatusContent(
          icon: Icons.error_outline,
          iconColor: AppColors.errorColor,
          title: expired ? 'QR expired' : 'Payment failed',
          message: expired
              ? 'This QR payment expired. Start a new attempt.'
              : (polled.message ??
                  'Payment was not completed. Please try again.'),
          children: [
            if (polled.amount != null)
              _InfoRow(
                label: 'Amount',
                value: '${polled.amount} ${polled.currency ?? ''}'.trim(),
              ),
          ],
        );
      }
      if (!_isWalletTopUp && polled.isTerminal) {
        if (polled.isCompleted) {
          return _StatusContent(
            icon: Icons.check_circle,
            iconColor: HomeColors.violet,
            title: 'Payment successful',
            message: 'Your payment was confirmed.',
            children: [
              if (polled.relatedOrderStatus != null)
                _InfoRow(label: _statusLabel, value: polled.relatedOrderStatus!),
              if (polled.transactionId != null)
                _InfoRow(label: 'Transaction', value: polled.transactionId!),
              if (polled.reference != null)
                _InfoRow(label: 'Reference', value: polled.reference!),
              if (polled.amount != null)
                _InfoRow(
                  label: 'Amount',
                  value: '${polled.amount} ${polled.currency ?? ''}'.trim(),
                ),
              ...entityRows(
                relatedId: polled.relatedOrderId?.toString(),
              ),
            ],
          );
        }
        return _StatusContent(
          icon: Icons.error_outline,
          iconColor: AppColors.errorColor,
          title: 'Payment ${polled.status ?? 'failed'}',
          message:
              polled.message ?? 'Payment was not completed. Please try again.',
          children: [
            if (polled.relatedOrderStatus != null)
              _InfoRow(label: _statusLabel, value: polled.relatedOrderStatus!),
            ...entityRows(),
          ],
        );
      }
    }

    if (!result.isSuccess) {
      return _StatusContent(
        icon: Icons.error_outline,
        iconColor: AppColors.errorColor,
        title: 'Payment failed',
        message: result.message ?? 'Could not initiate payment.',
      );
    }

    final waitingChildren = <Widget>[
      if (_isPollingActive) ...[
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_checking)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: HomeColors.violet,
                ),
              )
            else
              Icon(
                Icons.hourglass_top,
                size: 16,
                color: HomeColors.textMutedOf(context),
              ),
            SizedBox(width: 8),
            Text(
              _timedOut
                  ? 'Status check timed out. Tap Check status to retry.'
                  : 'Waiting for payment confirmation…',
              style: TextStyle(
                fontSize: 12,
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
      ],
      if (polled?.status != null)
        _InfoRow(label: 'Payment status', value: polled!.status!),
    ];

    switch (result.uiMode) {
      case PaymentInitiateUiMode.ussdPending:
      case PaymentInitiateUiMode.userActionRequired:
        return _StatusContent(
          icon: Icons.phone_android,
          iconColor: HomeColors.violet,
          title: 'Complete on your phone',
          message: result.customerMessage ??
              result.message ??
              'Please check your phone and enter your PIN to complete the payment.',
          children: [
            ...waitingChildren,
            _InfoRow(
              label: _statusLabel,
              value: _expectedStatus(result.method),
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
            ...entityRows(),
          ],
        );
      case PaymentInitiateUiMode.qrCode:
        return _QrContent(
          result: result,
          orderId: orderId,
          isQPay: _isWalletTopUp || result.method == 'qpay',
          entityLabel: _entityLabel,
          statusLabel: _statusLabel,
          expectedStatus: _expectedStatus(result.method),
          trackingNumber: tracking,
          extraChildren: waitingChildren,
        );
      case PaymentInitiateUiMode.redirectToHpp:
        return _StatusContent(
          icon: Icons.open_in_browser,
          iconColor: HomeColors.violet,
          title: 'Hosted payment',
          message: result.customerMessage ??
              result.message ??
              'Complete payment on the hosted page.',
          children: [
            ...waitingChildren,
            _InfoRow(
              label: _statusLabel,
              value: _expectedStatus(result.method),
            ),
            ...entityRows(),
            SizedBox(height: 16),
            if (result.redirectUrl != null && result.redirectUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: AppColors.buttonHeightMD,
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeColors.textPrimaryOf(context),
                    side: BorderSide(color: HomeColors.borderOf(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  icon: Icon(Icons.open_in_browser),
                  label: Text(context.l10n.openPaymentPage),
                ),
              ),
          ],
        );
      case PaymentInitiateUiMode.success:
        final isCompleted =
            result.status == 'completed' || result.method == 'wallet';
        final isCod = result.method == 'cash_on_delivery';
        final orderStatus =
            result.orderStatus ?? _expectedStatus(result.method);
        final successMessage = _isDeliveryContext
            ? (isCompleted
                ? 'Your delivery is paid.'
                : (isCod
                    ? 'Pay upon delivery. Your delivery is confirmed.'
                    : 'Your delivery is processing while payment confirms.'))
            : (isCompleted
                ? 'Your order is paid.'
                : (isCod
                    ? 'Pay upon delivery. Your order is confirmed.'
                    : 'Your order is processing while payment confirms.'));
        return _StatusContent(
          icon: isCompleted ? Icons.check_circle : Icons.receipt_long,
          iconColor: HomeColors.violet,
          title: isCompleted
              ? 'Payment successful'
              : (isCod
                  ? (_isDeliveryContext
                      ? 'Delivery confirmed'
                      : 'Order confirmed')
                  : 'Payment initiated'),
          message: result.customerMessage ?? result.message ?? successMessage,
          children: [
            if (_shouldPoll) ...waitingChildren,
            _InfoRow(label: _statusLabel, value: orderStatus),
            if (result.transactionId != null)
              _InfoRow(label: 'Transaction', value: result.transactionId!),
            if (result.amount != null)
              _InfoRow(
                label: 'Amount',
                value: '${result.amount} ${result.currency ?? ''}'.trim(),
              ),
            ...entityRows(),
          ],
        );
      case PaymentInitiateUiMode.failure:
        return _StatusContent(
          icon: Icons.error_outline,
          iconColor: AppColors.errorColor,
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: AppColors.spaceMD),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 44),
          ),
          SizedBox(height: AppColors.spaceLG),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
          SizedBox(height: AppColors.spaceSM),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: HomeColors.textSecondaryOf(context),
              height: 1.45,
            ),
          ),
          if (children.isNotEmpty) ...[
            SizedBox(height: AppColors.spaceLG),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppColors.spaceMD),
              decoration: BoxDecoration(
                color: HomeColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: HomeColors.borderOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QrContent extends StatelessWidget {
  final PaymentInitiateResult result;
  final String orderId;
  final bool isQPay;
  final String entityLabel;
  final String statusLabel;
  final String expectedStatus;
  final String? trackingNumber;
  final List<Widget> extraChildren;

  const _QrContent({
    required this.result,
    required this.orderId,
    this.isQPay = false,
    required this.entityLabel,
    required this.statusLabel,
    required this.expectedStatus,
    this.trackingNumber,
    this.extraChildren = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrRaw = result.qrCodeRaw ?? result.qrCodeBase64;
    final payload = parseQpayQrPayload(qrRaw);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: AppColors.spaceMD),
          if (isQPay) ...[
            Text(
              'QPay QR',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
            SizedBox(height: AppColors.spaceSM),
            Text(
              'Accepts CBE, Telebirr, and all Banks in Ethiopia',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: HomeColors.textMutedOf(context),
              ),
            ),
            SizedBox(height: AppColors.spaceSM),
          ],
          Text(
            isQPay
                ? 'Scan with CBE, Telebirr, or any Ethiopian bank app. Do not close this screen until payment is confirmed.'
                : (result.customerMessage ??
                    result.message ??
                    'Scan the QR code to complete payment.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: HomeColors.textSecondaryOf(context),
              height: 1.45,
            ),
          ),
          SizedBox(height: AppColors.spaceLG),
          _QpayQrImage(payload: payload),
          SizedBox(height: AppColors.spaceLG),
          if (extraChildren.isNotEmpty) ...extraChildren,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              color: HomeColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(color: HomeColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isQPay)
                  _InfoRow(label: statusLabel, value: expectedStatus),
                if (result.amount != null)
                  _InfoRow(
                    label: 'Amount',
                    value: '${result.amount} ${result.currency ?? ''}'.trim(),
                  ),
                if (result.expiresAt != null)
                  _InfoRow(
                    label: isQPay ? 'QR valid until' : 'Expires',
                    value: result.expiresAt!,
                  ),
                if (result.qrId != null)
                  _InfoRow(label: 'QR ID', value: result.qrId!),
                if (trackingNumber != null && trackingNumber!.isNotEmpty)
                  _InfoRow(label: 'Tracking', value: trackingNumber!),
                if (!isQPay)
                  _InfoRow(label: entityLabel, value: '#$orderId'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QpayQrImage extends StatelessWidget {
  const _QpayQrImage({required this.payload});

  final QpayQrPayload payload;

  @override
  Widget build(BuildContext context) {
    final frame = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppColors.radiusLG),
      border: Border.all(color: HomeColors.borderOf(context)),
    );

    if (payload.isEmpty) {
      return Icon(Icons.qr_code_2, size: 120, color: HomeColors.violet);
    }

    switch (payload.kind) {
      case QpayQrDisplayKind.qrValue:
        return Container(
          padding: EdgeInsets.all(AppColors.spaceMD),
          decoration: frame,
          child: QrImageView(
            data: payload.value,
            version: QrVersions.auto,
            size: 260,
            backgroundColor: Colors.white,
          ),
        );
      case QpayQrDisplayKind.imageUrl:
        return Container(
          padding: EdgeInsets.all(AppColors.spaceMD),
          decoration: frame,
          child: Image.network(
            payload.value,
            width: 260,
            height: 260,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.qr_code_2, size: 120, color: HomeColors.violet),
          ),
        );
      case QpayQrDisplayKind.dataUrl:
      case QpayQrDisplayKind.rawBase64:
        final base64 = base64ImageBytesFromQrPayload(payload);
        Uint8List? imageBytes;
        if (base64 != null && base64.isNotEmpty) {
          try {
            imageBytes = base64Decode(base64);
          } catch (_) {}
        }
        if (imageBytes == null) {
          return Icon(Icons.qr_code_2, size: 120, color: HomeColors.violet);
        }
        return Container(
          padding: EdgeInsets.all(AppColors.spaceMD),
          decoration: frame,
          child: Image.memory(imageBytes, width: 260, height: 260),
        );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
