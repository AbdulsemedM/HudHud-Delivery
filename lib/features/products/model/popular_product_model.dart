import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

class PopularProductModel {
  final CategoriesProductsModel product;
  final String? shopName;
  final int? shopId;
  final String? shopLogoUrl;
  final double shopRating;
  final int deliveryFee;
  final int? popularityScore;
  final String? totalOrders;

  const PopularProductModel({
    required this.product,
    this.shopName,
    this.shopId,
    this.shopLogoUrl,
    this.shopRating = 0,
    this.deliveryFee = 0,
    this.popularityScore,
    this.totalOrders,
  });

  String get displayImage =>
      product.image_path?.trim().isNotEmpty == true
          ? product.image_path!
          : '';

  String get displayPrice =>
      product.formatted_price ??
      product.current_price ??
      product.price ??
      '';

  String? get promoLabel {
    if (product.is_on_discount == true &&
        product.discount_percentage != null &&
        product.discount_percentage! > 0) {
      return '${product.discount_percentage}% off';
    }
    if (totalOrders != null && totalOrders!.isNotEmpty && totalOrders != '0') {
      return '$totalOrders orders';
    }
    if (popularityScore != null && popularityScore! > 0) {
      return 'Popular';
    }
    return null;
  }

  factory PopularProductModel.fromMap(Map<String, dynamic> map) {
    final vendorShop = map['vendor_shop'];
    String? shopName;
    int? shopId;
    String? shopLogo;
    double shopRating = 0;
    int deliveryFee = 0;

    if (vendorShop is Map) {
      final shop = Map<String, dynamic>.from(vendorShop);
      shopName = shop['shop_name']?.toString();
      shopId = int.tryParse(shop['id']?.toString() ?? '');
      shopLogo = shop['logo_path']?.toString();
      if (shopLogo == null || shopLogo.isEmpty) {
        final logoUrls = shop['logo_urls'];
        if (logoUrls is Map) {
          shopLogo = logoUrls['medium']?.toString() ??
              logoUrls['thumb']?.toString() ??
              logoUrls['original']?.toString();
        }
      }
      final ratingRaw = shop['average_rating'];
      if (ratingRaw is num) {
        shopRating = ratingRaw.toDouble();
      } else {
        shopRating = double.tryParse(ratingRaw?.toString() ?? '') ?? 0;
      }
      deliveryFee =
          double.tryParse(shop['delivery_fee']?.toString() ?? '')?.round() ?? 0;
    }

    return PopularProductModel(
      product: CategoriesProductsModel.fromMap(map),
      shopName: shopName,
      shopId: shopId,
      shopLogoUrl: shopLogo,
      shopRating: shopRating,
      deliveryFee: deliveryFee,
      popularityScore: int.tryParse(map['popularity_score']?.toString() ?? ''),
      totalOrders: map['total_orders']?.toString(),
    );
  }
}

class PopularProductsResult {
  final List<PopularProductModel> products;
  final Map<String, dynamic>? meta;

  const PopularProductsResult({
    required this.products,
    this.meta,
  });

  factory PopularProductsResult.fromResponseData(dynamic data) {
    if (data == null) {
      return const PopularProductsResult(products: []);
    }

    if (data is List) {
      return PopularProductsResult(
        products: data
            .whereType<Map>()
            .map((item) =>
                PopularProductModel.fromMap(Map<String, dynamic>.from(item)))
            .toList(),
      );
    }

    if (data is Map) {
      final body = Map<String, dynamic>.from(data);
      final list = body['data'];
      if (list is List) {
        return PopularProductsResult(
          products: list
              .whereType<Map>()
              .map((item) =>
                  PopularProductModel.fromMap(Map<String, dynamic>.from(item)))
              .toList(),
          meta: body['meta'] is Map
              ? Map<String, dynamic>.from(body['meta'] as Map)
              : null,
        );
      }
    }

    return const PopularProductsResult(products: []);
  }
}
