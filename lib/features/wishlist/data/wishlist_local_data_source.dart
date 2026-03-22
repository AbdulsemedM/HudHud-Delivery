import 'package:hudhud_delivery/core/local_db/app_database.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:sqflite/sqflite.dart';

class WishlistLocalDataSource {
  WishlistLocalDataSource({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  static const String table = 'wishlist_items';

  Future<bool> isWishlisted({required int userId, required int productId}) async {
    final database = await _db.database;
    final result = await database.query(
      table,
      columns: const ['id'],
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> upsert({
    required int userId,
    required CategoriesProductsModel product,
  }) async {
    final productId = product.id;
    if (productId == null) {
      throw ArgumentError('Wishlist requires product.id to be non-null');
    }

    final database = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(
      table,
      {
        'user_id': userId,
        'product_id': productId,
        'product_json': product.toJson(),
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove({required int userId, required int productId}) async {
    final database = await _db.database;
    await database.delete(
      table,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }

  Future<int> toggle({
    required int userId,
    required CategoriesProductsModel product,
  }) async {
    final productId = product.id;
    if (productId == null) {
      throw ArgumentError('Wishlist requires product.id to be non-null');
    }

    final exists = await isWishlisted(userId: userId, productId: productId);
    if (exists) {
      await remove(userId: userId, productId: productId);
      return 0;
    }

    await upsert(userId: userId, product: product);
    return 1;
  }

  Future<List<CategoriesProductsModel>> getAll({required int userId}) async {
    final database = await _db.database;
    final rows = await database.query(
      table,
      columns: const ['product_json'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return rows
        .map((r) => CategoriesProductsModel.fromJson(r['product_json'] as String))
        .where((p) => p.id != null)
        .toList(growable: false);
  }
}

