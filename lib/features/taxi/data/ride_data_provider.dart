import 'package:dio/dio.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class RideDataProvider {
  final ApiService apiService = ApiService.instance;

  /// POST /api/services/ride/estimate
  /// Returns estimated distance, duration, and fare for a ride
  Future<Map<String, dynamic>> getRideEstimate({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String vehicleType,
    required String rideType,
    int passengerCount = 1,
  }) async {
    try {
      final Map<String, dynamic> estimateData = {
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'vehicle_type': vehicleType,
        'ride_type': rideType,
        'passenger_count': passengerCount,
      };

      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.rideEstimate}',
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
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/services/ride/request
  /// Creates a ride request with nested pickup/dropoff locations.
  Future<Map<String, dynamic>> requestRide({
    required String pickupLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropoffLocation,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String vehicleType,
    required String rideType,
    int passengerCount = 1,
    String? scheduledAt,
    required double estimatedDistance,
    required int estimatedDuration,
    required double estimatedFare,
    required String paymentMethod,
    String? notes,
    int? preferredDriverId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'pickup_location': {
          'latitude': pickupLatitude,
          'longitude': pickupLongitude,
          'address': pickupLocation,
        },
        'dropoff_location': {
          'latitude': dropoffLatitude,
          'longitude': dropoffLongitude,
          'address': dropoffLocation,
        },
        // Legacy flat fields for backends that still expect them.
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'vehicle_type': vehicleType,
        'ride_type': rideType,
        'passenger_count': passengerCount,
        'scheduled_at': scheduledAt,
        'estimated_distance': estimatedDistance,
        'estimated_duration': estimatedDuration,
        'estimated_fare': estimatedFare,
        'payment_method': paymentMethod,
        'notes': notes,
        'preferred_driver_id': preferredDriverId,
      };

      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.rideRequest}',
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
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/services/ride/available-vehicles
  /// Returns available vehicles/drivers near the given location
  Future<Map<String, dynamic>> getAvailableVehicles({
    required double latitude,
    required double longitude,
    String vehicleType = 'car',
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'latitude': latitude,
        'longitude': longitude,
        'vehicle_type': vehicleType,
      };

      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.rideAvailableVehicles}',
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
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/services/ride/{id}/cancel
  /// Cancels a ride request (customer side).
  Future<Map<String, dynamic>> cancelRide({
    required int rideId,
    String cancellationReason = 'Changed my mind',
  }) async {
    try {
      final path = ApiConstants.rideCancelById.replaceAll(
        '{id}',
        rideId.toString(),
      );
      final response = await apiService.post(
        '${ApiConstants.baseUrl}$path',
        data: {
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

  /// GET /api/user/rides/active
  /// Returns the user's active ride (if any).
  /// A 404 ("No active ride found") is treated as a normal empty result,
  /// not a Dio error, so debug logs stay quiet for that expected case.
  Future<Map<String, dynamic>> getActiveRide() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.userRidesActive}',
        options: Options(
          validateStatus: (status) =>
              status != null && (status < 300 || status == 404),
        ),
      );

      if (response.statusCode == 404) {
        return {
          'statusCode': 404,
          'data': null,
          'errorMessage': null,
        };
      }

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
}
