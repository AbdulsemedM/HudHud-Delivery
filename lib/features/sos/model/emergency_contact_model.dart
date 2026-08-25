class EmergencyContactModel {
  final int id;
  final int? userId;
  final String name;
  final String phone;
  final String? email;
  final String? relationship;
  final bool isPrimary;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmergencyContactModel({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
    this.isPrimary = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      relationship: json['relationship']?.toString(),
      isPrimary: json['is_primary'] == true,
      isActive: json['is_active'] != false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        'name': name,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (relationship != null && relationship!.isNotEmpty)
          'relationship': relationship,
        'is_primary': isPrimary,
        'is_active': isActive,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  Map<String, dynamic> toCreateBody() => {
        'name': name,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (relationship != null && relationship!.isNotEmpty)
          'relationship': relationship,
        'is_primary': isPrimary,
      };

  Map<String, dynamic> toUpdateBody() => {
        'name': name,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (relationship != null && relationship!.isNotEmpty)
          'relationship': relationship,
        'is_primary': isPrimary,
        'is_active': isActive,
      };

  EmergencyContactModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    bool? isPrimary,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
