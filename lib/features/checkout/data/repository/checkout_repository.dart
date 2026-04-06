import '../data_provider/checkout_data_provider.dart';

class CheckoutRepository {
  final CheckoutDataProvider checkoutDataProvider;
  CheckoutRepository({required this.checkoutDataProvider});

  Future<Map<String, dynamic>> createOrder({
    required int vendorId,
    required List<Map<String, dynamic>> items,
    required double taxAmount,
    required double discountAmount,
    required String deliveryAddress,
    required String deliveryLocation,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String paymentMethod,
    String serviceType = 'delivery',
    String? notes,
  }) async {
    try {
      final response = await checkoutDataProvider.createOrder(
        vendorId: vendorId,
        items: items,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        deliveryAddress: deliveryAddress,
        deliveryLocation: deliveryLocation,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        paymentMethod: paymentMethod,
        serviceType: serviceType,
        notes: notes,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        return {
          'success': true,
          'data': response['data'],
          'message': 'Order created successfully'
        };
      } else {
        String errorMessage =
            response['errorMessage'] ?? 'Error creating order';
        errorMessage = _cleanErrorMessage(errorMessage);
        return {'success': false, 'data': null, 'message': errorMessage};
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {'success': false, 'data': null, 'message': errorMessage};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final response = await checkoutDataProvider.cancelOrder(orderId);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'message':
              data?['message']?.toString() ?? 'Order cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': "You can't cancel this order",
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': "You can't cancel this order",
      };
    }
  }

  Future<List<dynamic>> getOrderHistory() async {
    try {
      final response = await checkoutDataProvider.getOrderHistory();

      if (response['statusCode'] == 200) {
        final List<dynamic> orders = response['data']['data'] ?? [];
        return orders;
      } else {
        String errorMessage =
            response['errorMessage'] ?? 'Error fetching order history';
        errorMessage = _cleanErrorMessage(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      throw Exception(errorMessage);
    }
  }

  String _cleanErrorMessage(String message) {
    // Remove various prefixes that might appear
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    if (message.startsWith('ApiException: ')) {
      message = message.substring(14);
    }
    if (message.startsWith('FormatException: ')) {
      message = message.substring(17);
    }
    return message;
  }
}
