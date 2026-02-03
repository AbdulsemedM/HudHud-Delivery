import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class ServiceTypesDataProvider {
  final ApiService apiService;

  ServiceTypesDataProvider({required this.apiService});

  /// GET /api/service-types - fetches all service types (paginated).
  Future<Map<String, dynamic>> getServiceTypes({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.serviceTypes}',
        queryParameters: {
          'page': page,
          'per_page': perPage,
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
}
