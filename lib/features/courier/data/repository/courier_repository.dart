import '../../utils/delivery_estimate.dart';
import '../data_provider/courier_data_provider.dart';
import '../models/create_delivery_result.dart';

class CourierRepository {
  final CourierDataProvider courierDataProvider;

  CourierRepository({required this.courierDataProvider});

  /// Estimate delivery cost. Returns estimated_distance, estimated_duration, estimated_cost.
  Future<Map<String, dynamic>> estimateDelivery({
    required String packageType,
    required double packageWeight,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String vehicleType,
    required String serviceType,
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
          'data': rawData,
          'message': 'Estimate retrieved successfully',
        };
      } else {
        String errorMessage =
            response['errorMessage'] ?? 'Error getting delivery estimate';
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
        String errorMessage =
            response['errorMessage'] ?? 'Error creating delivery request';
        errorMessage = _cleanErrorMessage(errorMessage);
        return {
          'success': false,
          'data': null,
          'orderId': null,
          'created': null,
          'message': errorMessage
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
