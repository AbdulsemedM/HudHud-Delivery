import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class VendorsDataProvider {
  final ApiService apiService;
  VendorsDataProvider({required this.apiService});

  /// GET /api/vendors?page=1
  Future<Map<String, dynamic>> getVendors({int page = 1}) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.vendors}',
        queryParameters: {'page': page},
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

  /// GET /api/vendor/products/by-vendor/{id}
  Future<Map<String, dynamic>> getVendorProducts(int vendorId) async {
    try {
      final path = ApiConstants.vendorProducts.replaceAll('{id}', vendorId.toString());
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
