// ignore_for_file: public_member_api_docs, sort_constructors_first

/// Model for a handyman user with profile.
class HandymanModel {
  final int id;
  final int? branchId;
  final String name;
  final String email;
  final String? phone;
  final String type;
  final String status;
  final String? avatar;
  final String? avatarUrl;
  final double? averageRating;
  final int? completedOrdersCount;
  final int? ratingsCount;
  final HandymanProfileModel? handymanProfile;

  const HandymanModel({
    required this.id,
    this.branchId,
    required this.name,
    required this.email,
    this.phone,
    required this.type,
    required this.status,
    this.avatar,
    this.avatarUrl,
    this.averageRating,
    this.completedOrdersCount,
    this.ratingsCount,
    this.handymanProfile,
  });

  factory HandymanModel.fromJson(Map<String, dynamic> json) {
    final profileRaw = json['handyman_profile'];
    HandymanProfileModel? profile;
    if (profileRaw is Map<String, dynamic>) {
      profile = HandymanProfileModel.fromJson(profileRaw);
    }

    return HandymanModel(
      id: json['id'] as int? ?? 0,
      branchId: json['branch_id'] as int?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      avatar: json['avatar'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      completedOrdersCount: json['completed_orders_count'] as int?,
      ratingsCount: json['ratings_count'] as int?,
      handymanProfile: profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'email': email,
      'phone': phone,
      'type': type,
      'status': status,
      'avatar': avatar,
      'avatar_url': avatarUrl,
      'average_rating': averageRating,
      'completed_orders_count': completedOrdersCount,
      'ratings_count': ratingsCount,
      'handyman_profile': handymanProfile?.toJson(),
    };
  }
}

/// Handyman profile with skills, rate, experience, etc.
class HandymanProfileModel {
  final int id;
  final int userId;
  final List<String> skills;
  final String serviceType;
  final String? hourlyRate;
  final int? experienceYears;
  final int? serviceRadius;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String? certifications;
  final String? tools;
  final String? availability;
  final String? bio;
  final bool isVerified;
  final bool isAvailable;

  const HandymanProfileModel({
    required this.id,
    required this.userId,
    this.skills = const [],
    required this.serviceType,
    this.hourlyRate,
    this.experienceYears,
    this.serviceRadius,
    this.address,
    this.latitude,
    this.longitude,
    this.certifications,
    this.tools,
    this.availability,
    this.bio,
    this.isVerified = false,
    this.isAvailable = true,
  });

  factory HandymanProfileModel.fromJson(Map<String, dynamic> json) {
    final skillsRaw = json['skills'];
    final skillsList = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return HandymanProfileModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      skills: skillsList,
      serviceType: json['service_type'] as String? ?? '',
      hourlyRate: json['hourly_rate']?.toString(),
      experienceYears: json['experience_years'] as int?,
      serviceRadius: json['service_radius'] as int?,
      address: json['address'] as String?,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      certifications: json['certifications'] as String?,
      tools: json['tools'] as String?,
      availability: json['availability'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] == true,
      isAvailable: json['is_available'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'skills': skills,
      'service_type': serviceType,
      'hourly_rate': hourlyRate,
      'experience_years': experienceYears,
      'service_radius': serviceRadius,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'certifications': certifications,
      'tools': tools,
      'availability': availability,
      'bio': bio,
      'is_verified': isVerified,
      'is_available': isAvailable,
    };
  }
}
