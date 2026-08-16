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
      throw ApiException('An unexpected error occurred. Please try again.');
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
      throw ApiException('An unexpected error occurred. Please try again.');
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
      throw ApiException('An unexpected error occurred. Please try again.');
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
      throw ApiException('An unexpected error occurred. Please try again.');
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
      throw ApiException('An unexpected error occurred. Please try again.');
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
        return ApiException('An unexpected error occurred. Please try again.');
    }
  }

  // Handle response errors
  ApiException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final headers = error.response?.headers;

    Map<String, dynamic>? payload;
    if (data is Map) {
      payload = Map<String, dynamic>.from(data);
    }

    final parsed = data is String
        ? parseApiErrorResult(data, statusCode: statusCode)
        : parseApiErrorResult(data, statusCode: statusCode);
    final message = parsed.displayMessage;
    final code = parsed.code;
    final retryAfter = _resolveRetryAfter(
      headers: headers,
      payload: payload,
    );

    switch (statusCode) {
      case 400:
      case 422:
        // Prefer clean structured messages for payment-style client errors.
        return ApiException(
          message,
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 401:
        return ApiException(
          'Your session has expired. Please login again.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 403:
        return ApiException(
          'You do not have permission to perform this action.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 404:
        return ApiException(
          message.isNotEmpty && !_isGenericNotFound(message)
              ? message
              : 'This item is unavailable or could not be found.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 409:
        final conflictMessage = code == 'IDEMPOTENCY_CONFLICT'
            ? (message.isNotEmpty
                ? message
                : 'This request conflicts with an existing payment. Do not create a duplicate.')
            : (message.isNotEmpty
                ? message
                : 'This action conflicts with an existing request.');
        return ApiException(
          conflictMessage,
          statusCode: statusCode,
          data: payload,
          code: code ?? 'conflict',
          retryAfter: retryAfter,
        );
      case 429:
        return ApiException(
          message.isNotEmpty
              ? message
              : 'Too many attempts. Please try again later.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 500:
        return ApiException(
          'Something went wrong on our side. Please try again later.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 502:
        return ApiException(
          'The service is temporarily unavailable. Please try again.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 503:
        if (code == ApiException.serviceComingSoonCode) {
          return ApiException(
            message.isNotEmpty ? message : 'Coming soon',
            statusCode: statusCode,
            data: payload,
            code: code,
            retryAfter: retryAfter,
          );
        }
        return ApiException(
          'Service unavailable. Please try again later.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      case 504:
        return ApiException(
          'The request timed out. Please try again.',
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
      default:
        return ApiException(
          message,
          statusCode: statusCode,
          data: payload,
          code: code,
          retryAfter: retryAfter,
        );
    }
  }

  bool _isGenericNotFound(String message) {
    final lower = message.toLowerCase();
    return lower == 'not found' ||
        lower.contains('not found') && lower.length < 20;
  }

  int? _resolveRetryAfter({
    Headers? headers,
    Map<String, dynamic>? payload,
  }) {
    final headerValue = headers?.value('retry-after');
    final fromHeader = _parsePositiveInt(headerValue);
    if (fromHeader != null) return fromHeader;

    if (payload == null) return null;
    return _parsePositiveInt(
      payload['retry_after'] ?? payload['retryAfter'],
    );
  }

  int? _parsePositiveInt(dynamic value) {
    if (value == null) return null;
    int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num) {
      parsed = value.toInt();
    } else {
      parsed = int.tryParse(value.toString());
    }
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}

// Custom API Exception class
class ApiException implements Exception {
  static const String serviceComingSoonCode = 'SERVICE_COMING_SOON';

  final String message;
  final int? statusCode;
  final dynamic data;
  final String? code;
  /// Seconds until a safe retry (from `Retry-After` / `retry_after`).
  final int? retryAfter;

  ApiException(
    this.message, {
    this.statusCode,
    this.data,
    this.code,
    this.retryAfter,
  });

  bool get isServiceComingSoon =>
      statusCode == 503 && code == serviceComingSoonCode;

  bool get isConflict => statusCode == 409;
  bool get isRateLimited => statusCode == 429;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}

/// True when a data-provider style result map is a gated "coming soon" service.
bool isServiceComingSoonResult(Map<String, dynamic> result) {
  return result['statusCode'] == 503 &&
      result['code'] == ApiException.serviceComingSoonCode;
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
