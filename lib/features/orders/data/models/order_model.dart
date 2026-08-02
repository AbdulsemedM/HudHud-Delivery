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
  final CustomerModel? customer;
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
    this.customer,
    this.driver,
  });

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static VendorModel _parseVendor(dynamic raw) {
    if (raw is! Map) {
      return VendorModel(
        id: 0,
        name: 'Vendor',
        email: '',
        phone: '',
        type: 'vendor',
        status: 'active',
        avatar: '',
        language: 'en',
        timezone: 'UTC',
        referralCode: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['shop_name'] != null) {
      return VendorModel.fromVendorListJson(map);
    }
    return VendorModel.fromJson(map);
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: _parseInt(json['id']),
      orderNumber: json['order_number']?.toString() ?? '',
      userId: _parseInt(json['user_id']),
      vendorId: _parseInt(json['vendor_id']),
      driverId: json['driver_id'] != null ? _parseInt(json['driver_id']) : null,
      paymentId: json['payment_id'] != null ? _parseInt(json['payment_id']) : null,
      subtotal: json['subtotal']?.toString() ?? '0',
      deliveryFee: json['delivery_fee']?.toString() ?? '0',
      taxAmount: json['tax_amount']?.toString() ?? '0',
      discountAmount: json['discount_amount']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? '0',
      paymentMethod: json['payment_method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      deliveryNotes: json['delivery_notes']?.toString(),
      preparationTime: json['preparation_time'] != null ? _parseInt(json['preparation_time']) : null,
      isScheduled: json['is_scheduled'] == true,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())
          : null,
      preparingAt: json['preparing_at'] != null
          ? DateTime.tryParse(json['preparing_at'].toString())
          : null,
      readyAt: json['ready_at'] != null
          ? DateTime.tryParse(json['ready_at'].toString())
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'].toString())
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'].toString())
          : null,
      cancellationReason: json['cancellation_reason']?.toString(),
      cancelledBy: json['cancelled_by']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      vendor: _parseVendor(json['vendor']),
      customer: json['customer'] is Map
          ? CustomerModel.fromJson(
              Map<String, dynamic>.from(json['customer'] as Map),
            )
          : null,
      driver: json['driver'] is Map
          ? DriverModel.fromJson(
              Map<String, dynamic>.from(json['driver'] as Map),
            )
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
      'customer': customer?.toJson(),
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

  /// ETA from order preparation time when available.
  String? get estimatedDeliveryTime {
    if (preparationTime != null && preparationTime! > 0) {
      return '$preparationTime mins';
    }
    return null;
  }
  
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
  
  String? get formattedEstimatedDelivery => estimatedDeliveryTime;

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