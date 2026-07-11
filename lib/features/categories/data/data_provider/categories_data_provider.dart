import 'package:hudhud_delivery/core/api/api_constants.dart';

import '../../../../core/api/api_service.dart';

class CategoriesDataProvider {
  ApiService apiService;
  CategoriesDataProvider({required this.apiService});

  /// GET /api/categories?page=1 - returns paginated list of categories.
  Future<Map<String, dynamic>> getCategories({int page = 1}) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.categories}',
        queryParameters: {'page': page},
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

  /// GET /api/categories/tree - returns tree of categories with nested children.
  Future<Map<String, dynamic>> getCategoriesTree() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.categories}/tree',
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

  /// GET /api/products/{id}
  Future<Map<String, dynamic>> getProductById(int productId) async {
    try {
      final path = ApiConstants.productDetails.replaceAll('{id}', productId.toString());
      final response = await apiService.get('${ApiConstants.baseUrl}$path');
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode,
        'data': null,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }
}
