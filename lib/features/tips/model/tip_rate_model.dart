class TipRateModel {
  final int id;
  final String name;
  final String type;
  final String value;
  final bool isDefault;
  final int displayOrder;
  final bool isActive;

  const TipRateModel({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.isDefault = false,
    this.displayOrder = 0,
    this.isActive = true,
  });

  bool get isCustom =>
      name.toLowerCase() == 'custom' ||
      (type == 'fixed' && value == '0.00' && !isDefault);

  bool get isNoTip =>
      name.toLowerCase() == 'no tip' ||
      (type == 'fixed' && value == '0.00' && isDefault);

  factory TipRateModel.fromJson(Map<String, dynamic> json) {
    return TipRateModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'fixed',
      value: json['value']?.toString() ?? '0.00',
      isDefault: json['is_default'] == true,
      displayOrder: _parseInt(json['display_order']) ?? 0,
      isActive: json['is_active'] != false,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
