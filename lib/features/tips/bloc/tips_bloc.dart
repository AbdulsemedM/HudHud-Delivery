import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/tips/data/tips_repository.dart';
import 'package:hudhud_delivery/features/tips/model/tip_add_wallet_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_calculate_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_item_model.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_query.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_rate_model.dart';

part 'tips_event.dart';
part 'tips_state.dart';

class TipsBloc extends Bloc<TipsEvent, TipsState> {
  TipsBloc({TipsRepository? repository})
      : _repository = repository ?? TipsRepository(),
        super(const TipsInitial()) {
    on<LoadTipRatesEvent>(_onLoadRates);
    on<CalculateTipEvent>(_onCalculate);
    on<SubmitTipEvent>(_onSubmit);
    on<LoadTipsHistoryEvent>(_onLoadHistory);
    on<LoadMoreTipsHistoryEvent>(_onLoadMoreHistory);
    on<ResetTipOrderEvent>(_onResetOrder);
  }

  final TipsRepository _repository;

  TipsLoaded _currentOrEmpty() {
    final current = state;
    return current is TipsLoaded ? current : const TipsLoaded();
  }

  Future<void> _onLoadRates(
    LoadTipRatesEvent event,
    Emitter<TipsState> emit,
  ) async {
    final base = _currentOrEmpty();
    if (base.rates.isEmpty) {
      emit(const TipsLoading());
    }
    try {
      final rates = await _repository.getRates();
      emit(
        (state is TipsLoaded ? state as TipsLoaded : const TipsLoaded())
            .copyWith(rates: rates),
      );
    } catch (e) {
      emit(TipsError(e.toString()));
    }
  }

  Future<void> _onCalculate(
    CalculateTipEvent event,
    Emitter<TipsState> emit,
  ) async {
    final base = _currentOrEmpty();
    emit(base.copyWith(isCalculating: true, clearCalculate: true));
    try {
      final result = await _repository.calculateTip(
        orderId: event.orderId,
        tipOptionId: event.tipOptionId,
        customAmount: event.customAmount,
      );
      emit(
        _currentOrEmpty().copyWith(
          calculateResult: result,
          isCalculating: false,
        ),
      );
    } catch (e) {
      emit(_currentOrEmpty().copyWith(isCalculating: false));
      emit(TipsError(e.toString()));
    }
  }

  Future<void> _onSubmit(
    SubmitTipEvent event,
    Emitter<TipsState> emit,
  ) async {
    final base = _currentOrEmpty();
    emit(base.copyWith(isSubmitting: true, clearAddResult: true));
    try {
      final result = await _repository.addTipWallet(
        orderId: event.orderId,
        amount: event.amount,
        tipOptionId: event.tipOptionId,
        recipientType: event.recipientType,
        message: event.message,
        isAnonymous: event.isAnonymous,
      );
      emit(
        _currentOrEmpty().copyWith(
          isSubmitting: false,
          tipSubmitted: true,
          lastAddResult: result,
        ),
      );
    } catch (e) {
      emit(_currentOrEmpty().copyWith(isSubmitting: false));
      emit(TipsError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
    LoadTipsHistoryEvent event,
    Emitter<TipsState> emit,
  ) async {
    emit(const TipsLoading());
    try {
      final result = await _repository.getHistory(
        query: TipHistoryQuery(status: event.status ?? 'completed'),
      );
      emit(
        TipsLoaded(
          history: result.items,
          stats: result.stats,
          statusFilter: event.status ?? 'completed',
          currentPage: result.currentPage,
          hasMoreHistory: result.hasMore,
        ),
      );
    } catch (e) {
      emit(TipsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreTipsHistoryEvent event,
    Emitter<TipsState> emit,
  ) async {
    final current = state;
    if (current is! TipsLoaded ||
        !current.hasMoreHistory ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final result = await _repository.getHistory(
        query: TipHistoryQuery(
          status: current.statusFilter,
          page: nextPage,
        ),
      );
      emit(
        current.copyWith(
          history: [...current.history, ...result.items],
          currentPage: result.currentPage,
          hasMoreHistory: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
      emit(TipsError(e.toString()));
    }
  }

  void _onResetOrder(ResetTipOrderEvent event, Emitter<TipsState> emit) {
    final current = state;
    if (current is TipsLoaded) {
      emit(
        current.copyWith(
          tipSubmitted: false,
          clearCalculate: true,
          clearAddResult: true,
        ),
      );
    }
  }
}
