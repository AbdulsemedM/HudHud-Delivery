import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../data/models/wallet_balance_model.dart';
import '../data/models/wallet_transaction_model.dart';
import '../data/repositories/wallet_repository.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;

  WalletBloc({required this.walletRepository}) : super(WalletInitial()) {
    on<FetchBalanceEvent>(_onFetchBalance);
    on<FetchTransactionsEvent>(_onFetchTransactions);
    on<AddFundsEvent>(_onAddFunds);
    on<WithdrawFundsEvent>(_onWithdrawFunds);
  }

  Future<void> _onFetchBalance(
    FetchBalanceEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      final balance = await walletRepository.getBalance();
      emit(BalanceLoaded(balance: balance));
      add(const FetchTransactionsEvent());
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  Future<void> _onFetchTransactions(
    FetchTransactionsEvent event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BalanceLoaded) return;

    try {
      final response = await walletRepository.getTransactions(
        page: event.page,
        limit: event.limit,
      );
      emit(currentState.copyWith(
        transactions: response.transactions,
        transactionsPage: response.currentPage,
        transactionsLastPage: response.lastPage,
        transactionsTotal: response.total,
      ));
    } catch (_) {
      // Keep balance visible even if transactions fail.
      emit(currentState.copyWith(transactions: currentState.transactions));
    }
  }

  Future<void> _onAddFunds(
    AddFundsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(AddFundsLoading());
    try {
      final response = await walletRepository.topUp(
        amount: event.amount,
        paymentMethodCode: event.paymentMethodCode,
        currency: event.currency,
        paymentDetails: event.paymentDetails,
      );
      emit(AddFundsSuccess(
        message: response.message,
        payment: response.payment,
      ));
    } catch (e) {
      emit(AddFundsError(message: e.toString()));
    }
  }

  Future<void> _onWithdrawFunds(
    WithdrawFundsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WithdrawFundsLoading());
    try {
      final response = await walletRepository.withdraw(
        amount: event.amount,
        paymentMethodCode: event.paymentMethodCode,
        paymentDetails: event.paymentDetails,
      );
      emit(WithdrawFundsSuccess(
        message: response.message,
        payment: response.payment,
      ));
    } catch (e) {
      emit(WithdrawFundsError(message: e.toString()));
    }
  }
}
