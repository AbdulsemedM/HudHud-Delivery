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
  final CategoryModel category;
  final VendorModel vendor;

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
    required this.category,
    required this.vendor,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      vendorId: json['vendor_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      discountPrice: json['discount_price'],
      costPrice: json['cost_price'],
      quantity: json['quantity'],
      sku: json['sku'],
      barcode: json['barcode'],
      imagePath: json['image_path'],
      galleryImages: List<String>.from(json['gallery_images'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
      nutritionFacts: Map<String, dynamic>.from(json['nutrition_facts'] ?? {}),
      preparationTime: json['preparation_time'],
      isFeatured: json['is_featured'],
      isAvailable: json['is_available'],
      status: json['status'],
      options: Map<String, dynamic>.from(json['options'] ?? {}),
      addons: List<String>.from(json['addons'] ?? []),
      minSelection: json['min_selection'],
      maxSelection: json['max_selection'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: CategoryModel.fromJson(json['category']),
      vendor: VendorModel.fromJson(json['vendor']),
    );
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
      'category': category.toJson(),
      'vendor': vendor.toJson(),
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