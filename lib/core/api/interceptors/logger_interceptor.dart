import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('\n🚀 REQUEST[${options.method}] => PATH: ${options.path}');
      print('Headers: ${options.headers}');
      print('Query Parameters: ${options.queryParameters}');
      if (options.data != null) {
        print('Body: ${options.data}');
      }
      print('Base URL: ${options.baseUrl}');
      print('Full URL: ${options.uri}');
      print('Connect Timeout: ${options.connectTimeout}');
      print('Receive Timeout: ${options.receiveTimeout}');
      print('Send Timeout: ${options.sendTimeout}');
      print('═══════════════════════════════════════════════════════════════');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('\n✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      print('Headers: ${response.headers}');
      print('Response Data: ${_formatResponseData(response.data)}');
      print('Status Message: ${response.statusMessage}');
      print('Is Redirect: ${response.isRedirect}');
      print('Real URI: ${response.realUri}');
      print('═══════════════════════════════════════════════════════════════');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('\n❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('Error Type: ${err.type}');
      print('Error Message: ${err.message}');
      
      if (err.response != null) {
        print('Response Headers: ${err.response!.headers}');
        print('Response Data: ${_formatResponseData(err.response!.data)}');
        print('Status Code: ${err.response!.statusCode}');
        print('Status Message: ${err.response!.statusMessage}');
      }
      
      if (err.requestOptions.data != null) {
        print('Request Data: ${err.requestOptions.data}');
      }
      
      print('Stack Trace: ${err.stackTrace}');
      print('═══════════════════════════════════════════════════════════════');
    }
    super.onError(err, handler);
  }

  String _formatResponseData(dynamic data) {
    if (data == null) return 'null';
    
    try {
      // If data is too large, truncate it
      String dataString = data.toString();
      if (dataString.length > 1000) {
        return '${dataString.substring(0, 1000)}... (truncated)';
      }
      return dataString;
    } catch (e) {
      return 'Error formatting response data: $e';
    }
  }
}