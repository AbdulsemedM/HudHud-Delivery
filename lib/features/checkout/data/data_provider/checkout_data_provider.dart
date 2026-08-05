import 'package:hudhud_delivery/core/api/api_constants.dart';
import '../../../../core/api/api_service.dart';

class CheckoutDataProvider {
  ApiService apiService;
  CheckoutDataProvider({required this.apiService});

  /// POST /api/customer/orders
  /// Sends nested delivery_address plus legacy flat lat/lng fields for compatibility.
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
    String? couponCode,
  }) async {
    try {
      final Map<String, dynamic> orderData = {
        'vendor_id': vendorId,
        'items': items,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'delivery_address': {
          'latitude': deliveryLatitude,
          'longitude': deliveryLongitude,
          'address': deliveryAddress,
        },
        // Legacy flat fields for backends that still expect them.
        'delivery_location': deliveryLocation,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'payment_method': paymentMethod,
        'service_type': serviceType,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'coupon_code': couponCode.trim(),
      };

      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.customerOrders}',
        data: orderData,
      );

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiException) {
      final message = _extractApiErrorMessage(apiException);
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double orderAmount,
    required int vendorId,
    String serviceType = 'restaurant',
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.validateCoupon}',
        data: {
          'code': code,
          'order_amount': orderAmount,
          'vendor_id': vendorId,
          'service_type': serviceType,
        },
      );

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': apiException.data,
        'errorMessage': _extractApiErrorMessage(apiException),
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': e.toString(),
      };
    }
  }

  String _extractApiErrorMessage(ApiException apiException) {
    final rawData = apiException.data;
    if (rawData is Map<String, dynamic>) {
      final messageField = rawData['message'];
      if (messageField is Map<String, dynamic>) {
        final couponErrors = messageField['coupon_code'];
        if (couponErrors is List && couponErrors.isNotEmpty) {
          return couponErrors.first.toString();
        }

        for (final entry in messageField.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value != null && value.toString().isNotEmpty) {
            return value.toString();
          }
        }
      }

      final errors = rawData['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final messages = <String>[];
        errors.forEach((field, value) {
          if (value is List && value.isNotEmpty) {
            messages.add('$field: ${value.first}');
          } else if (value != null) {
            messages.add('$field: $value');
          }
        });
        if (messages.isNotEmpty) {
          return messages.join(' | ');
        }
      }

      final message = rawData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return apiException.message;
  }

  /// POST /api/customer/orders/{id}/cancel
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.customerOrderCancel
              .replaceAll('{id}', orderId.toString());
      final response = await apiService.post(url);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
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
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }
}
