import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class VendorsDataProvider {
  final ApiService apiService;
  VendorsDataProvider({required this.apiService});

  /// GET /api/public/vendors — preferred discovery route (lat/lng optional).
  Future<Map<String, dynamic>> getVendors({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (categoryId != null) query['category_id'] = categoryId;
      if (latitude != null) query['latitude'] = latitude;
      if (longitude != null) query['longitude'] = longitude;

      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.publicVendors}',
        queryParameters: query,
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

  /// GET /api/public/vendors/{id}
  Future<Map<String, dynamic>> getVendorById(int vendorId) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.publicVendors}/$vendorId',
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

  /// GET /api/public/vendors/{id}/products
  Future<Map<String, dynamic>> getVendorProducts(
    int vendorId, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final path = ApiConstants.replacePathParams(
        ApiConstants.publicVendorProducts,
        {'id': vendorId},
      );
      final response = await apiService.get(
        '${ApiConstants.baseUrl}$path',
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
