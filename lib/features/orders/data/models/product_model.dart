import 'package:equatable/equatable.dart';
import 'category_model.dart';
import 'vendor_model.dart';

class ProductModel extends Equatable {
  final int id;
  final int vendorId;
  final int categoryId;
  final String name;
  final String description;
  final String price;
  final String? discountPrice;
  final String costPrice;
  final int quantity;
  final String sku;
  final String barcode;
  final String imagePath;
  final List<String> galleryImages;
  final List<String> ingredients;
  final List<String> allergens;
  final Map<String, dynamic> nutritionFacts;
  final int preparationTime;
  final bool isFeatured;
  final bool isAvailable;
  final String status;
  final Map<String, dynamic> options;
  final List<String> addons;
  final int minSelection;
  final int maxSelection;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryModel? category;
  final VendorModel? vendor;

  const ProductModel({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.costPrice,
    required this.quantity,
    required this.sku,
    required this.barcode,
    required this.imagePath,
    required this.galleryImages,
    required this.ingredients,
    required this.allergens,
    required this.nutritionFacts,
    required this.preparationTime,
    required this.isFeatured,
    required this.isAvailable,
    required this.status,
    required this.options,
    required this.addons,
    required this.minSelection,
    required this.maxSelection,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.vendor,
  });

  static int _parseInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  static bool _parseBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is int) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  static Map<String, dynamic> _parseOptions(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];
    return value
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _imageFromJson(Map<String, dynamic> json) {
    final path = json['image_path']?.toString();
    if (path != null && path.isNotEmpty) return path;
    final mainImage = json['main_image'];
    if (mainImage is Map) {
      return mainImage['medium']?.toString() ??
          mainImage['thumb']?.toString() ??
          mainImage['original']?.toString() ??
          '';
    }
    return '';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'];
    final vendorRaw = json['vendor'];

    return ProductModel(
      id: _parseInt(json['id']),
      vendorId: _parseInt(json['vendor_id']),
      categoryId: _parseInt(json['category_id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      discountPrice: json['discount_price']?.toString(),
      costPrice: json['cost_price']?.toString() ?? '0',
      quantity: _parseInt(json['quantity']),
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      imagePath: _imageFromJson(json),
      galleryImages: _parseStringList(json['gallery_images']),
      ingredients: _parseStringList(json['ingredients']),
      allergens: _parseStringList(json['allergens']),
      nutritionFacts: json['nutrition_facts'] is Map
          ? Map<String, dynamic>.from(json['nutrition_facts'] as Map)
          : {},
      preparationTime: _parseInt(json['preparation_time']),
      isFeatured: _parseBool(json['is_featured']),
      isAvailable: _parseBool(json['is_available'], fallback: true),
      status: json['status']?.toString() ?? 'active',
      options: _parseOptions(json['options']),
      addons: _parseStringList(json['addons']),
      minSelection: _parseInt(json['min_selection']),
      maxSelection: _parseInt(json['max_selection']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      category: categoryRaw is Map
          ? CategoryModel.fromJson(Map<String, dynamic>.from(categoryRaw))
          : null,
      vendor: vendorRaw is Map
          ? _parseVendor(Map<String, dynamic>.from(vendorRaw))
          : null,
    );
  }

  static VendorModel _parseVendor(Map<String, dynamic> map) {
    if (map['shop_name'] != null) {
      return VendorModel.fromVendorListJson(map);
    }
    return VendorModel.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'cost_price': costPrice,
      'quantity': quantity,
      'sku': sku,
      'barcode': barcode,
      'image_path': imagePath,
      'gallery_images': galleryImages,
      'ingredients': ingredients,
      'allergens': allergens,
      'nutrition_facts': nutritionFacts,
      'preparation_time': preparationTime,
      'is_featured': isFeatured,
      'is_available': isAvailable,
      'status': status,
      'options': options,
      'addons': addons,
      'min_selection': minSelection,
      'max_selection': maxSelection,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (category != null) 'category': category!.toJson(),
      if (vendor != null) 'vendor': vendor!.toJson(),
    };
  }

  // Helper methods
  bool get hasDiscount => discountPrice != null && discountPrice!.isNotEmpty;

  String get displayPrice => hasDiscount ? discountPrice! : price;

  String get formattedPrice {
    if (hasDiscount) {
      return 'ETB $discountPrice (was ETB $price)';
    }
    return 'ETB $price';
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        categoryId,
        name,
        description,
        price,
        discountPrice,
        costPrice,
        quantity,
        sku,
        barcode,
        imagePath,
        galleryImages,
        ingredients,
        allergens,
        nutritionFacts,
        preparationTime,
        isFeatured,
        isAvailable,
        status,
        options,
        addons,
        minSelection,
        maxSelection,
        createdAt,
        updatedAt,
        category,
        vendor,
      ];
}
