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

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      imagePath: json['image_path'],
      position: json['position'],
      isActive: json['is_active'],
      isFeatured: json['is_featured'],
      parentId: json['parent_id'],
      meta: Map<String, dynamic>.from(json['meta'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
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
  String? get icon => meta['icon'];
  String? get color => meta['color'];
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