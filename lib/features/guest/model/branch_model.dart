class BranchModel {
  final int id;
  final String name;
  final int? vendorId;
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;
  final Map<String, dynamic>? operatingHours;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? timezone;
  final double? distance;

  const BranchModel({
    required this.id,
    required this.name,
    this.vendorId,
    this.address,
    this.phone,
    this.email,
    this.isActive = true,
    this.operatingHours,
    this.locationLatitude,
    this.locationLongitude,
    this.timezone,
    this.distance,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      vendorId: _parseInt(json['vendor_id']),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      isActive: json['is_active'] == true,
      operatingHours: json['operating_hours'] is Map
          ? Map<String, dynamic>.from(json['operating_hours'] as Map)
          : null,
      locationLatitude: _parseDouble(json['location_latitude']),
      locationLongitude: _parseDouble(json['location_longitude']),
      timezone: json['timezone']?.toString(),
      distance: _parseDouble(json['distance']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
