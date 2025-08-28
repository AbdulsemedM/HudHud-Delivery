import 'package:hudhud_delivery/core/api/api_service.dart';

import '../../../../core/api/api_constants.dart';

class HomeDataProvider {
  ApiService apiService;
  HomeDataProvider({required this.apiService});
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await apiService.get('${ApiConstants.baseUrl}categories');
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
      };
    }
  }
}