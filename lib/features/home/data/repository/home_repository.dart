import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_data_provider.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_repository.dart';
import 'package:hudhud_delivery/features/home/model/category_model.dart';

import '../data_provider/home_data_provider.dart';

class HomeRepository {
  final HomeDataProvider homeDataProvider;
  final PublicCatalogRepository? publicCatalogRepository;

  HomeRepository({
    required this.homeDataProvider,
    PublicCatalogRepository? publicCatalogRepository,
  }) : publicCatalogRepository = publicCatalogRepository ??
            PublicCatalogRepository(
              dataProvider: PublicCatalogDataProvider(
                apiService: ApiService.instance,
              ),
            );

  Future<bool> _usePublicCatalog() => GuestBrowseService().isActive();

  Future<List<CategoryModel>> getCategories() async {
    if (await _usePublicCatalog()) {
      final result = await publicCatalogRepository!.getCategories();
      return result.items
          .map(
            (c) => CategoryModel(
              id: c.id,
              name: c.name,
              slug: c.slug,
              description: c.description,
              image_path: c.displayImageUrl,
              position: c.position,
              is_active: c.isActive,
              is_featured: c.isFeatured,
              icon: c.meta?['icon']?.toString(),
              color: c.meta?['color']?.toString(),
            ),
          )
          .toList();
    }
    final response = await homeDataProvider.getCategories();
    if (response['statusCode'] == 200) {
      final body = response['data'] as Map<String, dynamic>?;
      final paginated = body?['data'] as Map<String, dynamic>?;
      final list = paginated?['data'] as List?;
      if (list == null) return [];
      return list
          .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(response['errorMessage'] ?? 'Failed to load categories');
    }
  }
}
