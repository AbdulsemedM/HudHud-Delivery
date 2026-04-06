part of 'checkout_bloc.dart';

sealed class CheckoutEvent {}

class CreateOrderEvent extends CheckoutEvent {
  final int vendorId;
  final List<Map<String, dynamic>> items;
  final double taxAmount;
  final double discountAmount;
  final String deliveryAddress;
  final String deliveryLocation;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String paymentMethod;
  final String? notes;

  CreateOrderEvent({
    required this.vendorId,
    required this.items,
    required this.taxAmount,
    required this.discountAmount,
    required this.deliveryAddress,
    required this.deliveryLocation,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.paymentMethod,
    this.notes,
  });
}

class LoadOrderHistoryEvent extends CheckoutEvent {}
