/// Configured city service area from GET /api/services/delivery/service-areas.
class DeliveryServiceArea {
  const DeliveryServiceArea({
    this.id,
    this.name,
    this.enabled = false,
    this.cityAliases = const [],
    this.supportedVehicleTypes = const [],
  });

  final String? id;
  final String? name;
  final bool enabled;
  final List<String> cityAliases;
  final List<String> supportedVehicleTypes;
}

/// Lookup result for a pickup address. Use [supportedVehicleTypes] for the selector.
/// [areas] is only present when pickup_location is omitted; never use it to override
/// the configured result for a selected pickup.
class DeliveryServiceAreaLookup {
  const DeliveryServiceAreaLookup({
    this.pickupLocation,
    this.serviceArea,
    this.supportedVehicleTypes = const [],
    this.areas = const [],
  });

  final String? pickupLocation;
  final DeliveryServiceArea? serviceArea;
  final List<String> supportedVehicleTypes;
  final List<DeliveryServiceArea> areas;
}

DeliveryServiceAreaLookup parseDeliveryServiceAreaLookup(dynamic rawData) {
  final root = _asMap(rawData);
  if (root.isEmpty) {
    return const DeliveryServiceAreaLookup();
  }

  final data = _asMap(root['data']).isNotEmpty ? _asMap(root['data']) : root;
  final nestedArea = parseDeliveryServiceArea(data['service_area']);
  final topLevelTypes = _stringList(data['supported_vehicle_types']);
  final nestedTypes = nestedArea?.supportedVehicleTypes ?? const [];
  var types = topLevelTypes.isNotEmpty ? topLevelTypes : nestedTypes;
  if (nestedArea != null && !nestedArea.enabled) {
    types = const [];
  }

  return DeliveryServiceAreaLookup(
    pickupLocation: _nonEmpty(data['pickup_location']),
    serviceArea: nestedArea,
    supportedVehicleTypes: types,
    areas: _parseAreas(data['areas']),
  );
}

DeliveryServiceArea? parseDeliveryServiceArea(dynamic value) {
  final map = _asMap(value);
  if (map.isEmpty) return null;
  return DeliveryServiceArea(
    id: _nonEmpty(map['id']),
    name: _nonEmpty(map['name']),
    enabled: map['enabled'] != false,
    cityAliases: _stringList(map['city_aliases']),
    supportedVehicleTypes: _stringList(map['supported_vehicle_types']),
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<DeliveryServiceArea> _parseAreas(dynamic value) {
  if (value is! List) return const [];
  final areas = <DeliveryServiceArea>[];
  for (final item in value) {
    final parsed = parseDeliveryServiceArea(item);
    if (parsed != null) areas.add(parsed);
  }
  return areas;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

String? _nonEmpty(dynamic value) {
  final s = value?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s;
}
