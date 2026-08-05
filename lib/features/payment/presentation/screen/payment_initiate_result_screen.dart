import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../model/payment_initiate_result.dart';
import 'payment_hpp_screen.dart';

class PaymentInitiateResultScreen extends StatefulWidget {
  final PaymentInitiateResult result;
  final String orderId;

  const PaymentInitiateResultScreen({
    super.key,
    required this.result,
    required this.orderId,
  });

  @override
  State<PaymentInitiateResultScreen> createState() =>
      _PaymentInitiateResultScreenState();
}

class _PaymentInitiateResultScreenState
    extends State<PaymentInitiateResultScreen> {
  @override
  void initState() {
    super.initState();
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
    });
  }

  PaymentInitiateResult get result => widget.result;
  String get orderId => widget.orderId;

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
                    result.isSuccess ? 'Done' : 'Go back',
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
    if (!result.isSuccess) {
      return _StatusContent(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Payment failed',
        message: result.message ?? 'Could not initiate payment.',
      );
    }

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
        return _QrContent(result: result, orderId: orderId);
      case PaymentInitiateUiMode.redirectToHpp:
        return _StatusContent(
          icon: Icons.open_in_browser,
          iconColor: AppColors.primaryColor,
          title: 'Hosted payment',
          message: result.customerMessage ??
              result.message ??
              'Complete payment on the hosted page.',
          children: [
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
        final isCompleted = result.status == 'completed';
        final isCod = result.method == 'cash_on_delivery';
        return _StatusContent(
          icon: isCompleted ? Icons.check_circle : Icons.receipt_long,
          iconColor: AppColors.primaryColor,
          title: isCompleted
              ? 'Payment successful'
              : (isCod ? 'Order confirmed' : 'Payment initiated'),
          message: result.customerMessage ??
              result.message ??
              (isCompleted
                  ? 'Payment completed successfully.'
                  : 'Please complete your payment.'),
          children: [
            if (result.transactionId != null)
              _InfoRow(label: 'Transaction', value: result.transactionId!),
            if (result.orderStatus != null)
              _InfoRow(label: 'Order status', value: result.orderStatus!),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

  const _QrContent({required this.result, required this.orderId});

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
            const Icon(Icons.qr_code_2, size: 120, color: AppColors.primaryColor),
          const SizedBox(height: 20),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
