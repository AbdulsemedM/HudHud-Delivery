// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// Model for a category node from /api/categories/tree.
/// Supports nested [children] for tree structure.
class CategoryTreeModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imagePath;
  final int position;
  final bool isActive;
  final bool isFeatured;
  final int? parentId;
  final Map<String, dynamic>? meta;
  final String? fullPath;
  final bool hasProducts;
  final bool hasActiveProducts;
  final int vendorsCount;
  final int productsCount;
  final CategoryTreeImages? images;
  final List<CategoryTreeModel> children;

  const CategoryTreeModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imagePath,
    this.position = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.parentId,
    this.meta,
    this.fullPath,
    this.hasProducts = false,
    this.hasActiveProducts = false,
    this.vendorsCount = 0,
    this.productsCount = 0,
    this.images,
    this.children = const [],
  });

  /// Best URL for list/grid (small/thumb). Falls back to imagePath then original.
  String? get displayImageUrl {
    if (images?.small != null) return images!.small;
    if (images?.thumb != null) return images!.thumb;
    if (images?.original != null) return images!.original;
    return imagePath;
  }

  factory CategoryTreeModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>?;
    return CategoryTreeModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      position: _parseInt(json['position']) ?? 0,
      isActive: json['is_active'] == true,
      isFeatured: json['is_featured'] == true,
      parentId: _parseInt(json['parent_id']),
      meta: _parseMeta(json['meta']),
      fullPath: json['full_path'] as String?,
      hasProducts: json['has_products'] == true,
      hasActiveProducts: json['has_active_products'] == true,
      vendorsCount: _parseInt(json['vendors_count']) ?? 0,
      productsCount: _parseInt(json['products_count']) ?? 0,
      images: json['images'] != null
          ? CategoryTreeImages.fromJson(
              Map<String, dynamic>.from(json['images'] as Map))
          : null,
      children: childrenJson != null
          ? childrenJson
              .map((e) => CategoryTreeModel.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// API returns meta as either:
  ///   - null
  ///   - a Map  {"icon": "Male"}
  ///   - a List of JSON strings  ["{\"icon\":\"Male\"}"]
  /// Normalise all forms into a single Map.
  static Map<String, dynamic>? _parseMeta(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List) {
      // Merge all JSON-encoded entries in the list into one map.
      final merged = <String, dynamic>{};
      for (final entry in raw) {
        if (entry is String && entry.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(entry);
            if (decoded is Map) {
              merged.addAll(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {
            // ignore malformed entries
          }
        } else if (entry is Map) {
          merged.addAll(Map<String, dynamic>.from(entry));
        }
      }
      return merged.isEmpty ? null : merged;
    }
    return null;
  }
}

class CategoryTreeImages {
  final String? original;
  final String? thumb;
  final String? small;
  final String? medium;
  final String? large;
  final String? webp;

  const CategoryTreeImages({
    this.original,
    this.thumb,
    this.small,
    this.medium,
    this.large,
    this.webp,
  });

  factory CategoryTreeImages.fromJson(Map<String, dynamic> json) {
    return CategoryTreeImages(
      original: json['original'] as String?,
      thumb: json['thumb'] as String?,
      small: json['small'] as String?,
      medium: json['medium'] as String?,
      large: json['large'] as String?,
      webp: json['webp'] as String?,
    );
  }
}
