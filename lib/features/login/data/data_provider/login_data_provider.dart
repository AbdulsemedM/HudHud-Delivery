import 'package:flutter/foundation.dart';

import 'package:hudhud_delivery/core/api/api_service.dart';

import '../../../../core/api/api_constants.dart';

class LoginDataProvider {
  ApiService apiService;
  LoginDataProvider({required this.apiService});

  Future<Map<String, dynamic>> login(String emailOrPhone, String password, String fieldType) async {
    try {
      final body = {
        fieldType: emailOrPhone, // Use 'email' or 'phone' as key
        'password': password,
      };
      final response = await apiService.post(
        ApiConstants.login,
        data: body,
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// POST /api/auth/google-login — customer app uses `user_type: customer`.
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    String? deviceToken,
  }) async {
    try {
      final body = <String, dynamic>{
        'id_token': idToken,
        'user_type': 'customer',
      };
      if (deviceToken != null && deviceToken.isNotEmpty) {
        body['device_token'] = deviceToken;
      }
      final response = await apiService.post(
        ApiConstants.googleLogin,
        data: body,
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
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
      };
    } on Exception catch (e, st) {
      debugPrint('[GoogleSignIn] googleLogin request failed: $e');
      debugPrint('$st');
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
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
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
      };
    }
  }
}
