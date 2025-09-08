import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../data/repositories/orders_repository.dart';
import '../data/models/order_model.dart';

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
    on<FilterOrdersByStatusEvent>(_onFilterOrdersByStatus);
  }

  Future<void> _onFetchOrders(
    FetchOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    
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
      emit(OrdersError(e.toString()));
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
          hasReachedMax: newOrdersResponse.data.length < 10,
          currentPage: currentState.currentPage + 1,
        ));
      } catch (e) {
        emit(OrdersError(e.toString()));
      }
    }
  }

  Future<void> _onFetchOrderDetails(
    FetchOrderDetailsEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrderDetailsLoading());
    
    try {
      final order = await ordersRepository.getOrderById(event.orderId);
      emit(OrderDetailsLoaded(order));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onCancelOrder(
    CancelOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrderCancelling(event.orderId));
    
    try {
      final success = await ordersRepository.cancelOrder(
        event.orderId,
        reason: event.reason,
      );
      
      if (success) {
        emit(OrderCancelled(event.orderId, 'Order cancelled successfully'));
        // Refresh orders list
        add(const RefreshOrdersEvent());
      } else {
        emit(const OrdersError('Failed to cancel order'));
      }
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onFilterOrdersByStatus(
    FilterOrdersByStatusEvent event,
    Emitter<OrdersState> emit,
  ) async {
    add(FetchOrdersEvent(page: 1, status: event.status));
  }
}
