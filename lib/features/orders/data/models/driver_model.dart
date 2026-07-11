import 'package:equatable/equatable.dart';

class DriverModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String phone;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final String type;
  final String status;
  final String avatar;
  final String? deviceToken;
  final String? emailVerificationCode;
  final String? phoneVerificationCode;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? socialType;
  final String language;
  final String timezone;
  final String referralCode;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.type,
    required this.status,
    required this.avatar,
    this.deviceToken,
    this.emailVerificationCode,
    this.phoneVerificationCode,
    this.lastLoginAt,
    this.lastLoginIp,
    this.dateOfBirth,
    this.gender,
    this.socialType,
    required this.language,
    required this.timezone,
    required this.referralCode,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.parse(json['email_verified_at']) 
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null 
          ? DateTime.parse(json['phone_verified_at']) 
          : null,
      type: json['type']?.toString() ?? 'driver',
      status: json['status']?.toString() ?? 'active',
      avatar: json['avatar']?.toString() ?? json['avatar_url']?.toString() ?? '',
      deviceToken: json['device_token'],
      emailVerificationCode: json['email_verification_code'],
      phoneVerificationCode: json['phone_verification_code'],
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
      lastLoginIp: json['last_login_ip'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      gender: json['gender'],
      socialType: json['social_type'],
      language: json['language']?.toString() ?? 'en',
      timezone: json['timezone']?.toString() ?? 'UTC',
      referralCode: json['referral_code']?.toString() ?? '',
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'type': type,
      'status': status,
      'avatar': avatar,
      'device_token': deviceToken,
      'email_verification_code': emailVerificationCode,
      'phone_verification_code': phoneVerificationCode,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'last_login_ip': lastLoginIp,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'social_type': socialType,
      'language': language,
      'timezone': timezone,
      'referral_code': referralCode,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isActive => status == 'active';
  bool get isAvailable => status == 'available';
  bool get isOnline => status == 'online';
  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isPhoneVerified => phoneVerifiedAt != null;
  String get displayName => name.isNotEmpty ? name : email;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        emailVerifiedAt,
        phoneVerifiedAt,
        type,
        status,
        avatar,
        deviceToken,
        emailVerificationCode,
        phoneVerificationCode,
        lastLoginAt,
        lastLoginIp,
        dateOfBirth,
        gender,
        socialType,
        language,
        timezone,
        referralCode,
        deletedAt,
        createdAt,
        updatedAt,
      ];
}