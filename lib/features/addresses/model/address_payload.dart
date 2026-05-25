import 'address_model.dart';

class AddressPayload {
  /// Default postal code when the user does not enter one (Ethiopia app).
  static const defaultPostalCode = '1000';

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
  final bool autoGeocode;

  const AddressPayload({
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.addressType = 'home',
    this.label,
    this.landmark,
    this.isDefault = false,
    this.autoGeocode = false,
  });

  Map<String, dynamic> toJson({bool forCreate = false}) {
    final map = <String, dynamic>{
      'address_line_1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'address_line_2': addressLine2,
      'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      'postal_code': (postalCode != null && postalCode!.isNotEmpty)
          ? postalCode
          : defaultPostalCode,
      'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'address_type': addressType,
      if (label != null && label!.isNotEmpty) 'label': label,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      'is_default': isDefault,
    };
    if (forCreate && autoGeocode) {
      map['auto_geocode'] = true;
    }
    return map;
  }

  factory AddressPayload.fromModel(
    AddressModel model, {
    bool? isDefault,
    bool autoGeocode = false,
  }) {
    return AddressPayload(
      addressLine1: model.addressLine1,
      addressLine2: model.addressLine2,
      city: model.city,
      state: model.state,
      postalCode: model.postalCode,
      country: model.country,
      latitude: model.latitude,
      longitude: model.longitude,
      addressType: model.addressType,
      label: model.label,
      landmark: model.landmark,
      isDefault: isDefault ?? model.isDefault,
      autoGeocode: autoGeocode,
    );
  }
}
