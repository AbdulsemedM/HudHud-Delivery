class AddressModel {
  final int id;
  final int? userId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String addressType;
  final String? label;
  final String? landmark;
  final bool isDefault;
  final String? fullAddress;
  final String? formattedAddress;
  final String? displayLabel;
  final String? createdAt;
  final String? updatedAt;

  const AddressModel({
    required this.id,
    this.userId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    required this.addressType,
    this.label,
    this.landmark,
    required this.isDefault,
    this.fullAddress,
    this.formattedAddress,
    this.displayLabel,
    this.createdAt,
    this.updatedAt,
  });

  String get displayText =>
      formattedAddress ??
      fullAddress ??
      [addressLine1, addressLine2, city, state, postalCode, country]
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .join(', ');

  String get title => displayLabel ?? label ?? addressType;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']),
      addressLine1: json['address_line_1']?.toString() ?? '',
      addressLine2: json['address_line_2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      postalCode: json['postal_code']?.toString(),
      country: json['country']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      addressType: json['address_type']?.toString() ?? 'other',
      label: json['label']?.toString(),
      landmark: json['landmark']?.toString(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      fullAddress: json['full_address']?.toString(),
      formattedAddress: json['formatted_address']?.toString(),
      displayLabel: json['display_label']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  AddressModel copyWith({
    int? id,
    bool? isDefault,
    String? label,
    String? addressLine1,
    String? city,
    String? formattedAddress,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2,
      city: city ?? this.city,
      state: state,
      postalCode: postalCode,
      country: country,
      latitude: latitude,
      longitude: longitude,
      addressType: addressType,
      label: label ?? this.label,
      landmark: landmark,
      isDefault: isDefault ?? this.isDefault,
      fullAddress: fullAddress,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      displayLabel: displayLabel,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class AddressesListMeta {
  final int total;
  final int? defaultAddressId;
  final Map<String, int> addressesByType;

  const AddressesListMeta({
    required this.total,
    this.defaultAddressId,
    this.addressesByType = const {},
  });

  factory AddressesListMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AddressesListMeta(total: 0);
    }
    final byTypeRaw = json['addresses_by_type'];
    final byType = <String, int>{};
    if (byTypeRaw is Map) {
      byTypeRaw.forEach((key, value) {
        if (value is int) {
          byType[key.toString()] = value;
        } else {
          byType[key.toString()] = int.tryParse(value.toString()) ?? 0;
        }
      });
    }
    return AddressesListMeta(
      total: AddressModel._parseInt(json['total']) ?? 0,
      defaultAddressId: AddressModel._parseInt(json['default_address_id']),
      addressesByType: byType,
    );
  }
}
