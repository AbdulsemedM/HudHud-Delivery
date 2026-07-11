import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/products/model/products_query.dart';

class PublicCatalogDataProvider {
  final ApiService apiService;

  PublicCatalogDataProvider({required this.apiService});

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}$path',
        queryParameters: queryParameters,
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
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int perPage = 15,
    int? categoryId,
    String? minPrice,
    String? maxPrice,
    String? sortBy,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (categoryId != null) params['category_id'] = categoryId;
    if (minPrice != null && minPrice.trim().isNotEmpty) {
      params['min_price'] = minPrice.trim();
    }
    if (maxPrice != null && maxPrice.trim().isNotEmpty) {
      params['max_price'] = maxPrice.trim();
    }
    if (sortBy != null && sortBy.trim().isNotEmpty) {
      params['sort_by'] = sortBy.trim();
    }
    return _get(ApiConstants.publicProducts, queryParameters: params);
  }

  Future<Map<String, dynamic>> getProductsFromQuery(ProductsQuery query) {
    return getProducts(
      page: query.page,
      perPage: query.perPage,
      categoryId: query.categoryId,
      minPrice: query.minPrice,
      maxPrice: query.maxPrice,
      sortBy: query.sortBy,
    );
  }

  Future<Map<String, dynamic>> getCategoryProducts(
    int categoryId, {
    int page = 1,
    int perPage = 15,
  }) {
    final path = ApiConstants.replacePathParams(
      ApiConstants.publicCategoryProducts,
      {'id': categoryId},
    );
    return _get(path, queryParameters: {'page': page, 'per_page': perPage});
  }

  Future<Map<String, dynamic>> getVendorProducts(
    int vendorId, {
    int page = 1,
    int perPage = 15,
  }) {
    final path = ApiConstants.replacePathParams(
      ApiConstants.publicVendorProducts,
      {'id': vendorId},
    );
    return _get(path, queryParameters: {'page': page, 'per_page': perPage});
  }

  Future<Map<String, dynamic>> searchProducts({
    required String query,
    int? categoryId,
    int page = 1,
    int perPage = 15,
  }) {
    final params = <String, dynamic>{
      'query': query,
      'page': page,
      'per_page': perPage,
    };
    if (categoryId != null) params['category_id'] = categoryId;
    return _get(ApiConstants.publicSearch, queryParameters: params);
  }

  Future<Map<String, dynamic>> getProductById(int productId) {
    final path = ApiConstants.replacePathParams(
      ApiConstants.publicProductDetails,
      {'id': productId},
    );
    return _get(path);
  }

  Future<Map<String, dynamic>> getFeaturedProducts({int limit = 10}) {
    return _get(
      ApiConstants.publicProductsFeatured,
      queryParameters: {'limit': limit},
    );
  }

  Future<Map<String, dynamic>> getPopularProducts({
    String period = 'month',
    int? vendorId,
    int? categoryId,
    bool excludeOutOfStock = true,
  }) {
    final params = <String, dynamic>{
      'period': period,
      'exclude_out_of_stock': excludeOutOfStock,
    };
    if (vendorId != null) params['vendor_id'] = vendorId;
    if (categoryId != null) params['category_id'] = categoryId;
    return _get(ApiConstants.publicPopularProducts, queryParameters: params);
  }

  Future<Map<String, dynamic>> getCategories() {
    return _get(ApiConstants.publicCategories);
  }

  Future<Map<String, dynamic>> getVendors({int page = 1, int perPage = 15}) {
    return _get(
      ApiConstants.publicVendors,
      queryParameters: {'page': page, 'per_page': perPage},
    );
  }

  Future<Map<String, dynamic>> getBranches({required int vendorId}) {
    return _get(
      ApiConstants.publicBranches,
      queryParameters: {'vendor_id': vendorId},
    );
  }

  Future<Map<String, dynamic>> getNearbyBranches({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) {
    return _get(
      ApiConstants.publicBranchesNearby,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      },
    );
  }
}
