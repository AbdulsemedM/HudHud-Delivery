import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_data_provider.dart';
import 'package:hudhud_delivery/features/guest/model/branch_model.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/products/model/products_list_result.dart';
import 'package:hudhud_delivery/features/products/model/products_query.dart';

import '../../categories/data/repository/categories_repository.dart';

class PublicCatalogRepository {
  final PublicCatalogDataProvider dataProvider;

  PublicCatalogRepository({required this.dataProvider});

  Future<ProductsListResult> getProducts(ProductsQuery query) async {
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      return _search(search, query);
    }
    if (query.vendorId != null) {
      return _vendorProducts(query.vendorId!, query.page, query.perPage);
    }
    if (query.categoryId != null && !query.hasPublicProductFilters) {
      return _categoryProducts(query.categoryId!, query.page, query.perPage);
    }
    return _filteredOrAllProducts(query);
  }

  Future<ProductsListResult> _search(
    String search,
    ProductsQuery query,
  ) async {
    final response = await dataProvider.searchProducts(
      query: search,
      categoryId: query.categoryId,
      page: query.page,
      perPage: query.perPage,
    );
    return _parseProductsResponse(response);
  }

  Future<ProductsListResult> _vendorProducts(
    int vendorId,
    int page,
    int perPage,
  ) async {
    final response = await dataProvider.getVendorProducts(
      vendorId,
      page: page,
      perPage: perPage,
    );
    return _parseProductsResponse(response);
  }

  Future<ProductsListResult> _categoryProducts(
    int categoryId,
    int page,
    int perPage,
  ) async {
    final response = await dataProvider.getCategoryProducts(
      categoryId,
      page: page,
      perPage: perPage,
    );
    return _parseProductsResponse(response);
  }

  Future<ProductsListResult> _filteredOrAllProducts(ProductsQuery query) async {
    final response = await dataProvider.getProductsFromQuery(query);
    return _parseProductsResponse(response);
  }

  Future<List<CategoriesProductsModel>> getFeaturedProducts({
    int limit = 10,
  }) async {
    final response = await dataProvider.getFeaturedProducts(limit: limit);
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final body = response['data'];
    final list = _unwrapList(body);
    return list
        .whereType<Map>()
        .map((e) => CategoriesProductsModel.fromMap(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<CategoriesListResult> getCategories({int page = 1}) async {
    final response = await dataProvider.getCategories();
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final list = _unwrapList(response['data']);
    final items = list
        .map((e) =>
            CategoryTreeModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return CategoriesListResult(items: items, currentPage: 1, lastPage: 1);
  }

  Future<List<CategoryTreeModel>> getCategoriesTree() async {
    final result = await getCategories();
    return buildCategoryTree(result.items);
  }

  static List<CategoryTreeModel> buildCategoryTree(
    List<CategoryTreeModel> flat,
  ) {
    final childrenMap = <int, List<CategoryTreeModel>>{};
    for (final c in flat) {
      final parentId = c.parentId;
      if (parentId != null) {
        childrenMap.putIfAbsent(parentId, () => []).add(c);
      }
    }

    CategoryTreeModel withChildren(CategoryTreeModel node) {
      final kids = childrenMap[node.id] ?? const [];
      return CategoryTreeModel(
        id: node.id,
        name: node.name,
        slug: node.slug,
        description: node.description,
        imagePath: node.imagePath,
        position: node.position,
        isActive: node.isActive,
        isFeatured: node.isFeatured,
        parentId: node.parentId,
        meta: node.meta,
        fullPath: node.fullPath,
        hasProducts: node.hasProducts,
        hasActiveProducts: node.hasActiveProducts,
        vendorsCount: node.vendorsCount,
        productsCount: node.productsCount,
        images: node.images,
        children: kids.map(withChildren).toList(),
      );
    }

    return flat.where((c) => c.parentId == null).map(withChildren).toList();
  }

  Future<List<VendorModel>> getVendors({int page = 1}) async {
    final response = await dataProvider.getVendors(page: page);
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final list = _unwrapPaginatedList(response['data']);
    return list
        .map((e) =>
            VendorModel.fromVendorListJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CategoriesProductsModel?> getProductById(int productId) async {
    final response = await dataProvider.getProductById(productId);
    if (response['statusCode'] != 200) return null;
    final map = _unwrapEntity(response['data']);
    if (map == null) return null;
    return CategoriesProductsModel.fromMap(map);
  }

  Future<List<BranchModel>> getBranches({required int vendorId}) async {
    final response = await dataProvider.getBranches(vendorId: vendorId);
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final list = _unwrapList(response['data']);
    return list
        .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<BranchModel>> getNearbyBranches({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) async {
    final response = await dataProvider.getNearbyBranches(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final list = _unwrapList(response['data']);
    return list
        .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  ProductsListResult _parseProductsResponse(Map<String, dynamic> response) {
    if (response['statusCode'] != 200) {
      throw Exception(
        _clean(response['errorMessage']?.toString() ?? 'Error fetching products'),
      );
    }
    return ProductsListResult.fromResponseData(response['data']);
  }

  static List<dynamic> _unwrapList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) return data['data'] as List;
      if (data['data'] is Map && (data['data'] as Map)['data'] is List) {
        return (data['data'] as Map)['data'] as List;
      }
    }
    return [];
  }

  static List<dynamic> _unwrapPaginatedList(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List;
    }
    return _unwrapList(data);
  }

  static Map<String, dynamic>? _unwrapEntity(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      if (data.containsKey('id')) return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return null;
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) message = message.substring(11);
    if (message.startsWith('ApiException: ')) message = message.substring(14);
    return message;
  }
}
