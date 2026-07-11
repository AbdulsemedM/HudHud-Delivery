import 'package:equatable/equatable.dart';

class VendorModel extends Equatable {
  final int id;

  /// Linked user account id (not used for vendor product APIs).
  final int? userId;
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

  // Optional display fields from vendors list API (shop/vendor profile)
  final String? description;
  final String? cuisineType;
  final String? openingTime;
  final String? closingTime;
  final String? bannerPath;

  // Getter for logo (using avatar as placeholder)
  String? get logo => avatar.isNotEmpty ? avatar : null;

  const VendorModel({
    required this.id,
    this.userId,
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
    this.description,
    this.cuisineType,
    this.openingTime,
    this.closingTime,
    this.bannerPath,
  });

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Parses user_id from vendor list item (top-level user_id/userId or nested user.id).
  /// Accepts any Map for nested user so parsed JSON from Dio works reliably.
  static int? _parseUserId(Map<String, dynamic> json) {
    if (json['user_id'] != null) return _parseInt(json['user_id']);
    if (json['userId'] != null) return _parseInt(json['userId']);
    final user = json['user'];
    if (user is Map) {
      final id = user['id'];
      if (id != null) return _parseInt(id);
    }
    return null;
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: _parseInt(json['id']),
      userId: json['user_id'] != null ? _parseInt(json['user_id']) : null,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.parse(json['phone_verified_at'])
          : null,
      type: json['type']?.toString() ?? 'vendor',
      status: json['status']?.toString() ?? 'active',
      avatar:
          json['avatar']?.toString() ?? json['avatar_url']?.toString() ?? '',
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
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Parses a vendor from the vendors list API (/api/vendors).
  /// Uses shop_name as name and logo_path / logo_urls as avatar.
  factory VendorModel.fromVendorListJson(Map<String, dynamic> json) {
    final logoPath = json['logo_path']?.toString();
    final logoUrls = json['logo_urls'];
    String avatar = logoPath ?? '';
    if (avatar.isEmpty && logoUrls is Map) {
      final urls = logoUrls as Map<String, dynamic>;
      avatar = urls['medium']?.toString() ??
          urls['small']?.toString() ??
          urls['thumb']?.toString() ??
          urls['original']?.toString() ??
          '';
    }
    final bannerPath = json['banner_path']?.toString();
    final bannerUrls = json['banner_urls'];
    String? banner = bannerPath?.isNotEmpty == true ? bannerPath : null;
    if (banner == null && bannerUrls is Map) {
      final urls = bannerUrls as Map<String, dynamic>;
      banner = urls['medium']?.toString() ??
          urls['small']?.toString() ??
          urls['thumb']?.toString();
    }
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now();
    final updatedAt = DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
        DateTime.now();
    return VendorModel(
      id: _parseInt(json['id']),
      userId: _parseUserId(json),
      name: json['shop_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['contact_email']?.toString() ?? '',
      phone: json['contact_phone']?.toString() ?? '',
      emailVerifiedAt: null,
      phoneVerifiedAt: null,
      type: 'vendor',
      status: json['status']?.toString() ?? 'active',
      avatar: avatar,
      deviceToken: null,
      emailVerificationCode: null,
      phoneVerificationCode: null,
      lastLoginAt: null,
      lastLoginIp: null,
      dateOfBirth: null,
      gender: null,
      socialType: null,
      language: 'en',
      timezone: 'UTC',
      referralCode: '',
      deletedAt: null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: json['description']?.toString(),
      cuisineType: json['cuisine_type']?.toString(),
      openingTime: _formatTime(json['opening_time']?.toString()),
      closingTime: _formatTime(json['closing_time']?.toString()),
      bannerPath: banner,
    );
  }

  static String? _formatTime(String? time) {
    if (time == null || time.isEmpty) return null;
    // "07:00:00" -> "7:00 AM"
    final parts = time.split(':');
    if (parts.isEmpty) return time;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (h == 0 && m == 0 && time == '00:00:00') return 'Midnight';
    if (h == 12) return '${h}:${m.toString().padLeft(2, '0')} PM';
    if (h > 12) return '${h - 12}:${m.toString().padLeft(2, '0')} PM';
    return '${h == 0 ? 12 : h}:${m.toString().padLeft(2, '0')} AM';
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
        userId,
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
        description,
        cuisineType,
        openingTime,
        closingTime,
        bannerPath,
      ];
}
