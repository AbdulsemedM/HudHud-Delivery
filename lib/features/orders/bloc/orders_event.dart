part of 'orders_bloc.dart';

@immutable
sealed class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrdersEvent extends OrdersEvent {
  final int page;
  final int perPage;
  final String? status;

  const FetchOrdersEvent({
    this.page = 1,
    this.perPage = 10,
    this.status,
  });

  @override
  List<Object?> get props => [page, perPage, status];
}

class RefreshOrdersEvent extends OrdersEvent {
  const RefreshOrdersEvent();
}

class LoadMoreOrdersEvent extends OrdersEvent {
  const LoadMoreOrdersEvent();
}

class FetchOrderDetailsEvent extends OrdersEvent {
  final int orderId;

  const FetchOrderDetailsEvent(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class CancelOrderEvent extends OrdersEvent {
  final int orderId;
  final String? reason;

  const CancelOrderEvent(this.orderId, {this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

class FilterOrdersByStatusEvent extends OrdersEvent {
  final String? status;

  const FilterOrdersByStatusEvent(this.status);

  @override
  List<Object?> get props => [status];
}
