import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/wallet/bloc/wallet_bloc.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_model.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';

class WalletDetailScreen extends StatelessWidget {
  final int walletId;

  const WalletDetailScreen({super.key, required this.walletId});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider(
      create: (_) => WalletBloc(
        walletRepository: WalletRepository(
          walletDataProvider: WalletDataProvider(
            apiService: ApiService.instance,
          ),
        ),
      )..add(FetchWalletEvent(walletId: walletId)),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(l10n.walletDetailScreenTitle),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state is WalletDetailLoading) {
              return const Padding(
                padding: EdgeInsets.all(AppColors.spaceMD),
                child: _WalletDetailShimmer(),
              );
            }
            if (state is WalletDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppColors.spaceLG),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppColors.spaceMD),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppColors.spaceLG),
                      TextButton.icon(
                        onPressed: () => context
                            .read<WalletBloc>()
                            .add(FetchWalletEvent(walletId: walletId)),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.actionRetry),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is WalletDetailLoaded) {
              return _WalletDetailContent(wallet: state.wallet);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _WalletDetailShimmer extends StatelessWidget {
  const _WalletDetailShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
            ),
          ),
        ),
        const SizedBox(height: AppColors.spaceLG),
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletDetailContent extends StatelessWidget {
  final WalletModel wallet;

  const _WalletDetailContent({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppColors.spaceLG),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
              ),
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.currencyEtb} ${wallet.balance}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppColors.spaceLG),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.walletInformation,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppColors.spaceMD),
                _DetailRow(label: l10n.walletDetailName, value: wallet.name),
                _DetailRow(label: l10n.walletDetailType, value: wallet.type),
                _DetailRow(
                  label: l10n.walletDetailCurrencyLabel,
                  value: l10n.currencyEtb,
                ),
                _DetailRow(
                  label: l10n.balance,
                  value: '${l10n.currencyEtb} ${wallet.balance}',
                ),
                if (wallet.createdAt != null)
                  _DetailRow(label: l10n.created, value: wallet.createdAt!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
