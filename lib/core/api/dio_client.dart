import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'api_constants.dart';
import 'interceptors/logger_interceptor.dart';
import '../../app/services/auth_service.dart';

class DioClient {
  static DioClient? _instance;
  late Dio _dio;
  void Function()? _onUnauthorized;
  bool _handlingUnauthorized = false;
  bool _unauthorizedRedirectScheduled = false;

  DioClient._internal() : _onUnauthorized = null {
    _dio = Dio();
    _setupDio();
  }

  void setOnUnauthorized(void Function()? callback) {
    _onUnauthorized = callback;
  }

  static DioClient get instance {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Auth first so debug logs see the final Authorization header.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Session-creation endpoints must not send an old HudHud Bearer token.
          if (ApiConstants.isUnauthenticatedAuthPath(options.path)) {
            options.headers.remove('Authorization');
            handler.next(options);
            return;
          }
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isSessionCreation =
              ApiConstants.isUnauthenticatedAuthPath(path);
          if (error.response?.statusCode == 401 && !isSessionCreation) {
            await _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LoggerInterceptor());
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final authService = AuthService();
      return await authService.getStoredToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error retrieving auth token: $e');
      }
      return null;
    }
  }

  void _scheduleUnauthorizedRedirect() {
    if (_unauthorizedRedirectScheduled) return;
    _unauthorizedRedirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unauthorizedRedirectScheduled = false;
      _onUnauthorized?.call();
    });
  }

  Future<void> _handleUnauthorized() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    try {
      final authService = AuthService();

      // Try to refresh the token first
      final refreshed = await authService.refreshToken();

      if (!refreshed) {
        // If refresh fails, clear the session
        await authService.clearAllData();

        if (kDebugMode) {
          debugPrint('Token refresh failed, session cleared');
        }
        _scheduleUnauthorizedRedirect();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error handling unauthorized access: $e');
      }
      final authService = AuthService();
      await authService.clearAllData();
      _scheduleUnauthorizedRedirect();
    } finally {
      _handlingUnauthorized = false;
    }
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  void addAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
