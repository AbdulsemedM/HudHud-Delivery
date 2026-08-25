import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../core/api/api_service.dart';
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
      emit(WalletError(message: userFacingApiError(e)));
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
      emit(currentState.copyWith(transactions: currentState.transactions));
    }
  }

  Future<void> _onAddFunds(
    AddFundsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const AddFundsLoading());
    try {
      final response = await walletRepository.topUp(
        amount: event.amount,
        paymentMethodCode: event.paymentMethodCode,
        currency: event.currency,
        paymentDetails: event.paymentDetails,
        idempotencyKey: event.idempotencyKey,
      );
      emit(AddFundsSuccess(
        message: response.message,
        payment: response.payment,
        rawData: response.rawData,
        phase: _topUpPhase(response.payment, response.rawData),
      ));
    } catch (e) {
      emit(AddFundsError(message: userFacingApiError(e)));
    }
  }

  Future<void> _onWithdrawFunds(
    WithdrawFundsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WithdrawFundsLoading());
    try {
      final response = await walletRepository.withdraw(
        amount: event.amount,
        paymentMethodCode: event.paymentMethodCode,
        currency: event.currency,
        walletId: event.walletId,
        paymentDetails: event.paymentDetails,
        idempotencyKey: event.idempotencyKey,
      );
      emit(WithdrawFundsSuccess(
        message: response.message,
        payment: response.payment,
        rawData: response.rawData,
        phase: _withdrawPhase(response.payment),
      ));
    } catch (e) {
      emit(WithdrawFundsError(message: userFacingApiError(e)));
    }
  }

  WalletTopUpPhase _topUpPhase(
    Map<String, dynamic>? payment,
    Map<String, dynamic>? rawData,
  ) {
    if (rawData?['idempotent_replay'] == true) {
      return WalletTopUpPhase.duplicateReplay;
    }
    final status = payment?['status']?.toString().toLowerCase();
    if (status == 'completed') return WalletTopUpPhase.completed;
    if (status == 'failed' || status == 'cancelled') {
      return WalletTopUpPhase.failed;
    }
    return WalletTopUpPhase.pending;
  }

  WalletWithdrawPhase _withdrawPhase(Map<String, dynamic>? payment) {
    final status = payment?['status']?.toString().toLowerCase();
    switch (status) {
      case 'completed':
      case 'approved':
        return WalletWithdrawPhase.approved;
      case 'rejected':
      case 'failed':
      case 'cancelled':
        return WalletWithdrawPhase.rejected;
      case 'pending':
      case 'processing':
        return WalletWithdrawPhase.pending;
      default:
        return WalletWithdrawPhase.submitted;
    }
  }
}
