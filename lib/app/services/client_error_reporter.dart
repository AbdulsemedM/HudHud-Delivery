import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api/api_constants.dart';
import 'auth_service.dart';

/// Static per-install fields of a report (version, platform, device).
class ClientErrorMetadata {
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String? deviceModel;
  final String? deviceId;

  const ClientErrorMetadata({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    this.deviceModel,
    this.deviceId,
  });

  /// Best-effort; never throws. Version comes from package_info_plus (the
  /// same source Settings uses); device id is the one sent with the FCM
  /// token registration (Android ID / iOS identifierForVendor).
  static Future<ClientErrorMetadata> collect() async {
    var appVersion = '';
    var buildNumber = '';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {}

    var platform = 'unknown';
    var osVersion = '';
    try {
      platform = Platform.isAndroid
          ? 'android'
          : (Platform.isIOS ? 'ios' : Platform.operatingSystem);
      osVersion = Platform.operatingSystemVersion;
    } catch (_) {}

    String? deviceModel;
    String? deviceId;
    try {
      final plugin = DeviceInfoPlugin();
      if (platform == 'android') {
        final a = await plugin.androidInfo;
        deviceModel = '${a.manufacturer} ${a.model}'.trim();
        deviceId = a.id;
      } else if (platform == 'ios') {
        final i = await plugin.iosInfo;
        deviceModel = i.utsname.machine;
        deviceId = i.identifierForVendor;
      }
    } catch (_) {}

    return ClientErrorMetadata(
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: platform,
      osVersion: osVersion,
      deviceModel: (deviceModel == null || deviceModel.isEmpty) ? null : deviceModel,
      deviceId: (deviceId == null || deviceId.isEmpty) ? null : deviceId,
    );
  }
}

/// One queued report (the JSON shape of `POST /api/client-errors`).
class ClientErrorReport {
  final String errorType;
  final String message;
  final String stack;
  final bool fatal;
  final String? screen;
  final String? route;
  final String? locale;
  final DateTime occurredAt;

  const ClientErrorReport({
    required this.errorType,
    required this.message,
    required this.stack,
    required this.fatal,
    this.screen,
    this.route,
    this.locale,
    required this.occurredAt,
  });

  static const int maxMessageLength = 2000;
  static const int maxStackLength = 8000;

  /// Builds a report from a caught error; trims oversized text.
  factory ClientErrorReport.from(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? screen,
    String? route,
    String? locale,
    required DateTime occurredAt,
  }) {
    var message = '';
    try {
      message = error.toString();
    } catch (_) {
      message = '<unprintable error>';
    }
    return ClientErrorReport(
      errorType: error.runtimeType.toString(),
      message: _clip(message, maxMessageLength),
      stack: _clip(stack?.toString() ?? '', maxStackLength),
      fatal: fatal,
      screen: screen,
      route: route,
      locale: locale,
      occurredAt: occurredAt.toUtc(),
    );
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  /// Rate-limit / de-dup key: same error at the same place.
  String get fingerprint {
    final firstFrame = stack.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    final head = message.length > 200 ? message.substring(0, 200) : message;
    return '$errorType|$head|$firstFrame';
  }

  Map<String, dynamic> toJson(ClientErrorMetadata meta) => {
        'app': 'customer',
        'app_version': meta.appVersion,
        'build_number': meta.buildNumber,
        'platform': meta.platform,
        'os_version': meta.osVersion,
        if (meta.deviceModel != null) 'device_model': meta.deviceModel,
        'error_type': errorType,
        'message': message,
        'stack': stack,
        'fatal': fatal,
        'context': {
          'screen': screen,
          'route': route,
          'locale': locale,
        },
        'occurred_at': occurredAt.toIso8601String(),
        if (meta.deviceId != null) 'device_id': meta.deviceId,
      };
}

/// Sends the body; returns the HTTP status (null on network failure).
typedef ClientErrorSender = Future<int?> Function(Map<String, dynamic> body);

/// Error / crash reporting to OUR backend (`POST /api/client-errors`), no
/// Firebase Crashlytics.
///
/// - In-memory queue, flushed in batches of up to [maxBatch]
///   (`{"reports": [...]}`; a single report is sent unwrapped).
/// - Local rate limit: at most [maxPerMinute] reports accepted per minute,
///   identical errors once per minute.
/// - A failed batch is retried [maxAttempts] − 1 more times, then dropped.
/// - Never throws, never blocks the UI, never reports its own failures.
/// - Off in debug builds unless built with
///   `--dart-define=REPORT_ERRORS_IN_DEBUG=true`.
class ClientErrorReporter {
  ClientErrorReporter({
    ClientErrorSender? sender,
    Future<ClientErrorMetadata> Function()? metadata,
    DateTime Function()? clock,
    bool? enabled,
    this.flushDelay = const Duration(seconds: 5),
    this.retryDelay = const Duration(seconds: 15),
  })  : _sender = sender,
        _metadataLoader = metadata ?? ClientErrorMetadata.collect,
        _clock = clock ?? DateTime.now,
        enabled = enabled ?? (!kDebugMode || reportInDebug);

  static final ClientErrorReporter instance = ClientErrorReporter();

  static const bool reportInDebug =
      bool.fromEnvironment('REPORT_ERRORS_IN_DEBUG', defaultValue: false);

  static const int maxBatch = 20;
  static const int maxPerMinute = 20;
  static const int maxQueue = 60;
  static const int maxAttempts = 3;

  final bool enabled;
  final Duration flushDelay;
  final Duration retryDelay;
  final ClientErrorSender? _sender;
  final Future<ClientErrorMetadata> Function() _metadataLoader;
  final DateTime Function() _clock;

  /// Current locale code (set from main with the LocaleController).
  String? Function()? localeProvider;

  /// Last route seen by [ClientErrorRouteObserver].
  String? currentRoute;

  /// Optional screen name a screen may set for richer context.
  String? currentScreen;

  final List<ClientErrorReport> _queue = [];
  final List<DateTime> _accepted = [];
  final Map<String, DateTime> _recentFingerprints = {};
  Future<ClientErrorMetadata>? _metadata;
  Timer? _timer;
  bool _flushing = false;
  bool _endpointMissing = false;
  int _attempt = 0;
  bool _installed = false;
  Dio? _dio;

  /// Visible for tests.
  int get queuedCount => _queue.length;

  /// Hooks Flutter framework errors and uncaught platform/async errors.
  /// Keeps the previous handlers (debug console output is unchanged).
  void install() {
    if (_installed) return;
    _installed = true;
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      try {
        if (previousFlutterHandler != null) {
          previousFlutterHandler(details);
        } else {
          FlutterError.presentError(details);
        }
      } catch (_) {}
      if (details.silent) return;
      record(details.exception, details.stack, fatal: false);
    };
    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('Uncaught error: $error');
        debugPrint('$stack');
      }
      record(error, stack, fatal: true);
      try {
        if (previousPlatformHandler != null) {
          return previousPlatformHandler(error, stack);
        }
      } catch (_) {}
      return true;
    };
  }

  /// Queues a report. Safe to call from anywhere; never throws.
  void record(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? screen,
  }) {
    if (!enabled || _endpointMissing) return;
    try {
      final now = _clock();
      _accepted.removeWhere((t) => now.difference(t) >= const Duration(minutes: 1));
      _recentFingerprints
          .removeWhere((_, t) => now.difference(t) >= const Duration(minutes: 1));
      if (_accepted.length >= maxPerMinute) return;

      String? locale;
      try {
        locale = localeProvider?.call();
      } catch (_) {}
      final report = ClientErrorReport.from(
        error,
        stack,
        fatal: fatal,
        screen: screen ?? currentScreen,
        route: currentRoute,
        locale: locale,
        occurredAt: now,
      );
      final key = report.fingerprint;
      if (_recentFingerprints.containsKey(key)) return;
      _recentFingerprints[key] = now;
      _accepted.add(now);

      if (_queue.length >= maxQueue) _queue.removeAt(0);
      _queue.add(report);
      _schedule(fatal ? const Duration(milliseconds: 500) : flushDelay);
    } catch (_) {
      // Reporting must never cause another error.
    }
  }

  void _schedule(Duration delay) {
    if (_flushing) return;
    if (_timer?.isActive ?? false) return;
    _timer = Timer(delay, () => unawaited(flush()));
  }

  /// Sends queued reports in batches. Visible for tests; never throws.
  Future<void> flush() async {
    if (_flushing || _queue.isEmpty || _endpointMissing) return;
    _flushing = true;
    try {
      final meta = await (_metadata ??= _metadataLoader());
      while (_queue.isNotEmpty) {
        final batch = _queue.take(maxBatch).toList();
        final reports = batch.map((r) => r.toJson(meta)).toList();
        final body = reports.length == 1
            ? reports.single
            : <String, dynamic>{'reports': reports};
        int? status;
        try {
          status = await (_sender ?? _defaultSend)(body);
        } catch (_) {
          status = null;
        }
        final ok = status != null && status >= 200 && status < 300;
        if (ok || _isPermanentFailure(status)) {
          if (status == 404) {
            _endpointMissing = true;
            _queue.clear();
            break;
          }
          _queue.removeRange(0, batch.length);
          _attempt = 0;
          continue;
        }
        _attempt++;
        if (_attempt >= maxAttempts) {
          _queue.removeRange(0, batch.length);
          _attempt = 0;
          continue;
        }
        // Retry later with the same batch (plus anything new).
        _flushing = false;
        _timer?.cancel();
        _timer = Timer(retryDelay * _attempt, () => unawaited(flush()));
        return;
      }
    } catch (_) {
      _queue.clear();
      _attempt = 0;
    }
    _flushing = false;
  }

  /// 4xx (except 408/429) will not succeed on retry: drop the batch.
  static bool _isPermanentFailure(int? status) =>
      status != null &&
      status >= 400 &&
      status < 500 &&
      status != 408 &&
      status != 429;

  /// Own Dio (not ApiService/DioClient): a 401 here must never log the user
  /// out, and its errors must never be reported again. The bearer token is
  /// read from the app's existing secure token storage.
  Future<int?> _defaultSend(Map<String, dynamic> body) async {
    final dio = _dio ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (_) => true,
      ),
    );
    String? token;
    try {
      token = await AuthService().getStoredToken();
    } catch (_) {}
    final response = await dio.post<dynamic>(
      '${ApiConstants.baseUrl}${ApiConstants.clientErrors}',
      data: body,
      options: Options(
        headers: token != null && token.isNotEmpty
            ? {'Authorization': 'Bearer $token'}
            : null,
      ),
    );
    return response.statusCode;
  }
}

/// Tracks the current route name for report context.
class ClientErrorRouteObserver extends NavigatorObserver {
  ClientErrorRouteObserver({ClientErrorReporter? reporter})
      : _reporter = reporter ?? ClientErrorReporter.instance;

  final ClientErrorReporter _reporter;

  void _set(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name;
    _reporter.currentRoute =
        (name != null && name.isNotEmpty) ? name : route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _set(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(previousRoute);
}
