part of 'wallet_bloc.dart';

@immutable
sealed class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

final class WalletInitial extends WalletState {}

final class WalletLoading extends WalletState {}

final class WalletsLoaded extends WalletState {
  final List<WalletModel> wallets;
  final int currentPage;
  final int lastPage;
  final int total;
  final List<WalletTransactionModel>? transactions;
  final int transactionsPage;
  final int transactionsLastPage;
  final int transactionsTotal;

  const WalletsLoaded({
    required this.wallets,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.transactions,
    this.transactionsPage = 1,
    this.transactionsLastPage = 1,
    this.transactionsTotal = 0,
  });
  @override
  List<Object?> get props => [
        wallets,
        currentPage,
        lastPage,
        total,
        transactions,
        transactionsPage,
        transactionsLastPage,
        transactionsTotal,
      ];
}

final class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});
  @override
  List<Object?> get props => [message];
}

final class WalletDetailLoading extends WalletState {}

final class WalletDetailLoaded extends WalletState {
  final WalletModel wallet;

  const WalletDetailLoaded({required this.wallet});
  @override
  List<Object?> get props => [wallet];
}

final class WalletDetailError extends WalletState {
  final String message;

  const WalletDetailError({required this.message});
  @override
  List<Object?> get props => [message];
}

final class AddFundsLoading extends WalletState {}

final class AddFundsSuccess extends WalletState {
  final String message;
  final Map<String, dynamic>? payment;

  const AddFundsSuccess({required this.message, this.payment});
  @override
  List<Object?> get props => [message, payment];
}

final class AddFundsError extends WalletState {
  final String message;

  const AddFundsError({required this.message});
  @override
  List<Object?> get props => [message];
}

final class WithdrawFundsLoading extends WalletState {}

final class WithdrawFundsSuccess extends WalletState {
  final String message;
  final Map<String, dynamic>? payment;

  const WithdrawFundsSuccess({required this.message, this.payment});
  @override
  List<Object?> get props => [message, payment];
}

final class WithdrawFundsError extends WalletState {
  final String message;

  const WithdrawFundsError({required this.message});
  @override
  List<Object?> get props => [message];
}
