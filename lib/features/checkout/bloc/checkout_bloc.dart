import 'package:bloc/bloc.dart';
// import 'package:flutter/foundation.dart';
import '../data/repository/checkout_repository.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CheckoutRepository checkoutRepository;

  CheckoutBloc({required this.checkoutRepository}) : super(CheckoutInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<LoadOrderHistoryEvent>(_onLoadOrderHistory);
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    
    try {
      final result = await checkoutRepository.createOrder(
        vendorId: event.vendorId,
        items: event.items,
        taxAmount: event.taxAmount,
        discountAmount: event.discountAmount,
        deliveryAddress: event.deliveryAddress,
        deliveryLocation: event.deliveryLocation,
        deliveryLatitude: event.deliveryLatitude,
        deliveryLongitude: event.deliveryLongitude,
        paymentMethod: event.paymentMethod,
        couponCode: event.couponCode,
        serviceType: event.serviceType,
        notes: event.notes,
      );

      if (result['success'] == true) {
        emit(OrderCreatedSuccess(
          orderData: result['data'] ?? {},
          message: result['message'] ?? 'Order created successfully',
        ));
      } else {
        emit(CheckoutError(
          message: result['message'] ?? 'Failed to create order',
        ));
      }
    } catch (e) {
      emit(CheckoutError(
        message: 'An unexpected error occurred: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadOrderHistory(
    LoadOrderHistoryEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    
    try {
      final orders = await checkoutRepository.getOrderHistory();
      emit(OrderHistoryLoaded(orders: orders));
    } catch (e) {
      emit(CheckoutError(
        message: 'Failed to load order history: ${e.toString()}',
      ));
    }
  }
}
