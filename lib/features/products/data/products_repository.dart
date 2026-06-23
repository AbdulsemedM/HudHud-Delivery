import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_data_provider.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_repository.dart';
import 'package:hudhud_delivery/features/products/data/products_data_provider.dart';
import 'package:hudhud_delivery/features/products/model/products_list_result.dart';
import 'package:hudhud_delivery/features/products/model/products_query.dart';

class ProductsRepository {
  final ProductsDataProvider productsDataProvider;
  final PublicCatalogRepository? publicCatalogRepository;

  ProductsRepository({
    required this.productsDataProvider,
    PublicCatalogRepository? publicCatalogRepository,
  }) : publicCatalogRepository = publicCatalogRepository ??
            PublicCatalogRepository(
              dataProvider: PublicCatalogDataProvider(
                apiService: ApiService.instance,
              ),
            );

  Future<bool> _usePublicCatalog() => GuestBrowseService().isActive();

  Future<ProductsListResult> getProducts(ProductsQuery query) async {
    if (await _usePublicCatalog()) {
      return publicCatalogRepository!.getProducts(query);
    }
    final response = await productsDataProvider.getProducts(query);
    if (response['statusCode'] != 200) {
      throw Exception(
        _clean(response['errorMessage']?.toString() ?? 'Error fetching products'),
      );
    }
    return ProductsListResult.fromResponseData(response['data']);
  }

  Future<List<CategoriesProductsModel>> getFeaturedProducts({
    int limit = 10,
  }) async {
    return publicCatalogRepository!.getFeaturedProducts(limit: limit);
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
