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
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.type,
    this.permissions,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
  });

  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isPhoneVerified => phoneVerifiedAt != null;

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? type,
    List<dynamic>? permissions,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      permissions: permissions ?? this.permissions,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
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
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
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
      emailVerifiedAt: map['email_verified_at'] != null
          ? DateTime.tryParse(map['email_verified_at'] as String)
          : null,
      phoneVerifiedAt: map['phone_verified_at'] != null
          ? DateTime.tryParse(map['phone_verified_at'] as String)
          : null,
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

    return other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.type == type &&
        listEquals(other.permissions, permissions) &&
        other.emailVerifiedAt == emailVerifiedAt &&
        other.phoneVerifiedAt == phoneVerifiedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        type.hashCode ^
        permissions.hashCode ^
        emailVerifiedAt.hashCode ^
        phoneVerifiedAt.hashCode;
  }
}
