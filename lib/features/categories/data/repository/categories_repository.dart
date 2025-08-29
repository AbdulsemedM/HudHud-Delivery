import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

import '../data_provider/categories_data_provider.dart';

class CategoriesRepository {
  final CategoriesDataProvider categoriesDataProvider;
  CategoriesRepository({required this.categoriesDataProvider});

  Future<List<CategoriesProductsModel>> getCategoriesProducts(
      {required int categoryId}) async {
    try {
      final response = await categoriesDataProvider.getCategoriesProducts(
        categoryId: categoryId,
      );
      if (response['statusCode'] == 200) {
        final List<CategoriesProductsModel> categoriesProducts =
            (response['data']['data']['data'] as List)
                .map((e) => CategoriesProductsModel.fromMap(e))
                .toList();
        return categoriesProducts;
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
