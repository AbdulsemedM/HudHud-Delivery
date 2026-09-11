import 'package:dio/dio.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import '../../../../core/api/api_service.dart';

class CheckoutDataProvider {
  ApiService apiService;
  CheckoutDataProvider({required this.apiService});

  /// POST /api/customer/delivery-fee/quote
  Future<Map<String, dynamic>> quoteDeliveryFee({
    required int branchId,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.customerDeliveryFeeQuote}',
        data: {
          'branch_id': branchId,
          'delivery_address': deliveryAddress,
          'delivery_latitude': deliveryLatitude,
          'delivery_longitude': deliveryLongitude,
        },
      );

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
        'code': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': apiException.data,
        'errorMessage': _extractApiErrorMessage(apiException),
        'code': apiException.code ?? _extractErrorCode(apiException.data),
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': e.toString(),
        'code': null,
      };
    }
  }

  /// POST /api/customer/orders
  /// Nested delivery_address (docs) plus flat delivery_* fields (live API validation).
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
    String serviceType = 'restaurant',
    String? notes,
    String? couponCode,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    int? branchId,
    String? idempotencyKey,
  }) async {
    try {
      final Map<String, dynamic> orderData = {
        'items': items
            .map((item) {
              final mapped = <String, dynamic>{
                'product_id': item['product_id'],
                'quantity': item['quantity'],
              };
              final variantId = item['variant_id'];
              if (variantId != null) {
                final parsed = variantId is int
                    ? variantId
                    : int.tryParse(variantId.toString());
                if (parsed != null && parsed > 0) {
                  mapped['variant_id'] = parsed;
                }
              }
              final modifierIds = item['modifier_option_ids'];
              if (modifierIds is List && modifierIds.isNotEmpty) {
                mapped['modifier_option_ids'] = modifierIds
                    .map((e) => e is int ? e : int.tryParse(e.toString()))
                    .whereType<int>()
                    .where((id) => id > 0)
                    .toList();
              }
              final itemNotes = item['notes'];
              if (itemNotes is String && itemNotes.trim().isNotEmpty) {
                mapped['notes'] = itemNotes.trim();
              }
              return mapped;
            })
            .toList(),
        'delivery_address': {
          'latitude': deliveryLatitude,
          'longitude': deliveryLongitude,
          'address': deliveryAddress,
        },
        // Live API still requires these flat fields (422 if omitted).
        'delivery_location': deliveryLocation.isNotEmpty
            ? deliveryLocation
            : deliveryAddress,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'payment_method': paymentMethod,
        'service_type':
            serviceType.trim().isEmpty ? 'restaurant' : serviceType.trim(),
      };

      if (vendorId > 0) {
        orderData['vendor_id'] = vendorId;
      }
      if (branchId != null && branchId > 0) {
        orderData['branch_id'] = branchId;
      }
      if (notes != null && notes.trim().isNotEmpty) {
        orderData['notes'] = notes.trim();
      }
      if (couponCode != null && couponCode.trim().isNotEmpty) {
        orderData['coupon_code'] = couponCode.trim();
      }
      if (pickupLocation != null && pickupLocation.trim().isNotEmpty) {
        orderData['pickup_location'] = pickupLocation.trim();
      }
      if (pickupLatitude != null) {
        orderData['pickup_latitude'] = pickupLatitude;
      }
      if (pickupLongitude != null) {
        orderData['pickup_longitude'] = pickupLongitude;
      }

      final headers = <String, dynamic>{};
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        headers['Idempotency-Key'] = idempotencyKey;
      }

      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.customerOrders}',
        data: orderData,
        options: headers.isEmpty ? null : Options(headers: headers),
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

  String? _extractErrorCode(dynamic rawData) {
    if (rawData is Map) {
      final code = rawData['code']?.toString();
      if (code != null && code.isNotEmpty) return code;
    }
    return null;
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
  Future<Map<String, dynamic>> cancelOrder(
    int orderId, {
    String? reason,
  }) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.replacePathParams(
            ApiConstants.customerOrderCancel,
            {'id': orderId},
          );
      final body = <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        body['reason'] = reason.trim();
      }
      final response = await apiService.post(
        url,
        data: body.isEmpty ? null : body,
      );

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
