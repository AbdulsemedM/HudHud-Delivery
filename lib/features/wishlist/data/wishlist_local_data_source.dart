import 'package:hudhud_delivery/core/local_db/app_database.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class WishlistLocalDataSource {
  WishlistLocalDataSource({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;
  static final Map<int, Map<int, CategoriesProductsModel>> _memoryStore = {};

  static const String table = 'wishlist_items';

  Future<bool> isWishlisted({required int userId, required int productId}) async {
    try {
      final database = await _db.database;
      final result = await database.query(
        table,
        columns: const ['id'],
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
        limit: 1,
      );
      return result.isNotEmpty;
    } on MissingPluginException {
      return _memoryStore[userId]?.containsKey(productId) ?? false;
    } on DatabaseException {
      return _memoryStore[userId]?.containsKey(productId) ?? false;
    }
  }

  Future<void> upsert({
    required int userId,
    required CategoriesProductsModel product,
  }) async {
    final productId = product.id;
    if (productId == null) {
      throw ArgumentError('Wishlist requires product.id to be non-null');
    }

    try {
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
    } on MissingPluginException {
      _memoryStore.putIfAbsent(userId, () => {})[productId] = product;
    } on DatabaseException {
      _memoryStore.putIfAbsent(userId, () => {})[productId] = product;
    }
  }

  Future<void> remove({required int userId, required int productId}) async {
    try {
      final database = await _db.database;
      await database.delete(
        table,
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
    } on MissingPluginException {
      _memoryStore[userId]?.remove(productId);
    } on DatabaseException {
      _memoryStore[userId]?.remove(productId);
    }
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
    try {
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
    } on MissingPluginException {
      final map = _memoryStore[userId];
      if (map == null) return const [];
      return map.values.toList(growable: false);
    } on DatabaseException {
      final map = _memoryStore[userId];
      if (map == null) return const [];
      return map.values.toList(growable: false);
    }
  }
}

