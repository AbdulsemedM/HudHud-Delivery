import 'package:hudhud_delivery/core/api/api_constants.dart';

import '../../../../core/api/api_service.dart';

class CategoriesDataProvider {
  ApiService apiService;
  CategoriesDataProvider({required this.apiService});

  Future<Map<String, dynamic>> getCategoriesProducts(
      {required int categoryId}) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}categories/$categoryId/products',
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        "errorMessage": null
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        "errorMessage": apiException.message
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, "errorMessage": e.toString()};
    }
  }
}
