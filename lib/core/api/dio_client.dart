import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'api_constants.dart';
import 'interceptors/logger_interceptor.dart';
import '../../app/services/auth_service.dart';
import '../../app/services/guest_browse_service.dart';

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
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    if (kDebugMode) {
      _dio.interceptors.add(LoggerInterceptor());
    }

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (GuestBrowseService().isGuestBrowseMode) {
            handler.next(options);
            return;
          }
          // Add auth token if available
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !GuestBrowseService().isGuestBrowseMode) {
            await _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _getAuthToken() async {
    try {
      final authService = AuthService();
      return await authService.getStoredToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving auth token: $e');
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
    if (_handlingUnauthorized || GuestBrowseService().isGuestBrowseMode) return;
    _handlingUnauthorized = true;
    try {
      final authService = AuthService();

      // Try to refresh the token first
      final refreshed = await authService.refreshToken();

      if (!refreshed) {
        // If refresh fails, clear the session
        await authService.clearAllData();

        if (kDebugMode) {
          print('Token refresh failed, session cleared');
        }
        _scheduleUnauthorizedRedirect();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling unauthorized access: $e');
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