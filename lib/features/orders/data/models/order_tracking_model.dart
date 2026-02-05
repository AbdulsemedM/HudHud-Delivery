import 'package:equatable/equatable.dart';

class OrderTrackingModel extends Equatable {
  final String orderStatus;
  final String? currentLocation;
  final List<OrderTrackingHistoryItem> trackingHistory;
  final String? estimatedTime;

  const OrderTrackingModel({
    required this.orderStatus,
    this.currentLocation,
    this.trackingHistory = const [],
    this.estimatedTime,
  });

  factory OrderTrackingModel.fromJson(Map<String, dynamic> json) {
    final history = json['tracking_history'] as List<dynamic>? ?? [];
    return OrderTrackingModel(
      orderStatus: json['order_status']?.toString() ?? 'pending',
      currentLocation: json['current_location']?.toString(),
      trackingHistory: history
          .map((e) => OrderTrackingHistoryItem.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : (e is String ? {'status': e} : <String, dynamic>{})))
          .toList(),
      estimatedTime: json['estimated_time']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [orderStatus, currentLocation, trackingHistory, estimatedTime];
}

class OrderTrackingHistoryItem extends Equatable {
  final String? status;
  final String? location;
  final DateTime? timestamp;
  final String? description;

  const OrderTrackingHistoryItem({
    this.status,
    this.location,
    this.timestamp,
    this.description,
  });

  factory OrderTrackingHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderTrackingHistoryItem(
      status: json['status']?.toString(),
      location: json['location']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      description: json['description']?.toString(),
    );
  }

  @override
  List<Object?> get props => [status, location, timestamp, description];
}
