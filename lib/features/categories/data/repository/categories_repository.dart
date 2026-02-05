import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';

import '../data_provider/categories_data_provider.dart';

class CategoriesRepository {
  final CategoriesDataProvider categoriesDataProvider;
  CategoriesRepository({required this.categoriesDataProvider});

  /// Fetches categories tree from /api/categories/tree.
  /// Returns root-level categories, each with nested [CategoryTreeModel.children].
  Future<List<CategoryTreeModel>> getCategoriesTree() async {
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

  Future<List<CategoriesProductsModel>> getCategoriesProducts(
      {required int categoryId}) async {
    try {
      final response = await categoriesDataProvider.getCategoriesProducts(
        categoryId: categoryId,
      );
      if (response['statusCode'] == 200) {
        final body = response['data'] as Map<String, dynamic>?;
        final paginated = body?['data'] as Map<String, dynamic>?;
        final list = paginated?['data'] as List?;
        if (list == null) return [];
        return list
            .map((e) => CategoriesProductsModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        String errorMessage =
            response['errorMessage'] ?? " Error Fetching products";
        errorMessage = _cleanErrorMessage(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = e.toString();
      errorMessage = _cleanErrorMessage(errorMessage);
      throw Exception(errorMessage);
    }
  }

  String _cleanErrorMessage(String message) {
    // Remove various prefixes that might appear
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
