import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_query.dart';

class WishlistDataProvider {
  final ApiService apiService;

  WishlistDataProvider({required this.apiService});

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  Future<Map<String, dynamic>> _wrap(Future<dynamic> Function() call) async {
    try {
      final response = await call();
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addProduct({
    required int productId,
    String? notes,
  }) {
    final body = <String, dynamic>{'product_id': productId};
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }
    return _wrap(
      () => apiService.post(_url(ApiConstants.wishlistAdd), data: body),
    );
  }

  Future<Map<String, dynamic>> getWishlist(WishlistQuery query) {
    return _wrap(
      () => apiService.get(
        _url(ApiConstants.wishlist),
        queryParameters: query.toParams(),
      ),
    );
  }

  Future<Map<String, dynamic>> removeItem(int wishlistId) {
    return _wrap(
      () => apiService.delete(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.wishlistItem,
            {'id': wishlistId},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> bulkRemove(List<int> productIds) {
    return _wrap(
      () => apiService.post(
        _url(ApiConstants.wishlistBulkRemove),
        data: {'product_ids': productIds},
      ),
    );
  }

  Future<Map<String, dynamic>> updateNotes(int wishlistId, String notes) {
    return _wrap(
      () => apiService.put(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.wishlistItemNotes,
            {'id': wishlistId},
          ),
        ),
        data: {'notes': notes},
      ),
    );
  }

  Future<Map<String, dynamic>> shareWishlist({
    required String email,
    String permission = 'view',
    int expiresInDays = 7,
  }) {
    return _wrap(
      () => apiService.post(
        _url(ApiConstants.wishlistShare),
        data: {
          'email': email,
          'permission': permission,
          'expires_in_days': expiresInDays,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getPriceDrops() {
    return _wrap(
      () => apiService.get(_url(ApiConstants.wishlistPriceDrops)),
    );
  }
}
