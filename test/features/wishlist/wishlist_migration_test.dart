import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_data_provider.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_local_data_source.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_migration_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingWishlistDataProvider extends WishlistDataProvider {
  _RecordingWishlistDataProvider() : super(apiService: ApiService.instance);

  final List<int> addedProductIds = <int>[];

  @override
  Future<Map<String, dynamic>> addProduct({
    required int productId,
    String? notes,
  }) async {
    addedProductIds.add(productId);
    return {
      'statusCode': 201,
      'data': {
        'id': productId + 1000,
        'user_id': 1,
        'product_id': productId,
      },
      'errorMessage': null,
    };
  }
}

class _InMemoryWishlistLocalDataSource extends WishlistLocalDataSource {
  final Map<int, List<CategoriesProductsModel>> _store = {};

  @override
  Future<List<CategoriesProductsModel>> getAll({required int userId}) async {
    return List<CategoriesProductsModel>.from(_store[userId] ?? const []);
  }

  @override
  Future<void> upsert({
    required int userId,
    required CategoriesProductsModel product,
  }) async {
    final productId = product.id;
    if (productId == null) return;
    final list = _store.putIfAbsent(userId, () => []);
    list.removeWhere((p) => p.id == productId);
    list.add(product);
  }

  @override
  Future<void> clearLocalForUser({required int userId}) async {
    _store.remove(userId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WishlistMigrationService', () {
    const userId = 42;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('migrates local rows once, sets flag, and clears local', () async {
      final local = _InMemoryWishlistLocalDataSource();
      final provider = _RecordingWishlistDataProvider();
      final service = WishlistMigrationService(localDataSource: local);

      await local.upsert(
        userId: userId,
        product: CategoriesProductsModel(id: 10, name: 'A'),
      );
      await local.upsert(
        userId: userId,
        product: CategoriesProductsModel(id: 20, name: 'B'),
      );

      expect(await service.isMigrated(userId), isFalse);
      expect((await local.getAll(userId: userId)).length, 2);

      await service.migrateIfNeeded(userId: userId, dataProvider: provider);

      expect(provider.addedProductIds, [10, 20]);
      expect(await service.isMigrated(userId), isTrue);
      expect(await local.getAll(userId: userId), isEmpty);

      provider.addedProductIds.clear();
      await local.upsert(
        userId: userId,
        product: CategoriesProductsModel(id: 99, name: 'C'),
      );

      await service.migrateIfNeeded(userId: userId, dataProvider: provider);

      expect(provider.addedProductIds, isEmpty);
      expect((await local.getAll(userId: userId)).length, 1);
    });
  });
}
