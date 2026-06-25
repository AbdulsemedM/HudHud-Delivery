import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

/// Product from GET /api/popular/products with popularity stats and vendor shop.
class PopularProductModel {
  final CategoriesProductsModel product;
  final int totalOrders;
  final int totalQuantitySold;
  final double popularityScore;
  final String? vendorShopName;
  final String? shopLogoUrl;
  final double shopRating;
  final String? deliveryFee;
  final int? avgPreparationTime;
  final int? vendorShopId;
  final int? vendorUserId;

  const PopularProductModel({
    required this.product,
    this.totalOrders = 0,
    this.totalQuantitySold = 0,
    this.popularityScore = 0,
    this.vendorShopName,
    this.shopLogoUrl,
    this.shopRating = 0,
    this.deliveryFee,
    this.avgPreparationTime,
    this.vendorShopId,
    this.vendorUserId,
  });

  static List<PopularProductModel> parseResponse(dynamic body) {
    if (body is! Map) return [];
    final list = body['data'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => PopularProductModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory PopularProductModel.fromJson(Map<String, dynamic> json) {
    final vendorShop = json['vendor_shop'];
    Map<String, dynamic>? shopMap;
    if (vendorShop is Map) {
      shopMap = Map<String, dynamic>.from(vendorShop);
    }

    final logoUrls = shopMap?['logo_urls'];
    String? logoUrl = shopMap?['logo_path']?.toString();
    if (logoUrl == null || logoUrl.isEmpty) {
      if (logoUrls is Map) {
        logoUrl = logoUrls['medium']?.toString() ??
            logoUrls['thumb']?.toString() ??
            logoUrls['original']?.toString();
      }
    }

    final prepFromShop = shopMap?['avg_preparation_time'];
    final prepFromProduct = json['preparation_time'];
    final prepMinutes = _parseInt(prepFromShop) ?? _parseInt(prepFromProduct);

    return PopularProductModel(
      product: CategoriesProductsModel.fromMap(json),
      totalOrders: _parseInt(json['total_orders']) ?? 0,
      totalQuantitySold: _parseInt(json['total_quantity_sold']) ?? 0,
      popularityScore: _parseDouble(json['popularity_score']) ?? 0,
      vendorShopName: shopMap?['shop_name']?.toString(),
      shopLogoUrl: logoUrl,
      shopRating: _parseDouble(shopMap?['average_rating']) ?? 0,
      deliveryFee: shopMap?['delivery_fee']?.toString(),
      avgPreparationTime: prepMinutes,
      vendorShopId: _parseInt(shopMap?['id']),
      vendorUserId: _parseInt(json['vendor_id']),
    );
  }

  String get displayName => product.name ?? 'Product';

  String get imageUrl => product.image_path ?? '';

  String get priceLabel =>
      product.formatted_price ??
      product.current_price ??
      product.price ??
      '';

  int get deliveryFeeAmount =>
      double.tryParse(deliveryFee ?? '')?.round() ?? 0;

  String get deliveryTimeLabel {
    final mins = avgPreparationTime ?? product.preparation_time;
    if (mins == null || mins <= 0) return '';
    return '$mins min';
  }

  String? get promoText {
    if (totalOrders > 0) return '$totalOrders orders';
    if (popularityScore > 0) return 'Popular';
    return null;
  }

  String get secondaryLine {
    final parts = <String>[];
    if (priceLabel.isNotEmpty) parts.add(priceLabel);
    if (vendorShopName != null && vendorShopName!.isNotEmpty) {
      parts.add(vendorShopName!);
    }
    if (deliveryFeeAmount > 0) {
      parts.add('ETB $deliveryFeeAmount delivery');
    }
    final time = deliveryTimeLabel;
    if (time.isNotEmpty) parts.add(time);
    return parts.join(' • ');
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
