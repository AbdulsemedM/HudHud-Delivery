import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/controllers/auth_controller.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/wallet/bloc/wallet_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_model.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'add_funds_screen.dart';
import 'wallet_detail_screen.dart';
import 'withdraw_funds_screen.dart';
import '../widgets/wallet_widget.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletBloc(
        walletRepository: WalletRepository(
          walletDataProvider: WalletDataProvider(
            apiService: ApiService.instance,
          ),
        ),
      )..add(const FetchWalletsEvent()),
      child: const _WalletScreenContent(),
    );
  }
}

class _WalletScreenContent extends StatelessWidget {
  const _WalletScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state is WalletLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is WalletError) {
              final theme = Theme.of(context);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<WalletBloc>().add(const FetchWalletsEvent()),
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.actionRetry),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is WalletsLoaded) {
              return _WalletContent(
                wallets: state.wallets,
                transactions: state.transactions,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _WalletContent extends StatelessWidget {
  final List<WalletModel> wallets;
  final List<WalletTransactionModel>? transactions;

  const _WalletContent({
    required this.wallets,
    this.transactions,
  });

  static List<TransactionItem> _toTransactionItems(
    AppLocalizations l10n,
    List<WalletTransactionModel>? transactions,
    String defaultCurrency,
  ) {
    if (transactions == null || transactions.isEmpty) return [];
    return transactions.map((t) {
      final date = t.createdAt != null
          ? DateFormat('dd MMM yyyy').format(
              DateTime.tryParse(t.createdAt!) ?? DateTime.now(),
            )
          : '-';
      return TransactionItem(
        date: date.toUpperCase(),
        amount: t.amount ?? '0',
        type: t.type ??
            t.description ??
            l10n.walletDefaultTransactionLabel,
        currency: t.currency ?? defaultCurrency,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalBalance = wallets.fold<double>(
      0,
      (sum, w) => sum + w.balanceAmount,
    );
    const primaryCurrency = 'ETB';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          WalletHeader(
            avatarUrl: getDisplayAvatarUrl(
              context.watch<AuthController>().currentUser,
            ),
          ),
          const SizedBox(height: 24),
          BalanceCard(
            balance:
                '${l10n.currencyEtb} ${totalBalance.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 24),
          WalletActions(
            onAddMoney: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddFundsScreen(
                    wallets: wallets,
                    defaultCurrency: primaryCurrency,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                context.read<WalletBloc>().add(const FetchWalletsEvent());
              }
            },
            onSendMoney: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => WithdrawFundsScreen(
                    wallets: wallets,
                    defaultCurrency: primaryCurrency,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                context.read<WalletBloc>().add(const FetchWalletsEvent());
              }
            },
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 24),
            _WalletsList(wallets: wallets),
          ],
          const SizedBox(height: 24),
          TransactionsList(
            transactions:
                _toTransactionItems(l10n, transactions, primaryCurrency),
            onSeeAll: null,
          ),
        ],
      ),
    );
  }
}

class _WalletsList extends StatelessWidget {
  final List<WalletModel> wallets;

  const _WalletsList({required this.wallets});

  void _openWalletDetail(BuildContext context, int walletId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletDetailScreen(walletId: walletId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.walletMyWalletsSection,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: wallets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final wallet = wallets[index];
            return _WalletCard(
              wallet: wallet,
              onTap: () => _openWalletDetail(context, wallet.id),
            );
          },
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback? onTap;

  const _WalletCard({required this.wallet, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.account_balance_wallet, color: Colors.orange[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.walletTypeCurrency(wallet.type, l10n.currencyEtb),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${l10n.currencyEtb} ${wallet.balance}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
