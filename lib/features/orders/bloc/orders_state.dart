part of 'orders_bloc.dart';

@immutable
sealed class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

final class OrdersInitial extends OrdersState {}

final class OrdersLoading extends OrdersState {
  final List<OrderModel> orders;

  const OrdersLoading({this.orders = const []});

  @override
  List<Object?> get props => [orders];
}

final class OrdersLoadingMore extends OrdersState {
  final List<OrderModel> currentOrders;

  const OrdersLoadingMore(this.currentOrders);

  @override
  List<Object?> get props => [currentOrders];
}

final class OrdersLoaded extends OrdersState {
  final List<OrderModel> orders;
  final bool hasReachedMax;
  final int currentPage;
  final String? currentFilter;

  const OrdersLoaded({
    required this.orders,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.currentFilter,
  });

  OrdersLoaded copyWith({
    List<OrderModel>? orders,
    bool? hasReachedMax,
    int? currentPage,
    String? currentFilter,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  @override
  List<Object?> get props => [orders, hasReachedMax, currentPage, currentFilter];
}

final class OrderDetailsLoading extends OrdersState {}

final class OrderDetailsLoaded extends OrdersState {
  final OrderModel order;
  final OrderTrackingModel? tracking;

  const OrderDetailsLoaded(this.order, {this.tracking});

  @override
  List<Object?> get props => [order, tracking];
}

final class OrderCancelling extends OrdersState {
  final int orderId;

  const OrderCancelling(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

final class OrderCancelled extends OrdersState {
  final int orderId;
  final String message;

  const OrderCancelled(this.orderId, this.message);

  @override
  List<Object?> get props => [orderId, message];
}

final class OrderRated extends OrdersState {
  final int orderId;
  final String message;

  const OrderRated(this.orderId, this.message);

  @override
  List<Object?> get props => [orderId, message];
}

final class OrdersError extends OrdersState {
  final String message;
  final List<OrderModel> orders;

  const OrdersError(this.message, {this.orders = const []});

  @override
  List<Object?> get props => [message, orders];
}
