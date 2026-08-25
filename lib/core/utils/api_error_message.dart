import 'api_error_result.dart';

export 'api_error_result.dart' show ApiErrorResult, parseApiErrorResult;

/// Extracts a user-facing message from Laravel-style API error payloads.
String extractApiErrorMessage(
  dynamic data, {
  String fallback = 'An error occurred',
  int? statusCode,
}) {
  return parseApiErrorResult(
    data,
    statusCode: statusCode,
    fallback: fallback,
  ).displayMessage;
}
