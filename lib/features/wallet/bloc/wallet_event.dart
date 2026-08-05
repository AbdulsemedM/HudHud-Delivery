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

  const AddFundsEvent({
    required this.amount,
    required this.paymentMethodCode,
    required this.currency,
    this.paymentDetails,
  });
  @override
  List<Object?> get props =>
      [amount, paymentMethodCode, currency, paymentDetails];
}

final class WithdrawFundsEvent extends WalletEvent {
  final double amount;
  final String paymentMethodCode;
  final Map<String, dynamic>? paymentDetails;

  const WithdrawFundsEvent({
    required this.amount,
    required this.paymentMethodCode,
    this.paymentDetails,
  });
  @override
  List<Object?> get props => [amount, paymentMethodCode, paymentDetails];
}
