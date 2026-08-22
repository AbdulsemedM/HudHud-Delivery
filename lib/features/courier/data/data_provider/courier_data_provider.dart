import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class CourierDataProvider {
  final ApiService apiService;

  CourierDataProvider({required this.apiService});

  /// POST /api/services/delivery/estimate
  /// Payload: package_type, package_weight, pickup_latitude, pickup_longitude,
  /// dropoff_latitude, dropoff_longitude, vehicle_type, service_type,
  /// optional scheduled_pickup (ISO-8601 with timezone offset).
  Future<Map<String, dynamic>> estimateDelivery({
    required String packageType,
    required double packageWeight,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String vehicleType,
    required String serviceType,
    String? scheduledPickup,
  }) async {
    try {
      final Map<String, dynamic> estimateData = {
        'package_type': packageType,
        'package_weight': packageWeight,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'vehicle_type': vehicleType,
        'service_type': serviceType,
      };
      if (scheduledPickup != null && scheduledPickup.isNotEmpty) {
        estimateData['scheduled_pickup'] = scheduledPickup;
      }

      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.deliveryEstimate}',
        data: estimateData,
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
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/services/delivery/request
  /// Full delivery request payload
  Future<Map<String, dynamic>> createDeliveryRequest({
    required Map<String, dynamic> requestData,
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.deliveryRequest}',
        data: requestData,
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
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/user/deliveries - fetches user's delivery history (paginated)
  Future<Map<String, dynamic>> getUserDeliveries({int page = 1}) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.userDeliveries}',
        queryParameters: {'page': page},
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

  /// GET /api/services/delivery/track/{id} - fetches delivery tracking info
  Future<Map<String, dynamic>> getDeliveryTrack(int deliveryId) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.deliveryTrack.replaceAll('{id}', deliveryId.toString());
      final response = await apiService.get(url);

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

  /// GET /api/user/deliveries/{id} - fetches delivery details by id
  Future<Map<String, dynamic>> getUserDeliveryDetails(int deliveryId) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.userDeliveryDetails
              .replaceAll('{id}', deliveryId.toString());
      final response = await apiService.get(url);

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

  /// GET /api/customer/nearby-drivers — anonymous markers near pickup.
  Future<Map<String, dynamic>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    int? radius,
    String? vehicleType,
  }) async {
    try {
      final query = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (radius != null) 'radius': radius,
        if (vehicleType != null && vehicleType.isNotEmpty)
          'vehicle_type': vehicleType,
      };
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.customerNearbyDrivers}',
        queryParameters: query,
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
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/customer/deliveries/{id}/live-tracking
  Future<Map<String, dynamic>> getDeliveryLiveTracking(int deliveryId) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.customerDeliveryLiveTracking
              .replaceAll('{id}', deliveryId.toString());
      final response = await apiService.get(url);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': apiException.data,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/user/deliveries/active - fetches user's active delivery (if any)
  Future<Map<String, dynamic>> getUserActiveDelivery() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.userDeliveriesActive}',
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

  /// POST /api/services/delivery/cancel — cancel a package delivery (customer).
  Future<Map<String, dynamic>> cancelDelivery({
    required int deliveryId,
    String cancellationReason = 'Changed my mind',
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.deliveryCancel}',
        data: {
          'delivery_id': deliveryId,
          'cancellation_reason': cancellationReason,
          'cancelled_by': 'user',
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
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/services/delivery/{id}/confirm-receipt
  Future<Map<String, dynamic>> confirmDeliveryReceipt(int deliveryId) async {
    try {
      final path = ApiConstants.deliveryConfirmReceipt.replaceAll(
        '{id}',
        deliveryId.toString(),
      );
      final response = await apiService.post('${ApiConstants.baseUrl}$path');

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': apiException.data,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/services/delivery/{id}/rate
  Future<Map<String, dynamic>> rateDelivery({
    required int deliveryId,
    required int rating,
    String? comment,
  }) async {
    try {
      final path = ApiConstants.deliveryRate.replaceAll(
        '{id}',
        deliveryId.toString(),
      );
      final body = <String, dynamic>{
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };
      final response = await apiService.post(
        '${ApiConstants.baseUrl}$path',
        data: body,
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
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/services/delivery/{id}/retry-payment
  Future<Map<String, dynamic>> retryPayment({
    required int deliveryId,
    required String paymentMethod,
    String? paymentPhone,
  }) async {
    try {
      final path = ApiConstants.deliveryRetryPayment.replaceAll(
        '{id}',
        deliveryId.toString(),
      );
      final body = <String, dynamic>{
        'payment_method': paymentMethod,
      };
      if (paymentPhone != null && paymentPhone.isNotEmpty) {
        body['payment_phone'] = paymentPhone;
      }
      final response = await apiService.post(
        '${ApiConstants.baseUrl}$path',
        data: body,
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
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }
}
