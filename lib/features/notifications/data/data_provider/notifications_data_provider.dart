import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class NotificationsDataProvider {
  final ApiService apiService;

  NotificationsDataProvider({required this.apiService});

  /// GET /api/notifications - returns list of notifications for the current user.
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.notificationsList}',
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

  /// GET /api/notifications/{id} - returns a single notification by id.
  Future<Map<String, dynamic>> getNotificationById(int id) async {
    try {
      final path = ApiConstants.replacePathParams(
        ApiConstants.notificationDetails,
        {'id': id.toString()},
      );
      final endpoint = '${ApiConstants.baseUrl}$path';
      final response = await apiService.get(endpoint);
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
