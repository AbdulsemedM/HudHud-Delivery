part of 'tips_bloc.dart';

sealed class TipsEvent {
  const TipsEvent();
}

class LoadTipRatesEvent extends TipsEvent {
  const LoadTipRatesEvent();
}

class CalculateTipEvent extends TipsEvent {
  final int orderId;
  final int tipOptionId;
  final num? customAmount;

  const CalculateTipEvent({
    required this.orderId,
    required this.tipOptionId,
    this.customAmount,
  });
}

class SubmitTipEvent extends TipsEvent {
  final int orderId;
  final num amount;
  final int tipOptionId;
  final String recipientType;
  final String? message;
  final bool isAnonymous;

  const SubmitTipEvent({
    required this.orderId,
    required this.amount,
    required this.tipOptionId,
    required this.recipientType,
    this.message,
    this.isAnonymous = false,
  });
}

class LoadTipsHistoryEvent extends TipsEvent {
  final String? status;
  const LoadTipsHistoryEvent({this.status});
}

class LoadMoreTipsHistoryEvent extends TipsEvent {
  const LoadMoreTipsHistoryEvent();
}

class ResetTipOrderEvent extends TipsEvent {
  const ResetTipOrderEvent();
}
