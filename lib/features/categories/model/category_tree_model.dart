// ignore_for_file: public_member_api_docs, sort_constructors_first

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
      meta: json['meta'] != null
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : null,
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
