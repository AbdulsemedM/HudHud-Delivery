import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/payment_poller.dart';
import 'package:hudhud_delivery/core/utils/qpay_qr_payload.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/payment/model/payment_status_result.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum QPayFlowContext { walletTopUp }

enum QPaySheetResult { completed, expired, failed, unavailable, dismissed }

Future<QPaySheetResult?> showQPayQrSheet(
  BuildContext context, {
  required int paymentId,
  required String qrCode,
  String? amount,
  String? currency,
  QPayFlowContext flowContext = QPayFlowContext.walletTopUp,
}) {
  return showModalBottomSheet<QPaySheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) => _QPayQrSheet(
      paymentId: paymentId,
      qrCode: qrCode,
      amount: amount,
      currency: currency,
      flowContext: flowContext,
    ),
  );
}

class _QPayQrSheet extends StatefulWidget {
  const _QPayQrSheet({
    required this.paymentId,
    required this.qrCode,
    this.amount,
    this.currency,
    required this.flowContext,
  });

  final int paymentId;
  final String qrCode;
  final String? amount;
  final String? currency;
  final QPayFlowContext flowContext;

  @override
  State<_QPayQrSheet> createState() => _QPayQrSheetState();
}

class _QPayQrSheetState extends State<_QPayQrSheet> {
  PaymentPoller? _poller;
  var _checking = false;

  @override
  void initState() {
    super.initState();
    _poller = PaymentPoller.startWalletTopUp(
      paymentId: widget.paymentId,
      onStatus: (_) {
        if (!mounted) return;
        setState(() => _checking = true);
      },
      onTerminal: _handleTerminal,
      onFatalError: (_) => _pop(QPaySheetResult.unavailable),
      onTimeout: () {
        if (!mounted) return;
        _pop(QPaySheetResult.expired);
      },
    );
  }

  void _handleTerminal(PaymentStatusResult result) {
    if (!mounted) return;
    if (result.isWalletTopUpSettled) {
      _pop(QPaySheetResult.completed);
      return;
    }
    final qpay = result.qpayStatus?.toUpperCase();
    if (qpay == 'EXPIRED' || result.status == 'expired') {
      _pop(QPaySheetResult.expired);
      return;
    }
    _pop(QPaySheetResult.failed);
  }

  void _pop(QPaySheetResult result) {
    _poller?.stop();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _poller?.stop();
    super.dispose();
  }

  String get _title {
    switch (widget.flowContext) {
      case QPayFlowContext.walletTopUp:
        return 'Scan to top up wallet';
    }
  }

  String get _subtitle {
    switch (widget.flowContext) {
      case QPayFlowContext.walletTopUp:
        return 'Pay with CBE, Telebirr, or other Ethiopian banks.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = QPayQrPayload.classify(widget.qrCode);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _poller?.stop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AuthScreenColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusXL),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppColors.spaceLG,
          AppColors.spaceMD,
          AppColors.spaceLG,
          AppColors.spaceLG + bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AuthScreenColors.textMutedOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              Text(
                _title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AuthScreenColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppColors.spaceSM),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AuthScreenColors.textSecondaryOf(context),
                    ),
              ),
              const SizedBox(height: AppColors.spaceLG),
              _QrDisplay(payload: payload),
              if (widget.amount != null) ...[
                const SizedBox(height: AppColors.spaceMD),
                Text(
                  '${widget.amount} ${widget.currency ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AuthScreenColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              const SizedBox(height: AppColors.spaceMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_checking)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AuthScreenColors.orange,
                      ),
                    ),
                  if (_checking) const SizedBox(width: 8),
                  Text(
                    _checking
                        ? 'Waiting for payment…'
                        : 'Checking payment status…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AuthScreenColors.textMutedOf(context),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppColors.spaceLG),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _pop(QPaySheetResult.dismissed),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrDisplay extends StatelessWidget {
  const _QrDisplay({required this.payload});

  final QPayQrPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
      ),
      child: SizedBox(
        width: 260,
        height: 260,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (payload.kind) {
      case QPayQrPayloadKind.imageUrl:
        return CachedNetworkImage(
          imageUrl: payload.displayValue,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
        );
      case QPayQrPayloadKind.base64Image:
        final bytes = payload.imageBytes;
        if (bytes != null && bytes.isNotEmpty) {
          return Image.memory(
            Uint8List.fromList(bytes),
            fit: BoxFit.contain,
          );
        }
        return const Icon(Icons.qr_code_2, size: 120);
      case QPayQrPayloadKind.rawValue:
        if (payload.displayValue.isEmpty) {
          return const Icon(Icons.qr_code_2, size: 120);
        }
        return QrImageView(
          data: payload.displayValue,
          version: QrVersions.auto,
          size: 240,
          backgroundColor: Colors.white,
        );
    }
  }
}