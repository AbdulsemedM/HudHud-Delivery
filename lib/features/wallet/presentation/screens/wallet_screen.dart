import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/wallet/bloc/wallet_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_balance_model.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'package:hudhud_delivery/features/wallet/services/wallet_topup_recovery_service.dart';
import 'wallet_topup_page.dart';
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
      )..add(const FetchBalanceEvent()),
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
          if (state is WalletLoading || state is WalletInitial) {
            return Padding(
              padding: EdgeInsets.all(AppColors.spaceMD),
              child: WalletShimmer(),
            );
          }
          if (state is WalletError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: AuthScreenColors.textMutedOf(context),
                    ),
                    SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AuthScreenColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AuthScreenColors.orange,
                      ),
                      onPressed: () => context
                          .read<WalletBloc>()
                          .add(const FetchBalanceEvent()),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.actionRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is BalanceLoaded) {
            return _WalletContent(
              balance: state.balance,
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
  final WalletBalance balance;
  final List<WalletTransactionModel> transactions;

  const _WalletContent({
    required this.balance,
    required this.transactions,
  });

  @override
  State<_WalletContent> createState() => _WalletContentState();
}

class _WalletContentState extends State<_WalletContent> {
  final _transactionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WalletTopUpRecoveryService.instance.addListener(_onRecoveryChanged);
  }

  @override
  void dispose() {
    WalletTopUpRecoveryService.instance.removeListener(_onRecoveryChanged);
    super.dispose();
  }

  void _onRecoveryChanged() {
    if (mounted) setState(() {});
  }

  static List<TransactionItem> _toTransactionItems(
    AppLocalizations l10n,
    List<WalletTransactionModel> transactions,
    String defaultCurrency,
  ) {
    if (transactions.isEmpty) return [];
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

  Future<void> _refreshAfterMutation() async {
    if (!mounted) return;
    context.read<WalletBloc>().add(const FetchBalanceEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = widget.balance.currency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      child: Column(
        children: [
          BalanceCard(
            balance:
                '$currency ${widget.balance.balance.toStringAsFixed(2)}',
            bottomActions: WalletActions(
              showPendingTopUp:
                  WalletTopUpRecoveryService.instance.hasPendingTopUp,
              onAddMoney: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => WalletTopUpPage(
                      defaultCurrency: currency,
                    ),
                  ),
                );
                if (result == true) {
                  await WalletTopUpRecoveryService.instance.refresh();
                  await _refreshAfterMutation();
                }
              },
              onSendMoney: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => WithdrawFundsScreen(
                      defaultCurrency: currency,
                      walletId: widget.balance.id,
                    ),
                  ),
                );
                if (result == true) await _refreshAfterMutation();
              },
              onHistory: () {
                final target = _transactionsKey.currentContext;
                if (target != null) {
                  Scrollable.ensureVisible(
                    target,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: AppColors.spaceLG),
          TransactionsList(
            key: _transactionsKey,
            transactions: _toTransactionItems(
              l10n,
              widget.transactions,
              currency,
            ),
            onSeeAll: null,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
