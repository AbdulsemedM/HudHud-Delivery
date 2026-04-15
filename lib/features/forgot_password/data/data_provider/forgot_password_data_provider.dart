import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class ForgotPasswordDataProvider {
  ForgotPasswordDataProvider({required this.apiService});

  final ApiService apiService;

  Future<Map<String, dynamic>> requestResetOtp({
    required String identifier,
    required String method,
  }) async {
    try {
      final response = await apiService.post(
        ApiConstants.passwordResetOtp,
        data: {
          'identifier': identifier,
          'method': method,
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String resetId,
    required String otp,
  }) async {
    try {
      final response = await apiService.post(
        ApiConstants.passwordVerifyOtp,
        data: {
          'reset_id': resetId,
          'otp': otp,
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> resendOtp({required String resetId}) async {
    try {
      final response = await apiService.post(
        ApiConstants.passwordResendOtp,
        data: {'reset_id': resetId},
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> resetWithToken({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await apiService.post(
        ApiConstants.passwordResetWithToken,
        data: {
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: $e',
      };
    }
  }
}
