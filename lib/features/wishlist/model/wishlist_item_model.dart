import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

import 'wishlist_price_drop_model.dart';

class WishlistItemModel {
  final int id;
  final int userId;
  final int productId;
  final int? vendorId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isInStock;
  final WishlistPriceDropModel? priceDrop;
  final CategoriesProductsModel? product;

  const WishlistItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.vendorId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.isInStock = true,
    this.priceDrop,
    this.product,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    return WishlistItemModel(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      productId: _parseInt(json['product_id']) ?? 0,
      vendorId: _parseInt(json['vendor_id']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      isInStock: json['is_in_stock'] != false,
      priceDrop: json['price_drop'] is Map
          ? WishlistPriceDropModel.fromJson(
              Map<String, dynamic>.from(json['price_drop'] as Map),
            )
          : null,
      product: productJson is Map
          ? CategoriesProductsModel.fromMap(
              Map<String, dynamic>.from(productJson),
            )
          : null,
    );
  }

  WishlistItemModel copyWith({
    String? notes,
    CategoriesProductsModel? product,
  }) {
    return WishlistItemModel(
      id: id,
      userId: userId,
      productId: productId,
      vendorId: vendorId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isInStock: isInStock,
      priceDrop: priceDrop,
      product: product ?? this.product,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
