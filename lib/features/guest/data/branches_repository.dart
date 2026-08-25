import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_data_provider.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_repository.dart';
import 'package:hudhud_delivery/features/guest/model/branch_model.dart';

class BranchesRepository {
  final PublicCatalogRepository _publicCatalogRepository;

  BranchesRepository({PublicCatalogRepository? publicCatalogRepository})
      : _publicCatalogRepository = publicCatalogRepository ??
            PublicCatalogRepository(
              dataProvider: PublicCatalogDataProvider(
                apiService: ApiService.instance,
              ),
            );

  Future<List<BranchModel>> getBranches({required int vendorId}) {
    return _publicCatalogRepository.getBranches(vendorId: vendorId);
  }

  Future<List<BranchModel>> getNearbyBranches({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) {
    return _publicCatalogRepository.getNearbyBranches(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }
}
