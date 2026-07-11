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
  final DateTime? dateOfBirth;
  final String? avatar;
  final String? avatarUrl;
  final String? referralCode;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.type,
    this.permissions,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.dateOfBirth,
    this.avatar,
    this.avatarUrl,
    this.referralCode,
  });

  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isPhoneVerified => phoneVerifiedAt != null;

  /// Check if user has a specific permission (from login response)
  bool hasPermission(String permission) =>
      permissions?.contains(permission) ?? false;

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? type,
    List<dynamic>? permissions,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? dateOfBirth,
    String? avatar,
    String? avatarUrl,
    String? referralCode,
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
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatar: avatar ?? this.avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      referralCode: referralCode ?? this.referralCode,
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
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'avatar': avatar,
      'avatar_url': avatarUrl,
      'referral_code': referralCode,
    };
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Extracts user fields from API envelopes like `{ success, data, avatar_url }`.
  static Map<String, dynamic>? userMapFromApiEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final dynamic payload = envelope['data'] ?? envelope['user'];
    if (payload is! Map) return null;

    final userMap = Map<String, dynamic>.from(payload);

    final avatarUrl = envelope['avatar_url']?.toString();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      userMap['avatar_url'] = avatarUrl;
    }
    final avatarThumb = envelope['avatar_thumb_url']?.toString();
    if (avatarThumb != null && avatarThumb.isNotEmpty) {
      userMap['avatar_thumb_url'] = avatarThumb;
    }

    return userMap;
  }

  static String? _parseAvatarUrl(Map<String, dynamic> map) {
    final direct = map['avatar_url']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final thumb = map['avatar_thumb_url']?.toString();
    if (thumb != null && thumb.isNotEmpty) return thumb;

    final avatarUrls = map['avatar_urls'];
    if (avatarUrls is Map) {
      final urls = Map<String, dynamic>.from(avatarUrls);
      return urls['medium']?.toString() ??
          urls['thumb']?.toString() ??
          urls['small']?.toString() ??
          urls['original']?.toString();
    }

    final avatar = map['avatar']?.toString();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  static String? _parseAvatarPath(Map<String, dynamic> map) {
    final avatar = map['avatar']?.toString();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: _parseInt(map['id']),
      name: map['name']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      type: map['type']?.toString(),
      permissions: map['permissions'] is List
          ? List<dynamic>.from(map['permissions'] as List)
          : null,
      emailVerifiedAt: _parseDateTime(map['email_verified_at']),
      phoneVerifiedAt: _parseDateTime(map['phone_verified_at']),
      dateOfBirth: _parseDateTime(map['date_of_birth']),
      avatar: _parseAvatarPath(map),
      avatarUrl: _parseAvatarUrl(map),
      referralCode: map['referral_code']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

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
        other.phoneVerifiedAt == phoneVerifiedAt &&
        other.dateOfBirth == dateOfBirth &&
        other.avatar == avatar &&
        other.avatarUrl == avatarUrl &&
        other.referralCode == referralCode;
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
        phoneVerifiedAt.hashCode ^
        dateOfBirth.hashCode ^
        avatar.hashCode ^
        avatarUrl.hashCode ^
        referralCode.hashCode;
  }
}
