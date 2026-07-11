import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class SosDataProvider {
  final ApiService apiService;

  SosDataProvider({required this.apiService});

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  Future<Map<String, dynamic>> _wrap(Future<dynamic> Function() call) async {
    try {
      final response = await call();
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  Future<Map<String, dynamic>> triggerSos(Map<String, dynamic> body) {
    return _wrap(
      () => apiService.post(_url(ApiConstants.sosTrigger), data: body),
    );
  }

  Future<Map<String, dynamic>> getSosHistory({
    String? status,
    int page = 1,
    int perPage = 10,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    return _wrap(
      () => apiService.get(
        _url(ApiConstants.sosHistory),
        queryParameters: query,
      ),
    );
  }

  Future<Map<String, dynamic>> addEmergencyContact(Map<String, dynamic> body) {
    return _wrap(
      () => apiService.post(_url(ApiConstants.sosContacts), data: body),
    );
  }

  Future<Map<String, dynamic>> updateEmergencyContact(
    int id,
    Map<String, dynamic> body,
  ) {
    return _wrap(
      () => apiService.put(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.sosContactDetails,
            {'id': id},
          ),
        ),
        data: body,
      ),
    );
  }

  Future<Map<String, dynamic>> deleteEmergencyContact(int id) {
    return _wrap(
      () => apiService.delete(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.sosContactDetails,
            {'id': id},
          ),
        ),
      ),
    );
  }
}
