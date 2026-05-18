import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? imagePath;
  final int position;
  final bool isActive;
  final bool isFeatured;
  final int? parentId;
  final Map<String, dynamic> meta;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.imagePath,
    required this.position,
    required this.isActive,
    required this.isFeatured,
    this.parentId,
    required this.meta,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
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
    return s == 'true' || s == '1';
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imagePath: json['image_path']?.toString(),
      position: _parseInt(json['position']),
      isActive: _parseBool(json['is_active'], fallback: true),
      isFeatured: _parseBool(json['is_featured']),
      parentId: json['parent_id'] != null ? _parseInt(json['parent_id']) : null,
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image_path': imagePath,
      'position': position,
      'is_active': isActive,
      'is_featured': isFeatured,
      'parent_id': parentId,
      'meta': meta,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // Helper methods
  String? get icon => meta['icon']?.toString();
  String? get color => meta['color']?.toString();
  bool get hasParent => parentId != null;

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        imagePath,
        position,
        isActive,
        isFeatured,
        parentId,
        meta,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
