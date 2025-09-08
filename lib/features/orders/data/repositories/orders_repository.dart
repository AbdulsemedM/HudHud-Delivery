import '../models/order_model.dart';
import '../models/orders_response_model.dart';
import '../providers/orders_data_provider.dart';

abstract class OrdersRepository {
  Future<OrdersResponseModel> fetchOrders({
    int page = 1,
    int perPage = 10,
    String? status,
  });
  
  Future<OrderModel> getOrderById(int orderId);
  Future<bool> cancelOrder(int orderId, {String? reason});
}

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersDataProvider dataProvider;

  OrdersRepositoryImpl({required this.dataProvider});

  @override
  Future<OrdersResponseModel> fetchOrders({
    int page = 1,
    int perPage = 10,
    String? status,
  }) async {
    try {
      final response = await dataProvider.fetchOrders(
        page: page,
        perPage: perPage,
        status: status,
      );
      
      if (response['statusCode'] == 200 && response['data'] != null) {
        return OrdersResponseModel.fromJson(response['data']);
      } else {
        throw OrdersRepositoryException(response['errorMessage'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      if (e is OrdersRepositoryException) rethrow;
      throw OrdersRepositoryException('Failed to fetch orders: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> getOrderById(int orderId) async {
    try {
      final response = await dataProvider.getOrderById(orderId);
      
      if (response['statusCode'] == 200 && response['data'] != null) {
        return OrderModel.fromJson(response['data']);
      } else {
        throw OrdersRepositoryException(response['errorMessage'] ?? 'Order not found');
      }
    } catch (e) {
      if (e is OrdersRepositoryException) rethrow;
      throw OrdersRepositoryException('Failed to fetch order: ${e.toString()}');
    }
  }

  @override
  Future<bool> cancelOrder(int orderId, {String? reason}) async {
    try {
      final response = await dataProvider.cancelOrder(orderId, reason: reason);
      
      if (response['statusCode'] == 200) {
        return response['data'] ?? true;
      } else {
        throw OrdersRepositoryException(response['errorMessage'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      if (e is OrdersRepositoryException) rethrow;
      throw OrdersRepositoryException('Failed to cancel order: ${e.toString()}');
    }
  }
}

/// Custom exception for repository-related errors
class OrdersRepositoryException implements Exception {
  final String message;

  const OrdersRepositoryException(this.message);

  @override
  String toString() => 'OrdersRepositoryException: $message';
}