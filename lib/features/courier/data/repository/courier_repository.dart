import '../../../../core/utils/api_error_result.dart';
import '../../../payment/model/payment_initiate_result.dart';
import '../../utils/delivery_estimate.dart';
import '../data_provider/courier_data_provider.dart';
import '../models/create_delivery_result.dart';
import '../models/delivery_live_tracking.dart';
import '../models/delivery_service_area.dart';
import '../models/nearby_drivers_result.dart';

class CourierRepository {
  final CourierDataProvider courierDataProvider;

  CourierRepository({required this.courierDataProvider});

  /// Estimate delivery cost. Returns estimated_distance, estimated_duration, estimated_cost.
  /// Pass [scheduledPickup] (ISO-8601 with offset) for scheduled bookings so the
  /// API prices against the requested Addis Ababa pickup time.
  Future<Map<String, dynamic>> estimateDelivery({
    required String packageType,
    required double packageWeight,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String vehicleType,
    required String serviceType,
    String? pickupLocation,
    String? scheduledPickup,
  }) async {
    try {
      final response = await courierDataProvider.estimateDelivery(
        packageType: packageType,
        packageWeight: packageWeight,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        dropoffLatitude: dropoffLatitude,
        dropoffLongitude: dropoffLongitude,
        vehicleType: vehicleType,
        serviceType: serviceType,
        pickupLocation: pickupLocation,
        scheduledPickup: scheduledPickup,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final rawData = response['data'];
        final estimate = parseDeliveryEstimate(rawData);
        return {
          'success': true,
          'estimatedDistance': estimate.estimatedDistance,
          'estimatedDuration': estimate.estimatedDuration,
          'estimatedCost': estimate.estimatedCost,
          'currency': estimate.currency,
          'baseDeliveryFee': estimate.baseDeliveryFee,
          'distanceRate': estimate.distanceRate,
          'freeDistance': estimate.freeDistance,
          'weightCharge': estimate.weightCharge,
          'timeBandName': estimate.timeBandName,
          'timeBandMultiplier': estimate.timeBandMultiplier,
          'timeBandSurchargeRate': estimate.timeBandSurchargeRate,
          'timeBandSurcharge': estimate.timeBandSurcharge,
          'evaluatedPickupAt': estimate.evaluatedPickupAt,
          'timezone': estimate.timezone,
          'nightHoursStart': estimate.nightHoursStart,
          'nightHoursEnd': estimate.nightHoursEnd,
          'vehicleType': estimate.vehicleType,
          'scheduledPickup': scheduledPickup,
          'data': rawData,
          'message': 'Estimate retrieved successfully',
        };
      } else {
        final statusCode = response['statusCode'] as int?;
        final parsed = parseApiErrorResult(
          response['data'],
          statusCode: statusCode,
          fallback: response['errorMessage']?.toString() ??
              'Error getting delivery estimate',
        );
        return {
          'success': false,
          'estimatedDistance': null,
          'estimatedDuration': null,
          'estimatedCost': null,
          'data': response['data'],
          'message': parsed.displayMessage,
          'error': parsed,
        };
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {
        'success': false,
        'estimatedDistance': null,
        'estimatedDuration': null,
        'estimatedCost': null,
        'data': null,
        'message': errorMessage,
      };
    }
  }

  /// GET /api/services/delivery/service-areas for a pickup address.
  Future<Map<String, dynamic>> getDeliveryServiceAreas({
    String? pickupLocation,
  }) async {
    try {
      final response = await courierDataProvider.getDeliveryServiceAreas(
        pickupLocation: pickupLocation,
      );
      final statusCode = response['statusCode'] as int?;
      if (statusCode == 200 || statusCode == 201) {
        final lookup = parseDeliveryServiceAreaLookup(response['data']);
        return {
          'success': true,
          'lookup': lookup,
          'supportedVehicleTypes': lookup.supportedVehicleTypes,
          'data': response['data'],
          'message': null,
        };
      }
      final parsed = parseApiErrorResult(
        response['data'],
        statusCode: statusCode,
        fallback: response['errorMessage']?.toString() ??
            'Error looking up delivery service area',
      );
      return {
        'success': false,
        'lookup': null,
        'supportedVehicleTypes': const <String>[],
        'data': response['data'],
        'message': parsed.displayMessage,
        'error': parsed,
      };
    } catch (e) {
      return {
        'success': false,
        'lookup': null,
        'supportedVehicleTypes': const <String>[],
        'data': null,
        'message': _cleanErrorMessage(e.toString()),
      };
    }
  }

  /// Create delivery request. Returns order data on success.
  Future<Map<String, dynamic>> createDeliveryRequest({
    required Map<String, dynamic> requestData,
  }) async {
    try {
      final response = await courierDataProvider.createDeliveryRequest(
          requestData: requestData);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'];
        final created = parseCreateDeliveryResponse(data);
        return {
          'success': true,
          'data': data,
          'orderId': created.isValid ? created.deliveryId : _extractOrderId(data),
          'created': created,
          'message': 'Delivery request created successfully',
        };
      } else {
        final statusCode = response['statusCode'] as int?;
        final parsed = parseApiErrorResult(
          response['data'],
          statusCode: statusCode,
          fallback: response['errorMessage']?.toString() ??
              'Error creating delivery request',
        );
        return {
          'success': false,
          'data': response['data'],
          'orderId': null,
          'created': null,
          'message': parsed.displayMessage,
          'error': parsed,
        };
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {
        'success': false,
        'data': null,
        'orderId': null,
        'created': null,
        'message': errorMessage
      };
    }
  }

  /// Get user's delivery history. Returns list of deliveries and pagination info.
  Future<Map<String, dynamic>> getUserDeliveries({int page = 1}) async {
    try {
      final response = await courierDataProvider.getUserDeliveries(page: page);

      if (response['statusCode'] == 200) {
        final rawData = response['data'] as Map<String, dynamic>?;
        final list = rawData?['data'] as List<dynamic>? ?? [];
        return {
          'success': true,
          'deliveries': List<Map<String, dynamic>>.from(
            list.map(
                (e) => e is Map<String, dynamic> ? e : <String, dynamic>{}),
          ),
          'currentPage': rawData?['current_page'] as int? ?? 1,
          'lastPage': rawData?['last_page'] as int? ?? 1,
          'total': rawData?['total'] as int? ?? 0,
          'message': null,
        };
      } else {
        String errorMessage =
            response['errorMessage'] ?? 'Error fetching deliveries';
        errorMessage = _cleanErrorMessage(errorMessage);
        return {
          'success': false,
          'deliveries': <Map<String, dynamic>>[],
          'currentPage': 1,
          'lastPage': 1,
          'total': 0,
          'message': errorMessage,
        };
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {
        'success': false,
        'deliveries': <Map<String, dynamic>>[],
        'currentPage': 1,
        'lastPage': 1,
        'total': 0,
        'message': errorMessage,
      };
    }
  }

  /// GET /api/customer/nearby-drivers. [retryable] is false on 422.
  Future<Map<String, dynamic>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    int? radius,
    String? vehicleType,
  }) async {
    try {
      final response = await courierDataProvider.getNearbyDrivers(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        vehicleType: vehicleType,
      );
      final statusCode = response['statusCode'] as int?;
      if (statusCode == 200) {
        final parsed = parseNearbyDriversResponse(response['data']);
        return {
          'success': true,
          'retryable': true,
          'nearby': parsed,
          'message': null,
        };
      }
      final retryable = statusCode != 422;
      return {
        'success': false,
        'retryable': retryable,
        'nearby': null,
        'message': _cleanErrorMessage(
          response['errorMessage']?.toString() ?? 'Error fetching nearby drivers',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'retryable': true,
        'nearby': null,
        'message': _cleanErrorMessage(e.toString()),
      };
    }
  }

  /// GET /api/customer/deliveries/{id}/live-tracking. [notFound] is true on 404.
  Future<Map<String, dynamic>> getDeliveryLiveTracking(int deliveryId) async {
    try {
      final response =
          await courierDataProvider.getDeliveryLiveTracking(deliveryId);
      final statusCode = response['statusCode'] as int?;
      if (statusCode == 200) {
        final parsed = parseDeliveryLiveTrackingResponse(response['data']);
        return {
          'success': true,
          'notFound': false,
          'tracking': parsed,
          'message': null,
        };
      }
      if (statusCode == 404) {
        return {
          'success': false,
          'notFound': true,
          'tracking': null,
          'message': _cleanErrorMessage(
            response['errorMessage']?.toString() ?? 'Tracking not found',
          ),
        };
      }
      return {
        'success': false,
        'notFound': false,
        'tracking': null,
        'message': _cleanErrorMessage(
          response['errorMessage']?.toString() ?? 'Error fetching live tracking',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'notFound': false,
        'tracking': null,
        'message': _cleanErrorMessage(e.toString()),
      };
    }
  }

  /// Get delivery tracking info. Returns tracking data from API.
  Future<Map<String, dynamic>> getDeliveryTrack(int deliveryId) async {
    try {
      final response = await courierDataProvider.getDeliveryTrack(deliveryId);

      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'data': data,
          'message': null,
        };
      } else {
        String errorMessage =
            response['errorMessage'] ?? 'Error fetching tracking';
        errorMessage = _cleanErrorMessage(errorMessage);
        return {'success': false, 'data': null, 'message': errorMessage};
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {'success': false, 'data': null, 'message': errorMessage};
    }
  }

  /// Get delivery details by id.
  Future<Map<String, dynamic>> getUserDeliveryDetails(int deliveryId) async {
    try {
      final response =
          await courierDataProvider.getUserDeliveryDetails(deliveryId);

      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        return {'success': true, 'data': data, 'message': null};
      } else {
        String errorMessage =
            response['errorMessage'] ?? 'Error fetching delivery details';
        errorMessage = _cleanErrorMessage(errorMessage);
        return {'success': false, 'data': null, 'message': errorMessage};
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {'success': false, 'data': null, 'message': errorMessage};
    }
  }

  /// Get user's active delivery. Returns delivery data or null if none.
  Future<Map<String, dynamic>> getUserActiveDelivery() async {
    try {
      final response = await courierDataProvider.getUserActiveDelivery();

      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'delivery': data,
          'message': null,
        };
      } else if (response['statusCode'] == 404) {
        return {'success': true, 'delivery': null, 'message': null};
      } else {
        String errorMessage =
            response['errorMessage'] ?? 'Error fetching active delivery';
        errorMessage = _cleanErrorMessage(errorMessage);
        return {'success': false, 'delivery': null, 'message': errorMessage};
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {'success': false, 'delivery': null, 'message': errorMessage};
    }
  }

  /// Retry unpaid payment via POST /api/services/delivery/{id}/retry-payment.
  Future<Map<String, dynamic>> retryPayment({
    required int deliveryId,
    required String paymentMethod,
    String? paymentPhone,
  }) async {
    try {
      final response = await courierDataProvider.retryPayment(
        deliveryId: deliveryId,
        paymentMethod: paymentMethod,
        paymentPhone: paymentPhone,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'];
        final envelope = _paymentEnvelope(data);
        return {
          'success': true,
          'data': data,
          'result': PaymentInitiateResult.fromJson(envelope),
          'message': envelope['message']?.toString() ?? 'Payment retry started',
        };
      }

      final parsed = parseApiErrorResult(
        response['data'],
        statusCode: response['statusCode'] as int?,
        fallback: response['errorMessage']?.toString() ??
            'Error retrying payment',
      );
      return {
        'success': false,
        'data': response['data'],
        'result': null,
        'message': parsed.displayMessage,
        'error': parsed,
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'result': null,
        'message': _cleanErrorMessage(e.toString()),
      };
    }
  }

  Map<String, dynamic> _paymentEnvelope(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map.containsKey('success')) return map;
      return {'success': true, 'data': map};
    }
    return {'success': true, 'data': <String, dynamic>{}};
  }

  /// Confirm package receipt via POST /api/services/delivery/{id}/confirm-receipt.
  Future<Map<String, dynamic>> confirmDeliveryReceipt(int deliveryId) async {
    try {
      final response =
          await courierDataProvider.confirmDeliveryReceipt(deliveryId);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'];
        String? message;
        if (data is Map) {
          message = data['message']?.toString();
        }
        return {
          'success': true,
          'data': data,
          'message': message ?? 'Receipt confirmed successfully',
        };
      }

      String errorMessage =
          response['errorMessage'] ?? 'Error confirming receipt';
      errorMessage = _cleanErrorMessage(errorMessage);
      return {
        'success': false,
        'data': response['data'],
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': _cleanErrorMessage(e.toString()),
      };
    }
  }

  /// Rate a package delivery via POST /api/services/delivery/{id}/rate.
  Future<Map<String, dynamic>> rateDelivery({
    required int deliveryId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await courierDataProvider.rateDelivery(
        deliveryId: deliveryId,
        rating: rating,
        comment: comment,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'];
        String? message;
        if (data is Map) {
          message = data['message']?.toString();
        }
        return {
          'success': true,
          'data': data,
          'message': message ?? 'Rating submitted successfully',
        };
      }

      String errorMessage = response['errorMessage'] ?? 'Error submitting rating';
      errorMessage = _cleanErrorMessage(errorMessage);
      return {
        'success': false,
        'data': response['data'],
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': _cleanErrorMessage(e.toString()),
      };
    }
  }

  /// Cancel a package delivery via POST /api/services/delivery/cancel.
  Future<Map<String, dynamic>> cancelDelivery({
    required int deliveryId,
    String cancellationReason = 'Changed my mind',
  }) async {
    try {
      final response = await courierDataProvider.cancelDelivery(
        deliveryId: deliveryId,
        cancellationReason: cancellationReason,
      );

      if (response['statusCode'] == 200) {
        final data = response['data'];
        String? message;
        if (data is Map) {
          message = data['message']?.toString();
        }
        return {
          'success': true,
          'data': data,
          'message': message ?? 'Delivery cancelled successfully',
        };
      }

      String errorMessage =
          response['errorMessage'] ?? 'Error cancelling delivery';
      errorMessage = _cleanErrorMessage(errorMessage);
      return {
        'success': false,
        'data': null,
        'message': errorMessage,
      };
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      return {
        'success': false,
        'data': null,
        'message': errorMessage,
      };
    }
  }

  dynamic _extractOrderId(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['id'] ?? data['order_id'] ?? data['orderId'];
    }
    return null;
  }

  String _cleanErrorMessage(String message) {
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
