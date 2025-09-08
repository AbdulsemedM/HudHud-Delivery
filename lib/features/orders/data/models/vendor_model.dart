import 'package:equatable/equatable.dart';

class VendorModel extends Equatable {
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

  // Getter for logo (using avatar as placeholder)
  String? get logo => avatar.isNotEmpty ? avatar : null;

  const VendorModel({
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

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.parse(json['email_verified_at']) 
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null 
          ? DateTime.parse(json['phone_verified_at']) 
          : null,
      type: json['type'],
      status: json['status'],
      avatar: json['avatar'],
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
      language: json['language'],
      timezone: json['timezone'],
      referralCode: json['referral_code'],
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isPhoneVerified => phoneVerifiedAt != null;

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