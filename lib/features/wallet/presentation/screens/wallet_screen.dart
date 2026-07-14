import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
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
    final l10n = context.l10n;
    return ProfileDarkPage(
      title: l10n.profileWallet,
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Padding(
              padding: EdgeInsets.all(AppColors.spaceMD),
              child: WalletShimmer(),
            );
          }
          if (state is WalletError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: AuthScreenColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AuthScreenColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AuthScreenColors.orange,
                      ),
                      onPressed: () => context
                          .read<WalletBloc>()
                          .add(const FetchWalletsEvent()),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.actionRetry),
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
    const primaryCurrency = 'ETB';

    final selectedWallet = widget.wallets.isNotEmpty
        ? widget.wallets[_selectedWalletIndex.clamp(0, widget.wallets.length - 1)]
        : null;

    final totalBalance = widget.wallets.fold<double>(
      0,
      (sum, w) => sum + w.balanceAmount,
    );

    final displayBalance = selectedWallet != null && widget.wallets.length > 1
        ? selectedWallet.balanceAmount
        : totalBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      child: Column(
        children: [
          BalanceCard(
            balance: '${l10n.currencyEtb} ${displayBalance.toStringAsFixed(2)}',
          ),
          WalletActions(
            onAddMoney: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddFundsScreen(
                    wallets: widget.wallets,
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
                    wallets: widget.wallets,
                    defaultCurrency: primaryCurrency,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                context.read<WalletBloc>().add(const FetchWalletsEvent());
              }
            },
          ),
          if (widget.wallets.length > 1) ...[
            const SizedBox(height: AppColors.spaceMD),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.wallets.length,
                itemBuilder: (context, index) {
                  final wallet = widget.wallets[index];
                  return WalletSelectorChip(
                    label: wallet.name,
                    selected: _selectedWalletIndex == index,
                    onTap: () => setState(() => _selectedWalletIndex = index),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppColors.spaceLG),
          TransactionsList(
            transactions: _toTransactionItems(
              l10n,
              widget.transactions,
              primaryCurrency,
            ),
            onSeeAll: widget.wallets.isNotEmpty
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WalletDetailScreen(
                          walletId: widget.wallets[_selectedWalletIndex].id,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
