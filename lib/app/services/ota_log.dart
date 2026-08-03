import 'package:flutter/foundation.dart';

/// Structured OTA lifecycle logging (check → download → apply/failure).
///
/// Uses tagged console output today. Swap the sink for Crashlytics breadcrumbs
/// when `firebase_crashlytics` is added to the project.
class OtaLog {
  OtaLog._();

  static const String _tag = 'OTA';

  static void info(String event, [Map<String, Object?>? data]) {
    _emit('INFO', event, data);
  }

  static void warn(String event, [Map<String, Object?>? data]) {
    _emit('WARN', event, data);
  }

  static void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    final payload = <String, Object?>{
      ...?data,
      if (error != null) 'error': error.toString(),
    };
    _emit('ERROR', event, payload);
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }

  static void _emit(String level, String event, Map<String, Object?>? data) {
    final suffix = (data == null || data.isEmpty)
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    // Always log: patch issues must be observable in release builds too.
    debugPrint('[$_tag][$level] $event$suffix');
  }
}
