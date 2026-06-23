part of 'tips_bloc.dart';

sealed class TipsState {
  const TipsState();
}

class TipsInitial extends TipsState {
  const TipsInitial();
}

class TipsLoading extends TipsState {
  const TipsLoading();
}

class TipsLoaded extends TipsState {
  final List<TipRateModel> rates;
  final TipCalculateResult? calculateResult;
  final bool isCalculating;
  final bool isSubmitting;
  final bool tipSubmitted;
  final TipAddWalletResult? lastAddResult;
  final List<TipHistoryItemModel> history;
  final TipHistoryStats stats;
  final String? statusFilter;
  final int currentPage;
  final bool hasMoreHistory;
  final bool isLoadingMore;

  const TipsLoaded({
    this.rates = const [],
    this.calculateResult,
    this.isCalculating = false,
    this.isSubmitting = false,
    this.tipSubmitted = false,
    this.lastAddResult,
    this.history = const [],
    this.stats = const TipHistoryStats(),
    this.statusFilter,
    this.currentPage = 1,
    this.hasMoreHistory = false,
    this.isLoadingMore = false,
  });

  TipsLoaded copyWith({
    List<TipRateModel>? rates,
    TipCalculateResult? calculateResult,
    bool? isCalculating,
    bool? isSubmitting,
    bool? tipSubmitted,
    TipAddWalletResult? lastAddResult,
    List<TipHistoryItemModel>? history,
    TipHistoryStats? stats,
    String? statusFilter,
    int? currentPage,
    bool? hasMoreHistory,
    bool? isLoadingMore,
    bool clearCalculate = false,
    bool clearAddResult = false,
  }) {
    return TipsLoaded(
      rates: rates ?? this.rates,
      calculateResult:
          clearCalculate ? null : (calculateResult ?? this.calculateResult),
      isCalculating: isCalculating ?? this.isCalculating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      tipSubmitted: tipSubmitted ?? this.tipSubmitted,
      lastAddResult:
          clearAddResult ? null : (lastAddResult ?? this.lastAddResult),
      history: history ?? this.history,
      stats: stats ?? this.stats,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TipsError extends TipsState {
  final String message;
  const TipsError(this.message);
}
