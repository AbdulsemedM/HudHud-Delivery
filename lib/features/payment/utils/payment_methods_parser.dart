/// Parses payment method items from GET /api/payment-methods or /payments/methods.
List<Map<String, dynamic>> parsePaymentMethodsList(dynamic list) {
  if (list == null || list is! List) {
    return [];
  }

  final List<Map<String, dynamic>> methods = [];
  for (final item in list) {
    if (item is! Map) continue;

    final map = Map<String, dynamic>.from(item);
    final code = map['code']?.toString() ?? map['id']?.toString();
    final name = map['name']?.toString() ?? code ?? 'Unknown';
    final description = map['description']?.toString() ?? 'Pay with $name';
    final sortOrder =
        int.tryParse(map['sort_order']?.toString() ?? '0') ?? 0;

    // Legacy /payment-methods uses is_active; registry uses can_use.
    final canUse = map['can_use'];
    final isActive = map['is_active'] == true;
    final enabled = canUse != null ? canUse == true : isActive;

    if (code != null && code.isNotEmpty) {
      methods.add({
        'id': code,
        'name': name,
        'description': description,
        'icon': map['icon'],
        'enabled': enabled,
        'can_use': canUse,
        'availability_code': map['availability_code']?.toString(),
        'requires_qr': map['requires_qr'] == true,
        'supports_qr_payment': map['supports_qr_payment'] == true,
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
