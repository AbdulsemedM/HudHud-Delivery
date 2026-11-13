import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../../cancellation/data/cancellation_models.dart';
import '../data/repositories/orders_repository.dart';
import '../data/models/order_cancel_result.dart';
import '../data/models/order_model.dart';
import '../data/models/order_tracking_model.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository ordersRepository;
  
  OrdersBloc({required this.ordersRepository}) : super(OrdersInitial()) {
    on<FetchOrdersEvent>(_onFetchOrders);
    on<RefreshOrdersEvent>(_onRefreshOrders);
    on<LoadMoreOrdersEvent>(_onLoadMoreOrders);
    on<FetchOrderDetailsEvent>(_onFetchOrderDetails);
    on<CancelOrderEvent>(_onCancelOrder);
    on<RateOrderEvent>(_onRateOrder);
    on<FilterOrdersByStatusEvent>(_onFilterOrdersByStatus);
  }

  Future<void> _onFetchOrders(
    FetchOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    
    try {
      final ordersResponse = await ordersRepository.fetchOrders(
        page: event.page,
        perPage: event.perPage,
        status: event.status,
      );
      
      emit(OrdersLoaded(
        orders: ordersResponse.data,
        hasReachedMax: ordersResponse.data.length < event.perPage,
        currentPage: event.page,
        currentFilter: event.status,
      ));
    } catch (e) {
      emit(_errorFrom(e));
    }
  }

  Future<void> _onRefreshOrders(
    RefreshOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    String? currentFilter;
    
    if (currentState is OrdersLoaded) {
      currentFilter = currentState.currentFilter;
    }
    
    add(FetchOrdersEvent(page: 1, status: currentFilter));
  }

  Future<void> _onLoadMoreOrders(
    LoadMoreOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is OrdersLoaded && !currentState.hasReachedMax) {
      emit(OrdersLoadingMore(currentState.orders));
      
      try {
        final newOrdersResponse = await ordersRepository.fetchOrders(
          page: currentState.currentPage + 1,
          status: currentState.currentFilter,
        );
        
        emit(currentState.copyWith(
          orders: [...currentState.orders, ...newOrdersResponse.data],
          hasReachedMax: newOrdersResponse.data.length < 15,
          currentPage: currentState.currentPage + 1,
        ));
      } catch (_) {
        // Keep what is already on screen; the next scroll retries.
        emit(currentState);
      }
    }
  }

  Future<void> _onFetchOrderDetails(
    FetchOrderDetailsEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final previous = state;
    final OrderDetailsLoaded? keep =
        previous is OrderDetailsLoaded && previous.order.id == event.orderId
            ? previous
            : null;
    if (keep == null) {
      emit(OrderDetailsLoading());
    }

    try {
      final order = await ordersRepository.getOrderById(event.orderId);
      OrderTrackingModel? tracking;
      try {
        tracking = await ordersRepository.getOrderTracking(event.orderId);
      } catch (_) {
        // Tracking is optional; show order details even if tracking fails
        tracking = keep?.tracking;
      }
      emit(OrderDetailsLoaded(order, tracking: tracking));
    } catch (e) {
      if (keep != null) {
        // Keep last good snapshot on poll failure.
        emit(keep);
      } else {
        emit(_errorFrom(e));
      }
    }
  }

  Future<void> _onCancelOrder(
    CancelOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrderCancelling(event.orderId));
    
    try {
      final result = await ordersRepository.cancelOrder(
        event.orderId,
        reason: event.reason,
        acceptPenaltyPoints: event.acceptPenaltyPoints,
      );

      emit(OrderCancelled(
        event.orderId,
        'Order cancelled successfully',
        refund: result.refund,
        penalty: result.penalty,
      ));
      // Refresh orders list
      add(const RefreshOrdersEvent());
    } catch (e) {
      emit(_errorFrom(e));
    }
  }

  Future<void> _onRateOrder(
    RateOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final success = await ordersRepository.rateOrder(
        event.orderId,
        rating: event.rating,
        review: event.review,
      );

      if (success) {
        emit(OrderRated(event.orderId, 'Order rated successfully'));
        add(FetchOrderDetailsEvent(event.orderId));
      } else {
        emit(const OrdersError('Failed to rate order'));
      }
    } catch (e) {
      emit(_errorFrom(e));
    }
  }

  Future<void> _onFilterOrdersByStatus(
    FilterOrdersByStatusEvent event,
    Emitter<OrdersState> emit,
  ) async {
    add(FetchOrdersEvent(page: 1, status: event.status));
  }

  static OrdersError _errorFrom(Object e) {
    if (e is OrdersRepositoryException) {
      return OrdersError(e.message, statusCode: e.statusCode);
    }
    return OrdersError(e.toString());
  }
}
