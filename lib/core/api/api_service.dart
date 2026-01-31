import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class ApiService {
  static ApiService? _instance;
  late Dio _dio;

  ApiService._internal() {
    _dio = DioClient.instance.dio;
  }

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // GET request
  Future<Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Unexpected error occurred: $e');
    }
  }

  // POST request
  Future<Response<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Unexpected error occurred: $e');
    }
  }

  // PUT request
  Future<Response<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Unexpected error occurred: $e');
    }
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Unexpected error occurred: $e');
    }
  }

  // PATCH request
  Future<Response<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Unexpected error occurred: $e');
    }
  }

  // Handle Dio errors
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException('Connection timeout. Please check your internet connection.');
      case DioExceptionType.sendTimeout:
        return ApiException('Send timeout. Please try again.');
      case DioExceptionType.receiveTimeout:
        return ApiException('Receive timeout. Please try again.');
      case DioExceptionType.badResponse:
        return _handleResponseError(error);
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.');
      case DioExceptionType.connectionError:
        return ApiException('Connection error. Please check your internet connection.');
      case DioExceptionType.badCertificate:
        return ApiException('Bad certificate. Please contact support.');
      case DioExceptionType.unknown:
      return ApiException('An unexpected error occurred: ${error.message}');
    }
  }

  // Handle response errors
  ApiException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    String message = 'An error occurred';
    
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      message = data['message'];
    } else if (data is String) {
      message = data;
    }
    
    switch (statusCode) {
      case 400:
        return ApiException('Bad request: $message', statusCode: statusCode);
      case 401:
        return ApiException('Unauthorized: Please login again', statusCode: statusCode);
      case 403:
        return ApiException('Forbidden: You don\'t have permission', statusCode: statusCode);
      case 404:
        return ApiException('Not found: $message', statusCode: statusCode);
      case 422:
        return ApiException('Validation error: $message', statusCode: statusCode);
      case 500:
        return ApiException('Server error: Please try again later', statusCode: statusCode);
      case 502:
        return ApiException('Bad gateway: Server is temporarily unavailable', statusCode: statusCode);
      case 503:
        return ApiException('Service unavailable: Please try again later', statusCode: statusCode);
      default:
        return ApiException('HTTP $statusCode: $message', statusCode: statusCode);
    }
  }
}

// Custom API Exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}