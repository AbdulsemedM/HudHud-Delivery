/// Extracts a user-facing message from Laravel-style API error payloads.
String extractApiErrorMessage(
  dynamic data, {
  String fallback = 'An error occurred',
}) {
  if (data is! Map) return fallback;

  final map = Map<String, dynamic>.from(data);

  final validation = _firstValidationError(map['errors']);
  if (validation != null && validation.isNotEmpty) {
    return validation;
  }

  final message = map['message'];
  if (message is Map) {
    final nested = _firstValidationError(message);
    if (nested != null && nested.isNotEmpty) {
      return nested;
    }
  }

  if (message is String && message.isNotEmpty) {
    return message;
  }

  return fallback;
}

String? _firstValidationError(dynamic errors) {
  if (errors is! Map) return null;

  for (final value in errors.values) {
    if (value is List && value.isNotEmpty) {
      final first = value.first?.toString();
      if (first != null && first.isNotEmpty) return first;
    } else if (value != null) {
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
  }
  return null;
}
