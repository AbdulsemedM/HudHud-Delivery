import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return BlocProvider(
      create: (_) => WalletBloc(
        walletRepository: WalletRepository(
          walletDataProvider: WalletDataProvider(
            apiService: ApiService.instance,
          ),
        ),
      )..add(FetchWalletEvent(walletId: walletId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wallet Details'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state is WalletDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WalletDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => context
                            .read<WalletBloc>()
                            .add(FetchWalletEvent(walletId: walletId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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

class _WalletDetailContent extends StatelessWidget {
  final WalletModel wallet;

  const _WalletDetailContent({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown[300]!,
                  Colors.orange[200]!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ETB ${wallet.balance}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _DetailRow(label: 'Name', value: wallet.name),
                _DetailRow(label: 'Type', value: wallet.type),
                const _DetailRow(label: 'Currency', value: 'ETB'),
                _DetailRow(
                    label: 'Balance',
                    value: 'ETB ${wallet.balance}'),
                if (wallet.createdAt != null)
                  _DetailRow(label: 'Created', value: wallet.createdAt!),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
