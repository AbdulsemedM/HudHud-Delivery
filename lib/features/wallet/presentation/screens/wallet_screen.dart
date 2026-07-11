import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/controllers/auth_controller.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/wallet/bloc/wallet_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_model.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'add_funds_screen.dart';
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
              return const WalletScreenShimmer();
            }
            if (state is WalletError) {
              final theme = Theme.of(context);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => context
                            .read<WalletBloc>()
                            .add(const FetchWalletsEvent()),
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

class _WalletContent extends StatefulWidget {
  final List<WalletModel> wallets;
  final List<WalletTransactionModel>? transactions;

  const _WalletContent({
    required this.wallets,
    this.transactions,
  });

  @override
  State<_WalletContent> createState() => _WalletContentState();
}

class _WalletContentState extends State<_WalletContent> {
  int _selectedWalletIndex = 0;
  final _transactionsKey = GlobalKey();

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
          : l10n.emDash;
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

  void _scrollToTransactions() {
    final target = _transactionsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wallets = widget.wallets;
    final selectedWallet =
        wallets.isNotEmpty ? wallets[_selectedWalletIndex] : null;
    final totalBalance = wallets.fold<double>(
      0,
      (sum, w) => sum + w.balanceAmount,
    );
    final displayBalance = selectedWallet?.balanceAmount ?? totalBalance;
    final primaryCurrency = l10n.currencyEtb;

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
            amount: displayBalance.toStringAsFixed(2),
            currency: primaryCurrency,
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
            onSeeHistory: _scrollToTransactions,
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 24),
            WalletSelectorChips(
              wallets: wallets,
              selectedIndex: _selectedWalletIndex,
              onSelected: (index) {
                setState(() => _selectedWalletIndex = index);
              },
            ),
          ],
          const SizedBox(height: 24),
          KeyedSubtree(
            key: _transactionsKey,
            child: TransactionsList(
              transactions: _toTransactionItems(
                l10n,
                widget.transactions,
                primaryCurrency,
              ),
              onSeeAll: null,
            ),
          ),
        ],
      ),
    );
  }
}
