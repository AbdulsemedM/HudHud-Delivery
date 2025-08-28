// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CategoryModel {
  final int? id;
  final String? name;
  final String? slug;
  final String? description;
  final String? image_path;
  final int? position;
  final bool? is_active;
  final bool? is_featured;
  final String? icon;
  final String? color;
  CategoryModel({
    this.id,
    this.name,
    this.slug,
    this.description,
    this.image_path,
    this.position,
    this.is_active,
    this.is_featured,
    this.icon,
    this.color,
  });
 

  CategoryModel copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? image_path,
    int? position,
    bool? is_active,
    bool? is_featured,
    String? icon,
    String? color,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      image_path: image_path ?? this.image_path,
      position: position ?? this.position,
      is_active: is_active ?? this.is_active,
      is_featured: is_featured ?? this.is_featured,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image_path': image_path,
      'position': position,
      'is_active': is_active,
      'is_featured': is_featured,
      'icon': icon,
      'color': color,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
      slug: map['slug'] != null ? map['slug'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
      image_path: map['image_path'] != null ? map['image_path'] as String : null,
      position: map['position'] != null ? map['position'] as int : null,
      is_active: map['is_active'] != null ? map['is_active'] as bool : null,
      is_featured: map['is_featured'] != null ? map['is_featured'] as bool : null,
      icon: map['icon'] != null ? map['icon'] as String : null,
      color: map['color'] != null ? map['color'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoryModel.fromJson(String source) => CategoryModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, slug: $slug, description: $description, image_path: $image_path, position: $position, is_active: $is_active, is_featured: $is_featured, icon: $icon, color: $color)';
  }

  @override
  bool operator ==(covariant CategoryModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.slug == slug &&
      other.description == description &&
      other.image_path == image_path &&
      other.position == position &&
      other.is_active == is_active &&
      other.is_featured == is_featured &&
      other.icon == icon &&
      other.color == color;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      slug.hashCode ^
      description.hashCode ^
      image_path.hashCode ^
      position.hashCode ^
      is_active.hashCode ^
      is_featured.hashCode ^
      icon.hashCode ^
      color.hashCode;
  }
}
