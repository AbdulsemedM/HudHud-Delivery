import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class NotificationsDataProvider {
  static const int defaultPerPage = 20;
  static const int maxPerPage = 100;

  final ApiService apiService;

  NotificationsDataProvider({required this.apiService});

  Map<String, dynamic> _wrapSuccess(dynamic response) {
    return {
      'statusCode': response.statusCode,
      'data': response.data,
      'errorMessage': null,
    };
  }

  Map<String, dynamic> _wrapApiException(ApiException apiException) {
    return {
      'statusCode': apiException.statusCode,
      'data': apiException.data,
      'errorMessage': apiException.message,
    };
  }

  Map<String, dynamic> _wrapUnknown(Object e) {
    return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
  }

  /// GET /api/notifications - returns list of notifications for the current user.
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = defaultPerPage,
  }) async {
    final boundedPerPage = perPage.clamp(1, maxPerPage);
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.notificationsList}',
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'per_page': boundedPerPage,
        },
      );
      return _wrapSuccess(response);
    } on ApiException catch (apiException) {
      return _wrapApiException(apiException);
    } on Exception catch (e) {
      return _wrapUnknown(e);
    }
  }

  /// GET /api/notifications/{id} - returns a single notification by id.
  Future<Map<String, dynamic>> getNotificationById(String id) async {
    try {
      final path = ApiConstants.replacePathParams(
        ApiConstants.notificationDetails,
        {'id': id},
      );
      final endpoint = '${ApiConstants.baseUrl}$path';
      final response = await apiService.get(endpoint);
      return _wrapSuccess(response);
    } on ApiException catch (apiException) {
      return _wrapApiException(apiException);
    } on Exception catch (e) {
      return _wrapUnknown(e);
    }
  }

  /// POST /api/notifications/read
  Future<Map<String, dynamic>> markRead(String notificationId) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.notificationsRead}',
        data: {'notification_id': notificationId},
      );
      return _wrapSuccess(response);
    } on ApiException catch (apiException) {
      return _wrapApiException(apiException);
    } on Exception catch (e) {
      return _wrapUnknown(e);
    }
  }

  /// POST /api/notifications/read-all
  Future<Map<String, dynamic>> markAllRead() async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.notificationsReadAll}',
      );
      return _wrapSuccess(response);
    } on ApiException catch (apiException) {
      return _wrapApiException(apiException);
    } on Exception catch (e) {
      return _wrapUnknown(e);
    }
  }
}
