import 'package:hudhud_delivery/core/api/api_constants.dart';
import '../../../../core/api/api_service.dart';

class CheckoutDataProvider {
  ApiService apiService;
  CheckoutDataProvider({required this.apiService});

  Future<Map<String, dynamic>> createOrder({
    required int vendorId,
    required List<Map<String, dynamic>> items,
    required double taxAmount,
    required double discountAmount,
    required String deliveryAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> orderData = {
        'vendor_id': vendorId,
        'items': items,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await apiService.post(
        '${ApiConstants.baseUrl}customer/orders',
        data: orderData,
      );
      
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> getOrderHistory() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}customer/orders',
      );
      
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode,
        'data': null,
        'errorMessage': e.message
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': e.toString()
      };
    }
  }
}