/// Lenient JSON readers shared by the Phase 2 growth models.
///
/// The backend returns money as JSON numbers, but older endpoints sometimes
/// send numeric strings — accept both and never throw on bad input.
double growthDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? fallback;
}

double? growthDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

int growthInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final s = value.toString().trim();
  return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? fallback;
}

int? growthIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final s = value.toString().trim();
  return int.tryParse(s) ?? double.tryParse(s)?.toInt();
}

bool growthBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

String? growthString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic>? growthMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> growthList(dynamic value) {
  if (value is List) return value;
  return const [];
}

/// Unwraps the standard `{success, data}` envelope. Returns `null` when the
/// payload is not a successful envelope with a map `data`.
Map<String, dynamic>? growthEnvelopeData(dynamic body) {
  final root = growthMap(body);
  if (root == null) return null;
  if (root.containsKey('success') && root['success'] != true) return null;
  return growthMap(root['data']);
}

/// Unwraps a `{success, data: [...]}` envelope whose `data` is a list.
/// Also accepts `data: {items|markets: [...]}`. Returns `null` when the
/// payload is not a successful envelope with list data.
List<dynamic>? growthEnvelopeList(dynamic body, {String key = 'items'}) {
  final root = growthMap(body);
  if (root == null) return null;
  if (root.containsKey('success') && root['success'] != true) return null;
  final data = root['data'];
  if (data is List) return data;
  final map = growthMap(data);
  if (map == null) return null;
  final nested = map[key];
  if (nested is List) return nested;
  return null;
}

/// Reads an ISO-8601 timestamp; `null` when absent or unparseable.
DateTime? growthDateTime(dynamic value) {
  final s = growthString(value);
  if (s == null) return null;
  return DateTime.tryParse(s);
}
