class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profileImage;
  final String role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profileImage,
    this.role = 'customer',
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
    this.metadata,
  });

  // Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      profileImage: json['profile_image']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      isEmailVerified: json['is_email_verified'] ?? false,
      isPhoneVerified: json['is_phone_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      preferences: json['preferences'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_image': profileImage,
      'role': role,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferences': preferences,
      'metadata': metadata,
    };
  }

  // Copy with method for updating user data
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? profileImage,
    String? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get display name (name or email if name is empty)
  String get displayName {
    return name.isNotEmpty ? name : email;
  }

  // Get initials for avatar
  String get initials {
    if (name.isNotEmpty) {
      final nameParts = name.trim().split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        return name[0].toUpperCase();
      }
    } else if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  // Check if user has a specific role
  bool hasRole(String roleToCheck) {
    return role.toLowerCase() == roleToCheck.toLowerCase();
  }

  // Check if user is admin
  bool get isAdmin => hasRole('admin');

  // Check if user is customer
  bool get isCustomer => hasRole('customer');

  // Check if user is delivery person
  bool get isDeliveryPerson => hasRole('delivery');

  // Check if user is restaurant owner
  bool get isRestaurantOwner => hasRole('restaurant');

  // Get user preference
  T? getPreference<T>(String key, [T? defaultValue]) {
    if (preferences == null) return defaultValue;
    return preferences![key] as T? ?? defaultValue;
  }

  // Get user metadata
  T? getMetadata<T>(String key, [T? defaultValue]) {
    if (metadata == null) return defaultValue;
    return metadata![key] as T? ?? defaultValue;
  }

  // Check if profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty;
  }

  // Get verification status
  String get verificationStatus {
    if (isEmailVerified && isPhoneVerified) {
      return 'Fully Verified';
    } else if (isEmailVerified) {
      return 'Email Verified';
    } else if (isPhoneVerified) {
      return 'Phone Verified';
    } else {
      return 'Not Verified';
    }
  }

  // Check if user needs verification
  bool get needsVerification {
    return !isEmailVerified || !isPhoneVerified;
  }

  // Get formatted phone number
  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return '';
    
    // Simple formatting - you can enhance this based on your needs
    final cleanPhone = phone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length >= 10) {
      return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    }
    return phone!;
  }

  // Get user age if birthdate is stored in metadata
  int? get age {
    final birthdate = getMetadata<String>('birthdate');
    if (birthdate != null) {
      try {
        final birth = DateTime.parse(birthdate);
        final now = DateTime.now();
        int age = now.year - birth.year;
        if (now.month < birth.month || 
            (now.month == birth.month && now.day < birth.day)) {
          age--;
        }
        return age;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}