// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? type;
  final List<dynamic>? permissions;
  UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.type,
    this.permissions,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? type,
    List<dynamic>? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'type': type,
      'permissions': permissions,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      type: map['type'] != null ? map['type'] as String : null,
      permissions: map['permissions'] != null ? List<String>.from(map['permissions'] as List<dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, type: $type, permissions: $permissions)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.type == type &&
      listEquals(other.permissions, permissions);
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      type.hashCode ^
      permissions.hashCode;
  }
}
