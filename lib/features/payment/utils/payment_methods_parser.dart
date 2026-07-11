/// Parses payment method items from GET /api/payment-methods `data` array.
List<Map<String, dynamic>> parsePaymentMethodsList(dynamic list) {
  if (list == null || list is! List) {
    return [];
  }

  final List<Map<String, dynamic>> methods = [];
  for (final item in list) {
    if (item is! Map) continue;

    final map = Map<String, dynamic>.from(item);
    final isActive = map['is_active'] == true;
    final code = map['code']?.toString();
    final name = map['name']?.toString() ?? code ?? 'Unknown';
    final description = map['description']?.toString() ?? 'Pay with $name';
    final sortOrder =
        int.tryParse(map['sort_order']?.toString() ?? '0') ?? 0;

    if (code != null && code.isNotEmpty) {
      methods.add({
        'id': code,
        'name': name,
        'description': description,
        'icon': map['icon'],
        'enabled': isActive,
        '_sortOrder': sortOrder,
      });
    }
  }

  methods.sort(
    (a, b) => (a['_sortOrder'] as int).compareTo(b['_sortOrder'] as int),
  );
  for (final m in methods) {
    m.remove('_sortOrder');
  }

  return methods;
}
