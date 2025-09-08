import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'order_item_model.dart';
import 'vendor_model.dart';
import 'customer_model.dart';
import 'driver_model.dart';

class OrderModel extends Equatable {
  final int id;
  final String orderNumber;
  final int userId;
  final int vendorId;
  final int? driverId;
  final int? paymentId;
  final String subtotal;
  final String deliveryFee;
  final String taxAmount;
  final String discountAmount;
  final String totalAmount;
  final String paymentMethod;
  final String status;
  final String deliveryAddress;
  final String? deliveryNotes;
  final int? preparationTime;
  final bool isScheduled;
  final DateTime? scheduledAt;
  final DateTime? acceptedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;
  final VendorModel vendor;
  final CustomerModel customer;
  final DriverModel? driver;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.vendorId,
    this.driverId,
    this.paymentId,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.deliveryAddress,
    this.deliveryNotes,
    this.preparationTime,
    required this.isScheduled,
    this.scheduledAt,
    this.acceptedAt,
    this.preparingAt,
    this.readyAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.vendor,
    required this.customer,
    this.driver,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      userId: json['user_id'],
      vendorId: json['vendor_id'],
      driverId: json['driver_id'],
      paymentId: json['payment_id'],
      subtotal: json['subtotal'],
      deliveryFee: json['delivery_fee'],
      taxAmount: json['tax_amount'],
      discountAmount: json['discount_amount'],
      totalAmount: json['total_amount'],
      paymentMethod: json['payment_method'],
      status: json['status'],
      deliveryAddress: json['delivery_address'],
      deliveryNotes: json['delivery_notes'],
      preparationTime: json['preparation_time'],
      isScheduled: json['is_scheduled'],
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.parse(json['scheduled_at']) 
          : null,
      acceptedAt: json['accepted_at'] != null 
          ? DateTime.parse(json['accepted_at']) 
          : null,
      preparingAt: json['preparing_at'] != null 
          ? DateTime.parse(json['preparing_at']) 
          : null,
      readyAt: json['ready_at'] != null 
          ? DateTime.parse(json['ready_at']) 
          : null,
      pickedUpAt: json['picked_up_at'] != null 
          ? DateTime.parse(json['picked_up_at']) 
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at']) 
          : null,
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.parse(json['cancelled_at']) 
          : null,
      cancellationReason: json['cancellation_reason'],
      cancelledBy: json['cancelled_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      vendor: VendorModel.fromJson(json['vendor']),
      customer: CustomerModel.fromJson(json['customer']),
      driver: json['driver'] != null 
          ? DriverModel.fromJson(json['driver']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user_id': userId,
      'vendor_id': vendorId,
      'driver_id': driverId,
      'payment_id': paymentId,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_notes': deliveryNotes,
      'preparation_time': preparationTime,
      'is_scheduled': isScheduled,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'preparing_at': preparingAt?.toIso8601String(),
      'ready_at': readyAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'vendor': vendor.toJson(),
      'customer': customer.toJson(),
      'driver': driver?.toJson(),
    };
  }

  // Helper methods for order status
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isPreparing => status == 'preparing';
  bool get isReadyForPickup => status == 'ready_for_pickup';
  bool get isPickedUp => status == 'picked_up';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  
  bool get canBeCancelled => isPending || isAccepted || isPreparing;
  
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Order Pending';
      case 'accepted':
        return 'Order Accepted';
      case 'preparing':
        return 'Preparing Order';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'picked_up':
        return 'Order Picked Up';
      case 'delivered':
        return 'Order Delivered';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return status.toUpperCase();
    }
  }
  
  String get formattedTotal {
    try {
      final total = double.parse(totalAmount);
      return '\$${total.toStringAsFixed(2)}';
    } catch (e) {
      return totalAmount;
    }
  }
  
  double get discount {
    try {
      return double.parse(discountAmount);
    } catch (e) {
      return 0.0;
    }
  }
  
  String get formattedDiscount {
    try {
      final discount = double.parse(discountAmount);
      return '\$${discount.toStringAsFixed(2)}';
    } catch (e) {
      return discountAmount;
    }
  }
  
  String get formattedDeliveryFee {
    try {
      final fee = double.parse(deliveryFee);
      return '\$${fee.toStringAsFixed(2)}';
    } catch (e) {
      return deliveryFee;
    }
  }
  
  String get formattedTax {
    try {
      final tax = double.parse(taxAmount);
      return '\$${tax.toStringAsFixed(2)}';
    } catch (e) {
      return taxAmount;
    }
  }
  
  String get formattedSubtotal {
    try {
      final sub = double.parse(subtotal);
      return '\$${sub.toStringAsFixed(2)}';
    } catch (e) {
      return subtotal;
    }
  }
  
  String get paymentStatus {
    // This is a placeholder - you may want to implement actual payment status logic
    return paymentMethod == 'cash' ? 'Cash on Delivery' : 'Paid Online';
  }
  
  Color get paymentStatusColor {
    // Import flutter/material.dart in the widget file, not here
    // This is a placeholder - return a basic color indication
    return paymentMethod == 'cash' ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);
  }
  
  String? get formattedDeliveredAt {
    if (deliveredAt == null) return null;
    return '${deliveredAt!.hour.toString().padLeft(2, '0')}:${deliveredAt!.minute.toString().padLeft(2, '0')}';
  }
  
  // Placeholder for out for delivery timestamp - you may want to add this field to the model
  DateTime? get outForDeliveryAt => pickedUpAt;
  
  String? get formattedOutForDeliveryAt {
    if (outForDeliveryAt == null) return null;
    return '${outForDeliveryAt!.hour.toString().padLeft(2, '0')}:${outForDeliveryAt!.minute.toString().padLeft(2, '0')}';
  }
  
  bool get isOutForDelivery => status == 'out_for_delivery' || isPickedUp;
  
  String? get formattedReadyForPickupAt {
    if (readyForPickupAt == null) return null;
    return '${readyForPickupAt!.hour.toString().padLeft(2, '0')}:${readyForPickupAt!.minute.toString().padLeft(2, '0')}';
  }
  
  // Additional missing getters
  DateTime? get confirmedAt => acceptedAt; // Using acceptedAt as placeholder
  DateTime? get readyForPickupAt => readyAt; // Using readyAt field
  String? get estimatedDeliveryTime => '30-45 mins'; // Placeholder
  
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
  
  String? get formattedConfirmedAt {
    if (confirmedAt == null) return null;
    return '${confirmedAt!.hour.toString().padLeft(2, '0')}:${confirmedAt!.minute.toString().padLeft(2, '0')}';
  }
  
  String? get formattedPreparingAt {
    if (preparingAt == null) return null;
    return '${preparingAt!.hour.toString().padLeft(2, '0')}:${preparingAt!.minute.toString().padLeft(2, '0')}';
  }
  
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready_for_pickup':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
  
  bool get isConfirmed => status == 'confirmed' || isPreparing || isReadyForPickup || isOutForDelivery || isDelivered;
  
  String get formattedEstimatedDelivery {
    return estimatedDeliveryTime ?? '30-45 mins';
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        userId,
        vendorId,
        driverId,
        paymentId,
        subtotal,
        deliveryFee,
        taxAmount,
        discountAmount,
        totalAmount,
        paymentMethod,
        status,
        deliveryAddress,
        deliveryNotes,
        preparationTime,
        isScheduled,
        scheduledAt,
        acceptedAt,
        preparingAt,
        readyAt,
        pickedUpAt,
        deliveredAt,
        cancelledAt,
        cancellationReason,
        cancelledBy,
        createdAt,
        updatedAt,
        items,
        vendor,
        customer,
        driver,
      ];
}