import 'package:hudhud_delivery/features/products/data/products_data_provider.dart';
import 'package:hudhud_delivery/features/products/model/products_list_result.dart';
import 'package:hudhud_delivery/features/products/model/products_query.dart';

class ProductsRepository {
  final ProductsDataProvider productsDataProvider;

  ProductsRepository({required this.productsDataProvider});

  Future<ProductsListResult> getProducts(ProductsQuery query) async {
    final response = await productsDataProvider.getProducts(query);
    if (response['statusCode'] != 200) {
      throw Exception(
        _clean(response['errorMessage']?.toString() ?? 'Error fetching products'),
      );
    }
    return ProductsListResult.fromResponseData(response['data']);
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    if (message.startsWith('ApiException: ')) {
      message = message.substring(14);
    }
    return message;
  }
}
