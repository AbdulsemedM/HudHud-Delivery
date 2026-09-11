import '../data_provider/checkout_data_provider.dart';
import '../models/delivery_fee_quote.dart';

class CheckoutRepository {
  final CheckoutDataProvider checkoutDataProvider;
  CheckoutRepository({required this.checkoutDataProvider});

  /// POST /api/customer/delivery-fee/quote — preview only.
  Future<DeliveryFeeQuote> quoteDeliveryFee({
    required int branchId,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
  }) async {
    final response = await checkoutDataProvider.quoteDeliveryFee(
      branchId: branchId,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
    );

    final statusCode = response['statusCode'] as int?;
    final body = response['data'];
    final code = response['code'] as String?;
    final errorMessage = _cleanErrorMessage(
      response['errorMessage']?.toString() ?? 'Unable to calculate delivery fee',
    );

    if (statusCode == 200 || statusCode == 201) {
      final root = body is Map<String, dynamic>
          ? body
          : body is Map
              ? Map<String, dynamic>.from(body)
              : null;
      if (root == null || root['success'] != true) {
        throw DeliveryFeeQuoteException(
          message: root?['message']?.toString() ?? errorMessage,
          statusCode: statusCode,
          code: root?['code']?.toString() ?? code,
        );
      }
      final data = root['data'];
      if (data is! Map) {
        throw DeliveryFeeQuoteException(
          message: 'Unable to calculate delivery fee',
          statusCode: statusCode,
        );
      }
      return DeliveryFeeQuote.fromJson(Map<String, dynamic>.from(data));
    }

    Map<String, dynamic>? errors;
    if (body is Map) {
      final rawErrors = body['errors'];
      if (rawErrors is Map) {
        errors = Map<String, dynamic>.from(rawErrors);
      }
    }

    throw DeliveryFeeQuoteException(
      message: body is Map && body['message'] != null
          ? body['message'].toString()
          : errorMessage,
      statusCode: statusCode,
      code: code ?? (body is Map ? body['code']?.toString() : null),
      errors: errors,
    );
  }

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
        couponCode: couponCode,
        pickupLocation: pickupLocation,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        branchId: branchId,
        idempotencyKey: idempotencyKey,
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

  Future<Map<String, dynamic>> cancelOrder(
    int orderId, {
    String? reason,
  }) async {
    try {
      final response =
          await checkoutDataProvider.cancelOrder(orderId, reason: reason);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'message':
              data?['message']?.toString() ?? 'Order cancelled successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': response['errorMessage']?.toString() ??
              "You can't cancel this order",
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
        final body = response['data'];
        if (body is! Map<String, dynamic>) return [];
        final inner = body['data'];
        if (inner is List) return inner;
        if (inner is Map<String, dynamic> && inner['data'] is List) {
          return inner['data'] as List<dynamic>;
        }
        return [];
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

  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double orderAmount,
    required int vendorId,
    String serviceType = 'restaurant',
  }) async {
    try {
      final response = await checkoutDataProvider.validateCoupon(
        code: code,
        orderAmount: orderAmount,
        vendorId: vendorId,
        serviceType: serviceType,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        return {
          'success': true,
          'data': response['data'],
          'message': response['data']?['message'] ?? 'Coupon is valid!',
        };
      }

      String errorMessage = response['errorMessage'] ?? 'Invalid coupon';
      errorMessage = _cleanErrorMessage(errorMessage);
      return {'success': false, 'data': null, 'message': errorMessage};
    } catch (e) {
      String errorMessage = _cleanErrorMessage(e.toString());
      return {'success': false, 'data': null, 'message': errorMessage};
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
