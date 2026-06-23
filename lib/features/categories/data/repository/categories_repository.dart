import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_data_provider.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_repository.dart';

import '../data_provider/categories_data_provider.dart';

/// Result of GET /api/categories?page= with pagination info.
class CategoriesListResult {
  final List<CategoryTreeModel> items;
  final int currentPage;
  final int lastPage;
  const CategoriesListResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });
  bool get hasMore => currentPage < lastPage;
}

class CategoriesRepository {
  final CategoriesDataProvider categoriesDataProvider;
  final PublicCatalogRepository? publicCatalogRepository;

  CategoriesRepository({
    required this.categoriesDataProvider,
    PublicCatalogRepository? publicCatalogRepository,
  }) : publicCatalogRepository = publicCatalogRepository ??
            PublicCatalogRepository(
              dataProvider: PublicCatalogDataProvider(
                apiService: ApiService.instance,
              ),
            );

  Future<bool> _usePublicCatalog() => GuestBrowseService().isActive();

  /// Fetches paginated categories list from /api/categories?page=.
  /// Returns list of categories; pagination info in [CategoriesListResult].
  Future<CategoriesListResult> getCategories({int page = 1}) async {
    if (await _usePublicCatalog()) {
      return publicCatalogRepository!.getCategories(page: page);
    }
    try {
      final response = await categoriesDataProvider.getCategories(page: page);
      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data == null) {
          return CategoriesListResult(items: [], currentPage: page, lastPage: page);
        }
        List<dynamic> list;
        int currentPage = page;
        int lastPage = page;
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          dynamic inner = data['data'];
          if (inner is List) {
            list = inner;
            currentPage = (data['current_page'] is int)
                ? data['current_page'] as int
                : (int.tryParse(data['current_page']?.toString() ?? '') ?? page);
            lastPage = (data['last_page'] is int)
                ? data['last_page'] as int
                : (int.tryParse(data['last_page']?.toString() ?? '') ?? page);
          } else if (inner is Map<String, dynamic>) {
            list = (inner['data'] is List) ? inner['data'] as List : [];
            currentPage = (inner['current_page'] is int)
                ? inner['current_page'] as int
                : page;
            lastPage = (inner['last_page'] is int) ? inner['last_page'] as int : page;
          } else {
            list = [];
          }
        } else {
          list = [];
        }
        final items = list
            .map((e) =>
                CategoryTreeModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return CategoriesListResult(
          items: items,
          currentPage: currentPage,
          lastPage: lastPage,
        );
      }
      final errorMessage = response['errorMessage'] ?? 'Error fetching categories';
      throw Exception(_cleanErrorMessage(errorMessage));
    } catch (e) {
      throw Exception(_cleanErrorMessage(e.toString()));
    }
  }

  /// Fetches categories tree from /api/categories/tree.
  /// Returns root-level categories, each with nested [CategoryTreeModel.children].
  Future<List<CategoryTreeModel>> getCategoriesTree() async {
    if (await _usePublicCatalog()) {
      return publicCatalogRepository!.getCategoriesTree();
    }
    try {
      final response = await categoriesDataProvider.getCategoriesTree();
      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data == null) return [];
        final list = data is List ? data : (data is Map ? data['data'] : null);
        if (list is! List) return [];
        return (list)
            .map((e) =>
                CategoryTreeModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final errorMessage =
          response['errorMessage'] ?? 'Error fetching categories tree';
      throw Exception(_cleanErrorMessage(errorMessage));
    } catch (e) {
      throw Exception(_cleanErrorMessage(e.toString()));
    }
  }

  /// GET /api/products/{id}
  Future<CategoriesProductsModel?> getProductById(int productId) async {
    if (await _usePublicCatalog()) {
      return publicCatalogRepository!.getProductById(productId);
    }
    try {
      final response = await categoriesDataProvider.getProductById(productId);
      if (response['statusCode'] != 200) return null;
      final data = response['data'];
      if (data == null) return null;
      Map<String, dynamic>? map;
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          map = data['data'] as Map<String, dynamic>;
        } else {
          map = data;
        }
      } else if (data is Map) {
        map = Map<String, dynamic>.from(data);
      }
      if (map == null) return null;
      return CategoriesProductsModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String _cleanErrorMessage(String message) {
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    if (message.startsWith('ApiException: ')) {
      message = message.substring(14);
    }
    if (message.startsWith('FormatException: ')) {
      message = message.substring(17);
    }
    return message;
  }
}
