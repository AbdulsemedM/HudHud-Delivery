import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../data/models/wallet_model.dart';
import '../data/models/wallet_transaction_model.dart';
import '../data/repositories/wallet_repository.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;

  WalletBloc({required this.walletRepository}) : super(WalletInitial()) {
    on<FetchWalletsEvent>(_onFetchWallets);
    on<FetchWalletEvent>(_onFetchWallet);
    on<FetchTransactionsEvent>(_onFetchTransactions);
    on<AddFundsEvent>(_onAddFunds);
    on<WithdrawFundsEvent>(_onWithdrawFunds);
  }

  Future<void> _onWithdrawFunds(
    WithdrawFundsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WithdrawFundsLoading());
    try {
      final response = await walletRepository.withdraw(
        amount: event.amount,
        method: event.method,
        currency: event.currency,
        walletId: event.walletId,
        payerId: event.payerId,
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

  Future<void> _onAddFunds(
    AddFundsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(AddFundsLoading());
    try {
      final response = await walletRepository.addFunds(
        amount: event.amount,
        method: event.method,
        currency: event.currency,
        payerId: event.payerId,
        walletId: event.walletId,
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

  Future<void> _onFetchWallet(
    FetchWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletDetailLoading());
    try {
      final wallet = await walletRepository.getWallet(event.walletId);
      if (wallet != null) {
        emit(WalletDetailLoaded(wallet: wallet));
      } else {
        emit(const WalletDetailError(message: 'Wallet not found'));
      }
    } catch (e) {
      emit(WalletDetailError(message: e.toString()));
    }
  }

  Future<void> _onFetchWallets(
    FetchWalletsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      final response = await walletRepository.getWallets(page: event.page);
      emit(WalletsLoaded(
        wallets: response.wallets,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      ));
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
    if (currentState is! WalletsLoaded) return;

    try {
      final response = await walletRepository.getTransactions(page: event.page);
      emit(WalletsLoaded(
        wallets: currentState.wallets,
        currentPage: currentState.currentPage,
        lastPage: currentState.lastPage,
        total: currentState.total,
        transactions: response.transactions,
        transactionsPage: response.currentPage,
        transactionsLastPage: response.lastPage,
        transactionsTotal: response.total,
      ));
    } catch (_) {
      emit(WalletsLoaded(
        wallets: currentState.wallets,
        currentPage: currentState.currentPage,
        lastPage: currentState.lastPage,
        total: currentState.total,
        transactions: currentState.transactions ?? [],
      ));
    }
  }
}
