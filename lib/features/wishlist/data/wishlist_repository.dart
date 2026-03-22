import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_local_data_source.dart';

class WishlistRepository {
  WishlistRepository({WishlistLocalDataSource? local})
      : _local = local ?? WishlistLocalDataSource();

  final WishlistLocalDataSource _local;

  Future<bool> isWishlisted({
    required int userId,
    required int productId,
  }) =>
      _local.isWishlisted(userId: userId, productId: productId);

  Future<int> toggleWishlist({
    required int userId,
    required CategoriesProductsModel product,
  }) =>
      _local.toggle(userId: userId, product: product);

  Future<void> add({
    required int userId,
    required CategoriesProductsModel product,
  }) =>
      _local.upsert(userId: userId, product: product);

  Future<void> remove({
    required int userId,
    required int productId,
  }) =>
      _local.remove(userId: userId, productId: productId);

  Future<List<CategoriesProductsModel>> getWishlist({required int userId}) =>
      _local.getAll(userId: userId);
}

