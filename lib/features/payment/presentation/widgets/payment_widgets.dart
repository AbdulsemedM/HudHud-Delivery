import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentMethodCard extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  const PaymentMethodCard({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Payment method icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getPaymentMethodColor(id).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPaymentMethodIcon(id),
                  color: _getPaymentMethodColor(id),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Payment method details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: enabled ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String paymentId) {
    switch (paymentId) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'cash_on_delivery':
        return Icons.money_rounded;
      case 'mpesa':
        return Icons.phone_android_rounded;
      case 'telebirr':
        return Icons.phone_android;
      case 'chapa':
        return Icons.payment;
      case 'cbe':
        return Icons.account_balance;
      case 'ebirr':
        return Icons.wallet;
      case 'edahab':
        return Icons.phone_android_rounded;
      case 'sahay':
        return Icons.payment;
      case 'waafi':
        return Icons.account_balance_wallet_rounded;
      case 'amole':
        return Icons.mobile_friendly;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String paymentId) {
    switch (paymentId) {
      case 'wallet':
        return const Color(0xFF2196F3);
      case 'card':
        return const Color(0xFF4CAF50);
      case 'cash_on_delivery':
        return const Color(0xFFFF9800);
      case 'mpesa':
        return const Color(0xFF00A86B);
      case 'telebirr':
        return const Color(0xFF1E88E5);
      case 'chapa':
        return const Color(0xFF4CAF50);
      case 'cbe':
        return const Color(0xFF2196F3);
      case 'ebirr':
        return const Color(0xFFFF9800);
      case 'edahab':
        return const Color(0xFF1E88E5);
      case 'sahay':
        return const Color(0xFF4CAF50);
      case 'waafi':
        return const Color(0xFF00A86B);
      case 'amole':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.primaryColor;
    }
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final double subtotal;
  final double total;

  const PaymentSummaryCard({
    super.key,
    required this.subtotal,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', subtotal),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Amount',
              total,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${amount.toStringAsFixed(2)} Br',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? AppColors.primaryColor
                  : isDiscount
                      ? Colors.green
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentProcessingDialog extends StatelessWidget {
  final String paymentMethod;

  const PaymentProcessingDialog({
    super.key,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Payment',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your payment via $paymentMethod...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
