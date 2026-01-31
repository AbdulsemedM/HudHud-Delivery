import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
// import '../models/orders_response_model.dart';

class OrdersDataProvider {
  ApiService apiService;
  
  OrdersDataProvider({required this.apiService});

  /// Fetch orders from the API
  Future<Map<String, dynamic>> fetchOrders({
    int page = 1,
    int perPage = 10,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null) 'status': status,
      };
      
      final response = await apiService.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );
      
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Cancel an order
  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason}) async {
    try {
      final body = {
        if (reason != null) 'reason': reason,
      };
      
      final response = await apiService.post(
        ApiConstants.replacePathParams(ApiConstants.cancelOrder, {'id': orderId}),
        data: body,
      );
      
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Get order details by ID
  Future<Map<String, dynamic>> getOrderById(int orderId) async {
    try {
      final response = await apiService.get(
        ApiConstants.replacePathParams(ApiConstants.orderDetails, {'id': orderId}),
      );
      
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
      };
    }
  }

}