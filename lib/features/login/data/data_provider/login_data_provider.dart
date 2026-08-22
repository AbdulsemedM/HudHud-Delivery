import 'package:flutter/foundation.dart';

import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/login_device_metadata.dart';

import '../../../../core/api/api_constants.dart';

class LoginDataProvider {
  ApiService apiService;
  LoginDataProvider({required this.apiService});

  static const _genericUnexpected =
      'Something went wrong. Please try again.';

  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
    String fieldType, {
    LoginDeviceMetadata? deviceMetadata,
  }) async {
    try {
      final body = <String, dynamic>{
        fieldType: emailOrPhone, // Use 'email' or 'phone' as key
        'password': password,
      };
      final meta = deviceMetadata ?? await LoginDeviceMetadata.collect();
      meta.applyTo(body);
      final response = await apiService.post(
        ApiConstants.login,
        data: body,
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
        'code': null,
        'retryAfter': null,
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
        'code': apiError.code,
        'retryAfter': apiError.retryAfter,
      };
    } on Exception {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': _genericUnexpected,
        'code': null,
        'retryAfter': null,
      };
    }
  }

  /// POST /api/auth/google-login — customer app uses `user_type: customer`.
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    LoginDeviceMetadata? deviceMetadata,
  }) async {
    try {
      final body = <String, dynamic>{
        'id_token': idToken,
        'user_type': 'customer',
      };
      final meta = deviceMetadata ?? await LoginDeviceMetadata.collect();
      meta.applyTo(body);
      final response = await apiService.post(
        ApiConstants.googleLogin,
        data: body,
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
        'code': null,
        'retryAfter': null,
      };
    } on ApiException catch (apiError) {
      debugPrint(
        '[GoogleSignIn] ApiException status=${apiError.statusCode} '
        'message=${apiError.message} data=${apiError.data}',
      );
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
        'code': apiError.code,
        'retryAfter': apiError.retryAfter,
      };
    } on Exception catch (e, st) {
      debugPrint('[GoogleSignIn] googleLogin request failed: $e');
      debugPrint('$st');
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': _genericUnexpected,
        'code': null,
        'retryAfter': null,
      };
    }
  }

  Future<Map<String, dynamic>> guest() async {
    try {
      final response = await apiService.post(
        ApiConstants.guest,
        data: <String, dynamic>{},
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
        'code': null,
        'retryAfter': null,
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
        'code': apiError.code,
        'retryAfter': apiError.retryAfter,
      };
    } on Exception {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': _genericUnexpected,
        'code': null,
        'retryAfter': null,
      };
    }
  }
}
