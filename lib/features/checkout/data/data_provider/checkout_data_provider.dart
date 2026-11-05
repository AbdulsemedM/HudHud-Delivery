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

  /// Order body shared by POST /api/customer/orders and
  /// POST /api/customer/gift-orders.
  /// Nested delivery_address (docs) plus flat delivery_* fields (live API validation).
  static Map<String, dynamic> buildOrderBody({
    required int vendorId,
    required List<Map<String, dynamic>> items,
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
    int? redeemPoints,
  }) {
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
    // Phase 2: points to redeem against the delivery fee. The server
    // recomputes and caps the discount; no client totals are trusted.
    if (redeemPoints != null && redeemPoints > 0) {
      orderData['redeem_points'] = redeemPoints;
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
    return orderData;
  }

  /// Max length of `gift_message` accepted by the API (GiftOrderService).
  static const int giftMessageMaxLength = 300;

  /// Max length of `recipient_name` accepted by the API.
  static const int giftRecipientNameMaxLength = 120;

  /// POST /api/customer/gift-orders body: the order body plus the
  /// recipient. Points are never sent (the API drops `redeem_points` for
  /// gifts) and cash on delivery must not reach this call.
  static Map<String, dynamic> buildGiftOrderBody({
    required Map<String, dynamic> orderBody,
    required String recipientName,
    required String recipientPhone,
    String? giftMessage,
  }) {
    final body = Map<String, dynamic>.from(orderBody)..remove('redeem_points');
    final name = recipientName.trim();
    body['recipient_name'] = name.length > giftRecipientNameMaxLength
        ? name.substring(0, giftRecipientNameMaxLength)
        : name;
    body['recipient_phone'] = recipientPhone.trim();
    final message = giftMessage?.trim();
    if (message != null && message.isNotEmpty) {
      body['gift_message'] = message.length > giftMessageMaxLength
          ? message.substring(0, giftMessageMaxLength)
          : message;
    }
    return body;
  }

  /// POST /api/customer/orders
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
    int? redeemPoints,
  }) async {
    try {
      final orderData = buildOrderBody(
        vendorId: vendorId,
        items: items,
        deliveryAddress: deliveryAddress,
        deliveryLocation: deliveryLocation,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        paymentMethod: paymentMethod,
        serviceType: serviceType,
        notes: notes,
        couponCode: couponCode,
        pickupLocation: pickupLocation,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        branchId: branchId,
        redeemPoints: redeemPoints,
      );

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

  /// POST /api/customer/gift-orders (Phase 6 diaspora gifting).
  ///
  /// [body] comes from [buildGiftOrderBody]. Errors also return the API
  /// `code` (FEATURE_DISABLED 422, GIFTING_NOT_READY 503) and the field
  /// `errors` (e.g. recipient_phone) so checkout can react.
  Future<Map<String, dynamic>> createGiftOrder({
    required Map<String, dynamic> body,
    String? idempotencyKey,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        headers['Idempotency-Key'] = idempotencyKey;
      }
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.customerGiftOrders}',
        data: body,
        options: headers.isEmpty ? null : Options(headers: headers),
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
        'errorMessage': _extractGiftErrorMessage(apiException),
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

  /// Gift validation errors are shown as the server wrote them (without the
  /// `field:` prefix [_extractApiErrorMessage] adds), recipient first.
  String _extractGiftErrorMessage(ApiException apiException) {
    final rawData = apiException.data;
    if (rawData is Map) {
      final errors = rawData['errors'];
      if (errors is Map && errors.isNotEmpty) {
        for (final field in const [
          'recipient_phone',
          'recipient_name',
          'gift_message',
          'payment_method',
        ]) {
          final value = errors[field];
          if (value is List && value.isNotEmpty) return value.first.toString();
        }
      }
    }
    return _extractApiErrorMessage(apiException);
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
