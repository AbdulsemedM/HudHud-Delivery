
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AuthScreenColors.lavender.withValues(alpha: 0.7),
              width: 2,
            ),
          ),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: AuthScreenColors.surfaceBorder,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AuthScreenColors.orange,
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AuthScreenColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuthScreenColors.surfaceBorder),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AuthScreenColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  final String balance;

  const BalanceCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AuthScreenColors.signInGradient,
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.walletMyBalanceLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const WalletActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class WalletActions extends StatelessWidget {
  final VoidCallback onAddMoney;
  final VoidCallback onSendMoney;
  final VoidCallback? onHistory;

  const WalletActions({
    super.key,
    required this.onAddMoney,
    required this.onSendMoney,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
        child: Row(
          children: [
            WalletActionButton(
              icon: Icons.add_rounded,
              label: l10n.walletAddMoney,
              onTap: onAddMoney,
            ),
            WalletActionButton(
              icon: Icons.arrow_upward_rounded,
              label: l10n.withdrawAction,
              onTap: onSendMoney,
            ),
            WalletActionButton(
              icon: Icons.history_rounded,
              label: l10n.walletRecentTransactions,
              onTap: onHistory ?? () {},
            ),
          ],
        ),
      ),
    );
  }
}

class WalletSelectorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const WalletSelectorChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.black : AuthScreenColors.textSecondary,
        ),
        backgroundColor: AuthScreenColors.surface,
        selectedColor: AuthScreenColors.orange,
        side: BorderSide(
          color: selected
              ? AuthScreenColors.orange
              : AuthScreenColors.surfaceBorder,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
        ),
      ),
    );
  }
}

class TransactionsList extends StatelessWidget {
  final List<TransactionItem> transactions;
  final VoidCallback? onSeeAll;
  final bool isLoading;

  const TransactionsList({
    super.key,
    required this.transactions,
    this.onSeeAll,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.walletRecentTransactions,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  l10n.walletSeeAll,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Column(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                ),
              );
            }),
          )
        else if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.walletNoTransactionsYet,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          _GroupedTransactions(transactions: transactions),
      ],
    );
  }
}

class _GroupedTransactions extends StatelessWidget {
  final List<TransactionItem> transactions;

  const _GroupedTransactions({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TransactionItem>>{};
    for (final tx in transactions) {
      grouped.putIfAbsent(tx.date, () => []).add(tx);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...entry.value.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionListItem(transaction: tx),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class TransactionListItem extends StatelessWidget {
  final TransactionItem transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  bool get _isCredit {
    final type = transaction.type.toLowerCase();
    return type.contains('credit') ||
        type.contains('deposit') ||
        type.contains('add') ||
        type.contains('refund');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountColor = _isCredit ? AppColors.delivered : AppColors.cancelled;

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  transaction.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            transaction.formattedAmount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionItem {
  final String date;
  final String amount;
  final String type;
  final String? currency;

  const TransactionItem({
    required this.date,
    required this.amount,
    required this.type,
    this.currency,
  });

  String get formattedAmount {
    if (currency != null && currency!.isNotEmpty) {
      return '$currency $amount';
    }
    return amount;
  }
}

class WalletShimmer extends StatelessWidget {
  const WalletShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(AppColors.radiusXL),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
