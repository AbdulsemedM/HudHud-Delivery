import 'package:flutter/material.dart';

import 'package:hudhud_delivery/features/courier/presentation/screens/delivery_tracking_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/finding_courier_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/active_delivery_card.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';

/// Finding vs live-tracking screen from a delivery payload.
Widget courierLiveJobScreenFromDelivery(Map<String, dynamic> delivery) {
  final deliveryId = delivery['id'] is int
      ? delivery['id'] as int
      : int.tryParse(delivery['id']?.toString() ?? '');
  final pickup = parseDeliveryLatLng(
    delivery['pickup_latitude'],
    delivery['pickup_longitude'],
  );
  final dropoff = parseDeliveryLatLng(
    delivery['dropoff_latitude'],
    delivery['dropoff_longitude'],
  );
  final pickupLocation = delivery['pickup_location']?.toString() ?? '';
  final deliveryLocation = delivery['dropoff_location']?.toString() ?? '';
  final selectedVehicle = delivery['vehicle_type']?.toString() ?? 'motorbike';
  final itemType = delivery['package_type']?.toString() ?? '';
  final quantity = delivery['package_weight']?.toString() ?? '1';
  final paymentType = delivery['payment_method']?.toString() ?? 'cash';
  final recipientName = delivery['receiver_name']?.toString() ?? '';
  final recipientPhone = delivery['receiver_phone']?.toString() ?? '';

  if (isDeliverySearchingForDriver(resolveDeliveryStatus(delivery))) {
    return FindingCourierScreen(
      deliveryId: deliveryId,
      pickupLocation: pickupLocation,
      deliveryLocation: deliveryLocation,
      pickupPosition: pickup,
      deliveryPosition: dropoff,
      selectedVehicle: selectedVehicle,
      itemType: itemType,
      quantity: quantity,
      whoPays: 'me',
      paymentType: paymentType,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
    );
  }

  return DeliveryTrackingScreen(
    deliveryId: deliveryId,
    pickupLocation: pickupLocation,
    deliveryLocation: deliveryLocation,
    pickupPosition: pickup,
    deliveryPosition: dropoff,
    selectedVehicle: selectedVehicle,
    itemType: itemType,
    quantity: quantity,
    whoPays: 'me',
    paymentType: paymentType,
    recipientName: recipientName,
    recipientPhone: recipientPhone,
  );
}
