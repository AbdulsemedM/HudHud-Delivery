part of 'wallet_bloc.dart';

@immutable
sealed class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

final class FetchBalanceEvent extends WalletEvent {
  const FetchBalanceEvent();
}

final class FetchTransactionsEvent extends WalletEvent {
  final int page;
  final int limit;

  const FetchTransactionsEvent({this.page = 1, this.limit = 20});
  @override
  List<Object?> get props => [page, limit];
}

final class AddFundsEvent extends WalletEvent {
  final double amount;
  final String paymentMethodCode;
  final String currency;
  final Map<String, dynamic>? paymentDetails;
  final String? idempotencyKey;

  const AddFundsEvent({
    required this.amount,
    required this.paymentMethodCode,
    required this.currency,
    this.paymentDetails,
    this.idempotencyKey,
  });
  @override
  List<Object?> get props =>
      [amount, paymentMethodCode, currency, paymentDetails, idempotencyKey];
}

final class WithdrawFundsEvent extends WalletEvent {
  final double amount;
  final String paymentMethodCode;
  final String currency;
  final int walletId;
  final Map<String, dynamic>? paymentDetails;
  final String? idempotencyKey;

  const WithdrawFundsEvent({
    required this.amount,
    required this.paymentMethodCode,
    required this.currency,
    required this.walletId,
    this.paymentDetails,
    this.idempotencyKey,
  });
  @override
  List<Object?> get props => [
        amount,
        paymentMethodCode,
        currency,
        walletId,
        paymentDetails,
        idempotencyKey,
      ];
}
