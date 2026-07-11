// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class CategoriesProductsModel {
  final int? id;
  final int? vendor_id;
  final int? category_id;
  final String? name;
  final String? description;
  final String? price;
  final String? discount_price;
  final String? cost_price;
  final int? quantity;
  final String? sku;
  final String? barcode;
  final String? image_path;
  final List<String>? gallery_images;
  final List<String>? ingredients;
  final List<String>? allergens;  
  final String? protein;
  final int? calories;
  final int? preparation_time;
  final Map<String, dynamic>? options;
  final List<String>? addons;
  final int? min_selection;
  final int? max_selection;
  final String? current_price;
  final String? formatted_price;
  final String? formatted_original_price;
  final bool? is_on_discount;
  final int? discount_percentage;
  final bool? is_available;
  final String? status;
  CategoriesProductsModel({
    this.id,
    this.vendor_id,
    this.category_id,
    this.name,
    this.description,
    this.price,
    this.discount_price,
    this.cost_price,
    this.quantity,
    this.sku,
    this.barcode,
    this.image_path,
    this.gallery_images,
    this.ingredients,
    this.allergens,
    this.protein,
    this.calories,
    this.preparation_time,
    this.options,
    this.addons,
    this.min_selection,
    this.max_selection,
    this.current_price,
    this.formatted_price,
    this.formatted_original_price,
    this.is_on_discount,
    this.discount_percentage,
    this.is_available,
    this.status,
  });

  /// Whether the product can be added to cart (API: is_available + active status).
  bool get canOrder =>
      is_available != false && (status == null || status == 'active');

  static bool _parseBool(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is int) return value != 0;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  CategoriesProductsModel copyWith({
    int? id,
    int? vendor_id,
    int? category_id,
    String? name,
    String? description,
    String? price,
    String? discount_price,
    String? cost_price,
    int? quantity,
    String? sku,
    String? barcode,
    String? image_path,
    List<String>? gallery_images,
    List<String>? ingredients,
    List<String>? allergens,
    String? protein,
    int? calories,
    int? preparation_time,
    Map<String, dynamic>? options,
    List<String>? addons,
    int? min_selection,
    int? max_selection,
    String? current_price,
    String? formatted_price,
    String? formatted_original_price,
    bool? is_on_discount,
    int? discount_percentage,
    bool? is_available,
    String? status,
  }) {
    return CategoriesProductsModel(
      id: id ?? this.id,
      vendor_id: vendor_id ?? this.vendor_id,
      category_id: category_id ?? this.category_id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discount_price: discount_price ?? this.discount_price,
      cost_price: cost_price ?? this.cost_price,
      quantity: quantity ?? this.quantity,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      image_path: image_path ?? this.image_path,
      gallery_images: gallery_images ?? this.gallery_images,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      protein: protein ?? this.protein,
      calories: calories ?? this.calories,
      preparation_time: preparation_time ?? this.preparation_time,
      options: options ?? this.options,
      addons: addons ?? this.addons,
      min_selection: min_selection ?? this.min_selection,
      max_selection: max_selection ?? this.max_selection,
      current_price: current_price ?? this.current_price,
      formatted_price: formatted_price ?? this.formatted_price,
      formatted_original_price: formatted_original_price ?? this.formatted_original_price,
      is_on_discount: is_on_discount ?? this.is_on_discount,
      discount_percentage: discount_percentage ?? this.discount_percentage,
      is_available: is_available ?? this.is_available,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'vendor_id': vendor_id,
      'category_id': category_id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discount_price,
      'cost_price': cost_price,
      'quantity': quantity,
      'sku': sku,
      'barcode': barcode,
      'image_path': image_path,
      'gallery_images': gallery_images,
      'ingredients': ingredients,
      'allergens': allergens,
      'protein': protein,
      'calories': calories,
      'preparation_time': preparation_time,
      'options': options,
      'addons': addons,
      'min_selection': min_selection,
      'max_selection': max_selection,
      'current_price': current_price,
      'formatted_price': formatted_price,
      'formatted_original_price': formatted_original_price,
      'is_on_discount': is_on_discount,
      'discount_percentage': discount_percentage,
      'is_available': is_available,
      'status': status,
    };
  }

  static Map<String, dynamic>? _parseOptions(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null || value is! List) return null;
    final items = value
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items;
  }

  /// Parses gallery_images from API: list of { original, thumb, small, medium, large, webp } -> list of URLs.
  static List<String>? _parseGalleryImages(dynamic value) {
    if (value == null || value is! List) return null;
    final urls = <String>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) continue;
      final url = item['medium'] ?? item['thumb'] ?? item['original'];
      if (url != null && url is String) urls.add(url);
    }
    return urls.isEmpty ? null : urls;
  }

  factory CategoriesProductsModel.fromMap(Map<String, dynamic> map) {
    return CategoriesProductsModel(
      id: map['id'] != null ? (map['id'] is String ? int.tryParse(map['id']) : map['id'] as int) : null,
      vendor_id: map['vendor_id'] != null ? (map['vendor_id'] is String ? int.tryParse(map['vendor_id']) : map['vendor_id'] as int) : null,
      category_id: map['category_id'] != null ? (map['category_id'] is String ? int.tryParse(map['category_id']) : map['category_id'] as int) : null,
      name: map['name'] != null ? map['name'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
      price: map['price'] != null ? map['price'].toString() : null,
      discount_price: map['discount_price'] != null ? map['discount_price'].toString() : null,
      cost_price: map['cost_price'] != null ? map['cost_price'].toString() : null,
      quantity: map['quantity'] != null ? (map['quantity'] is String ? int.tryParse(map['quantity']) : map['quantity'] as int) : null,
      sku: map['sku'] != null ? map['sku'] as String : null,
      barcode: map['barcode'] != null ? map['barcode'] as String : null,
      image_path: (map['image_path'] ?? (map['main_image'] is Map ? (map['main_image'] as Map)['medium'] : null))?.toString(),
      gallery_images: _parseGalleryImages(map['gallery_images']),
      ingredients: _parseStringList(map['ingredients']),
      allergens: _parseStringList(map['allergens']),
      protein: map['nutrition_facts'] != null && map['nutrition_facts']['protein'] != null ? map['nutrition_facts']['protein'].toString() : null,
      calories: map['nutrition_facts'] != null && map['nutrition_facts']['calories'] != null ? (map['nutrition_facts']['calories'] is String ? int.tryParse(map['nutrition_facts']['calories']) : map['nutrition_facts']['calories'] as int) : null,
      preparation_time: map['preparation_time'] != null ? (map['preparation_time'] is String ? int.tryParse(map['preparation_time']) : map['preparation_time'] as int) : null,
      options: _parseOptions(map['options']),
      addons: _parseStringList(map['addons']),
      min_selection: map['min_selection'] != null ? (map['min_selection'] is String ? int.tryParse(map['min_selection']) : map['min_selection'] as int) : null,
      max_selection: map['max_selection'] != null ? (map['max_selection'] is String ? int.tryParse(map['max_selection']) : map['max_selection'] as int) : null,
      current_price: map['current_price']?.toString(),
      formatted_price: map['formatted_price']?.toString(),
      formatted_original_price: map['formatted_original_price']?.toString(),
      is_on_discount: _parseBool(map['is_on_discount'], fallback: false),
      discount_percentage: map['discount_percentage'] != null ? (map['discount_percentage'] is String ? int.tryParse(map['discount_percentage']) : map['discount_percentage'] as int) : null,
      is_available: _parseBool(map['is_available'], fallback: true),
      status: map['status']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoriesProductsModel.fromJson(String source) => CategoriesProductsModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CategoriesProductsModel(id: $id, vendor_id: $vendor_id, category_id: $category_id, name: $name, description: $description, price: $price, discount_price: $discount_price, cost_price: $cost_price, quantity: $quantity, sku: $sku, barcode: $barcode, image_path: $image_path, gallery_images: $gallery_images, ingredients: $ingredients, allergens: $allergens, protein: $protein, calories: $calories, preparation_time: $preparation_time, options: $options, addons: $addons, min_selection: $min_selection, max_selection: $max_selection)';
  }

  @override
  bool operator ==(covariant CategoriesProductsModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.vendor_id == vendor_id &&
      other.category_id == category_id &&
      other.name == name &&
      other.description == description &&
      other.price == price &&
      other.discount_price == discount_price &&
      other.cost_price == cost_price &&
      other.quantity == quantity &&
      other.sku == sku &&
      other.barcode == barcode &&
      other.image_path == image_path &&
      listEquals(other.gallery_images, gallery_images) &&
      listEquals(other.ingredients, ingredients) &&
      listEquals(other.allergens, allergens) &&
      other.protein == protein &&
      other.calories == calories &&
      other.preparation_time == preparation_time &&
      mapEquals(other.options, options) &&
      listEquals(other.addons, addons) &&
      other.min_selection == min_selection &&
      other.max_selection == max_selection &&
      other.current_price == current_price &&
      other.formatted_price == formatted_price &&
      other.formatted_original_price == formatted_original_price &&
      other.is_on_discount == is_on_discount &&
      other.discount_percentage == discount_percentage &&
      other.is_available == is_available &&
      other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      vendor_id.hashCode ^
      category_id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      discount_price.hashCode ^
      cost_price.hashCode ^
      quantity.hashCode ^
      sku.hashCode ^
      barcode.hashCode ^
      image_path.hashCode ^
      gallery_images.hashCode ^
      ingredients.hashCode ^
      allergens.hashCode ^
      protein.hashCode ^
      calories.hashCode ^
      preparation_time.hashCode ^
      options.hashCode ^
      addons.hashCode ^
      min_selection.hashCode ^
      max_selection.hashCode ^
      current_price.hashCode ^
      formatted_price.hashCode ^
      formatted_original_price.hashCode ^
      is_on_discount.hashCode ^
      discount_percentage.hashCode ^
      is_available.hashCode ^
      status.hashCode;
  }
}
