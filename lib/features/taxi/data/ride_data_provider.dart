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
  /// Creates a ride request
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
        'pickup_location': pickupLocation,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_location': dropoffLocation,
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

  /// GET /api/user/rides/active
  /// Returns the user's active ride (if any)
  Future<Map<String, dynamic>> getActiveRide() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.userRidesActive}',
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
}
