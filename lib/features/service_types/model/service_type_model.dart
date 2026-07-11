// ignore_for_file: public_member_api_docs, sort_constructors_first

/// Model for a service type from /api/service-types.
class ServiceTypeModel {
  final int id;
  final String name;
  final String code;
  final String? description;
  final String category;
  final String? icon;
  final bool isActive;
  final String position;
  final String commissionRate;
  final Map<String, dynamic>? config;
  final List<String> requirements;
  final String pricingModel;
  final List<String>? supportedVehicleTypes;
  final String? createdAt;
  final String? updatedAt;
  final String? iconUrl;
  final List<dynamic> media;

  const ServiceTypeModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.category,
    this.icon,
    this.isActive = true,
    this.position = '0',
    this.commissionRate = '0',
    this.config,
    this.requirements = const [],
    this.pricingModel = '',
    this.supportedVehicleTypes,
    this.createdAt,
    this.updatedAt,
    this.iconUrl,
    this.media = const [],
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    final requirementsRaw = json['requirements'];
    final requirementsList = requirementsRaw is List
        ? requirementsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final vehicleTypesRaw = json['supported_vehicle_types'];
    final vehicleTypesList = vehicleTypesRaw is List
        ? vehicleTypesRaw.map((e) => e.toString()).toList()
        : null;

    final configRaw = json['config'];
    final configMap =
        configRaw is Map ? Map<String, dynamic>.from(configRaw) : null;

    final mediaRaw = json['media'];
    final mediaList = mediaRaw is List ? mediaRaw : <dynamic>[];

    return ServiceTypeModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? '',
      icon: json['icon'] as String?,
      isActive: json['is_active'] == true,
      position: json['position']?.toString() ?? '0',
      commissionRate: json['commission_rate']?.toString() ?? '0',
      config: configMap,
      requirements: requirementsList,
      pricingModel: json['pricing_model'] as String? ?? '',
      supportedVehicleTypes: vehicleTypesList,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      iconUrl: json['icon_url'] as String?,
      media: mediaList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'category': category,
      'icon': icon,
      'is_active': isActive,
      'position': position,
      'commission_rate': commissionRate,
      'config': config,
      'requirements': requirements,
      'pricing_model': pricingModel,
      'supported_vehicle_types': supportedVehicleTypes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'icon_url': iconUrl,
      'media': media,
    };
  }
}
