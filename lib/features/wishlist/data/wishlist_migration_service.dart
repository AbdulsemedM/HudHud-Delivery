import 'package:shared_preferences/shared_preferences.dart';

import 'wishlist_data_provider.dart';
import 'wishlist_local_data_source.dart';

class WishlistMigrationService {
  WishlistMigrationService({
    WishlistLocalDataSource? localDataSource,
  }) : _local = localDataSource ?? WishlistLocalDataSource();

  final WishlistLocalDataSource _local;

  static String _flagKey(int userId) => 'wishlist_migrated_$userId';

  Future<bool> isMigrated(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_flagKey(userId)) ?? false;
  }

  Future<void> _setMigrated(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flagKey(userId), true);
  }

  Future<void> migrateIfNeeded({
    required int userId,
    required WishlistDataProvider dataProvider,
  }) async {
    if (await isMigrated(userId)) return;

    final localItems = await _local.getAll(userId: userId);
    for (final product in localItems) {
      final productId = product.id;
      if (productId == null) continue;
      try {
        final response = await dataProvider.addProduct(productId: productId);
        final status = response['statusCode'] as int? ?? 500;
        if (status != 200 && status != 201 && status != 409) {
          // Continue migrating other items; flag only set after clear.
        }
      } catch (_) {
        // Best-effort migration per item.
      }
    }

    await _local.clearLocalForUser(userId: userId);
    await _setMigrated(userId);
  }
}
