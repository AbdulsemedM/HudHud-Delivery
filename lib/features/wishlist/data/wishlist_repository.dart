import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_data_provider.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_migration_service.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_item_model.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_list_result.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_query.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_share_result.dart';

class WishlistRepository {
  WishlistRepository({
    WishlistDataProvider? dataProvider,
    WishlistMigrationService? migrationService,
  })  : _dataProvider = dataProvider ??
            WishlistDataProvider(apiService: ApiService.instance),
        _migration = migrationService ?? WishlistMigrationService();

  final WishlistDataProvider _dataProvider;
  final WishlistMigrationService _migration;

  List<WishlistItemModel> _cachedItems = [];

  Future<void> migrateIfNeeded(int userId) {
    return _migration.migrateIfNeeded(
      userId: userId,
      dataProvider: _dataProvider,
    );
  }

  Future<WishlistListResult> getWishlist({
    WishlistQuery query = const WishlistQuery(),
  }) async {
    final response = await _dataProvider.getWishlist(query);
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final result = WishlistListResult.fromResponseData(response['data']);
    _cachedItems = result.items;
    return result;
  }

  Future<WishlistItemModel> addProduct({
    required int productId,
    String? notes,
    CategoriesProductsModel? product,
  }) async {
    final response = await _dataProvider.addProduct(
      productId: productId,
      notes: notes,
    );
    if (response['statusCode'] != 200 && response['statusCode'] != 201) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final data = response['data'];
    WishlistItemModel item;
    if (data is Map<String, dynamic> && data['data'] is Map) {
      item = WishlistItemModel.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    } else if (data is Map<String, dynamic>) {
      item = WishlistItemModel.fromJson(data);
    } else {
      item = WishlistItemModel(
        id: 0,
        userId: 0,
        productId: productId,
        product: product,
        notes: notes,
      );
    }
    if (product != null && item.product == null) {
      item = item.copyWith(product: product);
    }
    _cachedItems = [item, ..._cachedItems.where((i) => i.productId != productId)];
    return item;
  }

  Future<void> removeByWishlistId(int wishlistId) async {
    final response = await _dataProvider.removeItem(wishlistId);
    if (response['statusCode'] != 200 && response['statusCode'] != 204) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    _cachedItems = _cachedItems.where((i) => i.id != wishlistId).toList();
  }

  Future<void> bulkRemoveByProductIds(List<int> productIds) async {
    if (productIds.isEmpty) return;
    final response = await _dataProvider.bulkRemove(productIds);
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    _cachedItems =
        _cachedItems.where((i) => !productIds.contains(i.productId)).toList();
  }

  Future<WishlistItemModel> updateNotes(int wishlistId, String notes) async {
    final response = await _dataProvider.updateNotes(wishlistId, notes);
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final data = response['data'];
    final map = data is Map<String, dynamic>
        ? (data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data)
        : <String, dynamic>{};
    final item = WishlistItemModel.fromJson(map);
    _cachedItems = _cachedItems
        .map((i) => i.id == wishlistId ? item : i)
        .toList(growable: false);
    return item;
  }

  Future<WishlistShareResult> shareWishlist({
    required String email,
    String permission = 'view',
    int expiresInDays = 7,
  }) async {
    final response = await _dataProvider.shareWishlist(
      email: email,
      permission: permission,
      expiresInDays: expiresInDays,
    );
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final inner = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;
      return WishlistShareResult.fromJson(inner);
    }
    throw Exception('Invalid share response');
  }

  Future<WishlistPriceDropsResult> getPriceDrops() async {
    final response = await _dataProvider.getPriceDrops();
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    return WishlistPriceDropsResult.fromResponse(
      response['data'] as Map<String, dynamic>?,
    );
  }

  WishlistItemModel? findCachedByProductId(int productId) {
    for (final item in _cachedItems) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  Future<bool> isWishlisted(int productId) async {
    final cached = findCachedByProductId(productId);
    if (cached != null) return true;
    final result = await getWishlist();
    return result.items.any((i) => i.productId == productId);
  }

  Future<bool> toggleProduct({
    required int productId,
    CategoriesProductsModel? product,
    String? notes,
    int? wishlistId,
  }) async {
    final existing = findCachedByProductId(productId);
    if (existing != null || wishlistId != null) {
      final id = existing?.id ?? wishlistId;
      if (id != null && id > 0) {
        await removeByWishlistId(id);
        return false;
      }
      await bulkRemoveByProductIds([productId]);
      return false;
    }
    await addProduct(productId: productId, notes: notes, product: product);
    return true;
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) message = message.substring(11);
    if (message.startsWith('ApiException: ')) message = message.substring(14);
    return message;
  }
}
