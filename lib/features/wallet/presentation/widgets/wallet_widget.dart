import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/orders_widget.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_model.dart';
import 'package:shimmer/shimmer.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key, this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StoryRing(
          child: UserAvatar(radius: 20, imageUrl: avatarUrl),
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: colorScheme.onSurface,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  final String amount;
  final String currency;

  const BalanceCard({
    super.key,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(AppColors.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.walletMyBalanceLabel.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.lightOnPrimary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$currency $amount',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.lightOnPrimary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletActions extends StatelessWidget {
  final VoidCallback onAddMoney;
  final VoidCallback onSendMoney;
  final VoidCallback? onSeeHistory;

  const WalletActions({
    super.key,
    required this.onAddMoney,
    required this.onSendMoney,
    this.onSeeHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: _WalletActionButton(
            icon: Icons.add_circle_outline,
            label: l10n.walletAddMoney,
            color: colorScheme.primary,
            onTap: onAddMoney,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _WalletActionButton(
            icon: Icons.send_outlined,
            label: l10n.walletSendMoney,
            color: colorScheme.onSurface,
            onTap: onSendMoney,
            textTheme: textTheme,
          ),
        ),
        if (onSeeHistory != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _WalletActionButton(
              icon: Icons.history,
              label: l10n.walletSeeAll,
              color: colorScheme.onSurfaceVariant,
              onTap: onSeeHistory!,
              textTheme: textTheme,
            ),
          ),
        ],
      ],
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final TextTheme textTheme;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBox(icon: icon, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletSelectorChips extends StatelessWidget {
  final List<WalletModel> wallets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const WalletSelectorChips({
    super.key,
    required this.wallets,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.l10n.walletMyWalletsSection),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isSelected = index == selectedIndex;
              return FilterChip(
                label: Text(wallet.name),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) => onSelected(index),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primary.withValues(alpha: 0.12),
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.rFull),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TransactionsList extends StatelessWidget {
  final List<TransactionItem> transactions;
  final VoidCallback? onSeeAll;

  const TransactionsList({
    super.key,
    required this.transactions,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final grouped = <String, List<TransactionItem>>{};
    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.date, () => []).add(transaction);
    }
    final dates = grouped.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.walletRecentTransactions,
          onSeeAll: onSeeAll,
          seeAllLabel: l10n.walletSeeAll,
        ),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.walletNoTransactionsYet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...dates.map((date) {
            final items = grouped[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    date,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                ...List.generate(items.length, (index) {
                  final isLast = index == items.length - 1;
                  return Column(
                    children: [
                      TransactionListItem(transaction: items[index]),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
      ],
    );
  }
}

class TransactionListItem extends StatelessWidget {
  final TransactionItem transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  Color _iconColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (transaction.isCredit) {
      return AppColors.successColor;
    }
    if (transaction.isDebit) {
      return AppColors.errorColor;
    }
    return colorScheme.primary;
  }

  IconData _icon() {
    if (transaction.isCredit) {
      return Icons.arrow_downward_rounded;
    }
    if (transaction.isDebit) {
      return Icons.arrow_upward_rounded;
    }
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = _iconColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconBox(icon: _icon(), color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              transaction.type,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            transaction.formattedAmount,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletScreenShimmer extends StatelessWidget {
  const WalletScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final baseColor = isDark
        ? colorScheme.surfaceContainerHigh
        : Colors.grey.shade300;
    final highlightColor = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    final placeholder = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: placeholder,
                    borderRadius: BorderRadius.circular(AppColors.r10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: placeholder,
                borderRadius: BorderRadius.circular(AppColors.r16),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: placeholder,
                          borderRadius:
                              BorderRadius.circular(AppColors.r10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 56,
                        color: placeholder,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 16,
              width: 140,
              color: placeholder,
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: placeholder,
                        borderRadius: BorderRadius.circular(AppColors.r10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            color: placeholder,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 80,
                            color: placeholder,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 14,
                      width: 64,
                      color: placeholder,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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

  bool get isCredit {
    final value = double.tryParse(amount) ?? 0;
    return value > 0;
  }

  bool get isDebit {
    final value = double.tryParse(amount) ?? 0;
    return value < 0;
  }

  String get formattedAmount {
    if (currency != null && currency!.isNotEmpty) {
      return '$currency $amount';
    }
    return amount;
  }
}
