import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';
import 'interceptors/logger_interceptor.dart';

class DioClient {
  static DioClient? _instance;
  late Dio _dio;

  DioClient._internal() {
    _dio = Dio();
    _setupDio();
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
          // Add auth token if available
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token refresh logic here if needed
          if (error.response?.statusCode == 401) {
            // Token expired, handle refresh or logout
            await _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _getAuthToken() async {
    // Implement token retrieval from secure storage
    // This will be implemented in auth_service.dart
    return null;
  }

  Future<void> _handleUnauthorized() async {
    // Handle unauthorized access (logout, redirect to login, etc.)
    // This will be implemented based on your auth flow
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