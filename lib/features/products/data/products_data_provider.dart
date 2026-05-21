import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/products/model/products_query.dart';

class ProductsDataProvider {
  final ApiService apiService;

  ProductsDataProvider({required this.apiService});

  /// GET /api/products with query params from [query].
  Future<Map<String, dynamic>> getProducts(ProductsQuery query) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.products}',
        queryParameters: query.toQueryParameters(),
      );
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
