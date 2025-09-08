part of 'checkout_bloc.dart';

@immutable
sealed class CheckoutState {}

final class CheckoutInitial extends CheckoutState {}

final class CheckoutLoading extends CheckoutState {}

final class OrderCreatedSuccess extends CheckoutState {
  final Map<String, dynamic> orderData;
  final String message;

   OrderCreatedSuccess({
    required this.orderData,
    required this.message,
  });
}

final class CheckoutError extends CheckoutState {
  final String message;

   CheckoutError({required this.message});
}

final class OrderHistoryLoaded extends CheckoutState {
  final List<dynamic> orders;

   OrderHistoryLoaded({required this.orders});
}
