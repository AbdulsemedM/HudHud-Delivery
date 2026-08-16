part of 'wallet_bloc.dart';

/// Client-side top-up phases from the API handoff.
enum WalletTopUpPhase {
  idle,
  initiating,
  pending,
  completed,
  failed,
  duplicateReplay,
}

/// Client-side withdrawal phases from the API handoff.
enum WalletWithdrawPhase {
  idle,
  submitted,
  pending,
  approved,
  rejected,
  failed,
}

@immutable
sealed class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

final class WalletInitial extends WalletState {}

final class WalletLoading extends WalletState {}

final class BalanceLoaded extends WalletState {
  final WalletBalance balance;
  final List<WalletTransactionModel> transactions;
  final int transactionsPage;
  final int transactionsLastPage;
  final int transactionsTotal;

  const BalanceLoaded({
    required this.balance,
    this.transactions = const [],
    this.transactionsPage = 1,
    this.transactionsLastPage = 1,
    this.transactionsTotal = 0,
  });

  BalanceLoaded copyWith({
    WalletBalance? balance,
    List<WalletTransactionModel>? transactions,
    int? transactionsPage,
    int? transactionsLastPage,
    int? transactionsTotal,
  }) {
    return BalanceLoaded(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      transactionsPage: transactionsPage ?? this.transactionsPage,
      transactionsLastPage: transactionsLastPage ?? this.transactionsLastPage,
      transactionsTotal: transactionsTotal ?? this.transactionsTotal,
    );
  }

  @override
  List<Object?> get props => [
        balance,
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

final class AddFundsLoading extends WalletState {
  const AddFundsLoading();
}

final class AddFundsSuccess extends WalletState {
  final String message;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? rawData;
  final WalletTopUpPhase phase;

  const AddFundsSuccess({
    required this.message,
    this.payment,
    this.rawData,
    this.phase = WalletTopUpPhase.pending,
  });

  /// Full initiate-shaped map for [PaymentInitiateResult.fromJson].
  Map<String, dynamic> get initiateEnvelope => {
        'success': true,
        'message': message,
        'data': rawData ??
            (payment != null
                ? <String, dynamic>{'payment': payment}
                : <String, dynamic>{}),
      };

  bool get isPending =>
      phase == WalletTopUpPhase.pending ||
      phase == WalletTopUpPhase.duplicateReplay;

  @override
  List<Object?> get props => [message, payment, rawData, phase];
}

final class AddFundsError extends WalletState {
  final String message;
  final WalletTopUpPhase phase;

  const AddFundsError({
    required this.message,
    this.phase = WalletTopUpPhase.failed,
  });
  @override
  List<Object?> get props => [message, phase];
}

final class WithdrawFundsLoading extends WalletState {
  const WithdrawFundsLoading();
}

final class WithdrawFundsSuccess extends WalletState {
  final String message;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? rawData;
  final WalletWithdrawPhase phase;

  const WithdrawFundsSuccess({
    required this.message,
    this.payment,
    this.rawData,
    this.phase = WalletWithdrawPhase.submitted,
  });

  Map<String, dynamic> get initiateEnvelope => {
        'success': true,
        'message': message,
        'data': rawData ??
            (payment != null
                ? <String, dynamic>{'payment': payment}
                : <String, dynamic>{}),
      };

  @override
  List<Object?> get props => [message, payment, rawData, phase];
}

final class WithdrawFundsError extends WalletState {
  final String message;
  final WalletWithdrawPhase phase;

  const WithdrawFundsError({
    required this.message,
    this.phase = WalletWithdrawPhase.failed,
  });
  @override
  List<Object?> get props => [message, phase];
}
