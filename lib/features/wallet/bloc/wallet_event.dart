part of 'wallet_bloc.dart';

@immutable
sealed class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

final class FetchWalletsEvent extends WalletEvent {
  final int page;

  const FetchWalletsEvent({this.page = 1});
  @override
  List<Object?> get props => [page];
}

final class FetchWalletEvent extends WalletEvent {
  final int walletId;

  const FetchWalletEvent({required this.walletId});
  @override
  List<Object?> get props => [walletId];
}

final class FetchTransactionsEvent extends WalletEvent {
  final int page;

  const FetchTransactionsEvent({this.page = 1});
  @override
  List<Object?> get props => [page];
}

final class AddFundsEvent extends WalletEvent {
  final double amount;
  final String method;
  final String currency;
  final int? payerId;
  final int? walletId;
  final Map<String, dynamic>? paymentDetails;

  const AddFundsEvent({
    required this.amount,
    required this.method,
    required this.currency,
    this.payerId,
    this.walletId,
    this.paymentDetails,
  });
  @override
  List<Object?> get props =>
      [amount, method, currency, payerId, walletId, paymentDetails];
}

final class WithdrawFundsEvent extends WalletEvent {
  final double amount;
  final String method;
  final String currency;
  final int walletId;
  final int? payerId;
  final Map<String, dynamic>? paymentDetails;

  const WithdrawFundsEvent({
    required this.amount,
    required this.method,
    required this.currency,
    required this.walletId,
    this.payerId,
    this.paymentDetails,
  });
  @override
  List<Object?> get props =>
      [amount, method, currency, walletId, payerId, paymentDetails];
}
