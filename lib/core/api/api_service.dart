import 'package:dio/dio.dart';
import 'package:hudhud_delivery/core/utils/api_error_message.dart';
// import 'package:flutter/foundation.dart';
import 'dio_client.dart';

export 'package:hudhud_delivery/core/utils/api_error_message.dart'
    show extractApiErrorMessage, parseApiErrorResult, ApiErrorResult;

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

    Map<String, dynamic>? payload;
    if (data is Map) {
      payload = Map<String, dynamic>.from(data);
    }

    final parsed = data is String
        ? parseApiErrorResult(data, statusCode: statusCode)
        : parseApiErrorResult(data, statusCode: statusCode);
    final message = parsed.displayMessage;
    final code = parsed.code;

    switch (statusCode) {
      case 400:
      case 404:
      case 422:
        // Prefer clean structured messages for payment-style client errors.
        return ApiException(
          message,
          statusCode: statusCode,
          data: payload,
          code: code,
        );
      case 401:
        return ApiException('Unauthorized: Please login again',
            statusCode: statusCode, data: payload, code: code);
      case 403:
        return ApiException('Forbidden: You don\'t have permission',
            statusCode: statusCode, data: payload, code: code);
      case 429:
        return ApiException(message,
            statusCode: statusCode, data: payload, code: code);
      case 500:
        return ApiException('Server error: Please try again later',
            statusCode: statusCode, data: payload, code: code);
      case 502:
        return ApiException('Bad gateway: Server is temporarily unavailable',
            statusCode: statusCode, data: payload, code: code);
      case 503:
        return ApiException('Service unavailable: Please try again later',
            statusCode: statusCode, data: payload, code: code);
      default:
        return ApiException(message,
            statusCode: statusCode, data: payload, code: code);
    }
  }
}

// Custom API Exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final String? code;

  ApiException(this.message, {this.statusCode, this.data, this.code});

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}

/// Strips Exception/ApiException prefixes for snackbars and bloc error states.
String userFacingApiError(Object error, {String fallback = 'An error occurred'}) {
  if (error is ApiException) {
    return error.message.isNotEmpty ? error.message : fallback;
  }

  var text = error.toString();
  const prefixes = [
    'ApiException: ',
    'Exception: ',
    'FormatException: ',
  ];
  for (final p in prefixes) {
    if (text.startsWith(p)) {
      text = text.substring(p.length);
    }
  }
  text = text.replaceFirst(RegExp(r'\s*\(Status:\s*\d+\)\s*$'), '');
  // Nested wraps like "Failed to initiate payment: ApiException: ..."
  for (final p in prefixes) {
    final idx = text.indexOf(p);
    if (idx >= 0) {
      text = text.substring(idx + p.length);
    }
  }
  text = text.replaceFirst(RegExp(r'\s*\(Status:\s*\d+\)\s*$'), '');
  text = text.trim();
  return text.isNotEmpty ? text : fallback;
}
