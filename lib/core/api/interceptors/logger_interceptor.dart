import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\n🚀 REQUEST[${options.method}] => PATH: ${options.path}');
      debugPrint('Headers: ${options.headers}');
      debugPrint('Query Parameters: ${options.queryParameters}');
      if (options.data != null) {
        debugPrint('Body: ${options.data}');
      }
      debugPrint('Base URL: ${options.baseUrl}');
      debugPrint('Full URL: ${options.uri}');
      debugPrint('Connect Timeout: ${options.connectTimeout}');
      debugPrint('Receive Timeout: ${options.receiveTimeout}');
      debugPrint('Send Timeout: ${options.sendTimeout}');
      debugPrint('═══════════════════════════════════════════════════════════════');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\n✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Response Data: ${_formatResponseData(response.data)}');
      debugPrint('Status Message: ${response.statusMessage}');
      debugPrint('Is Redirect: ${response.isRedirect}');
      debugPrint('Real URI: ${response.realUri}');
      debugPrint('═══════════════════════════════════════════════════════════════');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\n❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      debugPrint('Error Type: ${err.type}');
      debugPrint('Error Message: ${err.message}');
      
      if (err.response != null) {
        debugPrint('Response Headers: ${err.response!.headers}');
        debugPrint('Response Data: ${_formatResponseData(err.response!.data)}');
        debugPrint('Status Code: ${err.response!.statusCode}');
        debugPrint('Status Message: ${err.response!.statusMessage}');
      }
      
      if (err.requestOptions.data != null) {
        debugPrint('Request Data: ${err.requestOptions.data}');
      }
      
      debugPrint('Stack Trace: ${err.stackTrace}');
      debugPrint('═══════════════════════════════════════════════════════════════');
    }
    super.onError(err, handler);
  }

  String _formatResponseData(dynamic data) {
    if (data == null) return 'null';

    try {
      return data.toString();
    } catch (e) {
      return 'Error formatting response data: $e';
    }
  }
}