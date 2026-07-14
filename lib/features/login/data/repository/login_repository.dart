import 'package:flutter/foundation.dart';

import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:hudhud_delivery/app/services/fcm_service.dart';
import 'package:hudhud_delivery/app/services/google_auth_helper.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/models/user_model.dart';

class LoginRepository {
  final LoginDataProvider loginDataProvider;
  LoginRepository(this.loginDataProvider);

  Future<UserModel> login(String emailOrPhone, String password, String fieldType) async {
    AuthService authService = AuthService();
    try {
      final response = await loginDataProvider.login(emailOrPhone, password, fieldType);
      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data == null || data['token'] == null || data['user'] == null) {
          throw 'Invalid server response: missing required data';
        }

        final user = await _completeSessionFromLoginData(data, authService);
        await _maybeRefreshBiometricCredentials(
          emailOrPhone: emailOrPhone,
          password: password,
          fieldType: fieldType,
        );
        return user;
      } else {
        // Get clean error message from data provider
        String errorMessage = response['errorMessage'] ?? 'Login failed';
        // Clean any prefixes that might exist
        errorMessage = _cleanErrorMessage(errorMessage);
        throw errorMessage; // Throw string directly instead of Exception
      }
    } catch (e) {
      if (e is String) {
        rethrow; // Re-throw clean string errors
      }
      // Clean any exception messages
      String errorMessage = _cleanErrorMessage(e.toString());
      throw errorMessage;
    }
  }

  Future<UserModel> googleLogin() async {
    final authService = AuthService();
    try {
      final idToken = await obtainGoogleIdToken();
      debugPrint(
        '[GoogleSignIn] id_token received (length ${idToken.length})',
      );
      final deviceToken = await FcmService().getToken();
      final response = await loginDataProvider.googleLogin(
        idToken: idToken,
        deviceToken: deviceToken,
      );
      final code = response['statusCode'] as int?;
      if (code == 200 || code == 201) {
        final raw = response['data'];
        final data = _normalizeLoginPayload(raw);
        return _completeSessionFromLoginData(data, authService);
      }
      String errorMessage =
          response['errorMessage'] as String? ?? 'Google login failed';
      errorMessage = _cleanErrorMessage(errorMessage);
      debugPrint('[GoogleSignIn] backend HTTP $code: $errorMessage');
      debugPrint('[GoogleSignIn] backend response data: ${response['data']}');
      throw errorMessage;
    } on GoogleSignInUserCancelled {
      rethrow;
    } catch (e, st) {
      debugPrint('[GoogleSignIn] googleLogin failed: $e');
      debugPrint('$st');
      if (e is String) rethrow;
      throw _cleanErrorMessage(e.toString());
    }
  }

  /// Accepts either `{ token, user }` or `{ success, data: { token, user } }`.
  Map<String, dynamic> _normalizeLoginPayload(dynamic raw) {
    if (raw is! Map) {
      throw 'Invalid server response: missing required data';
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['token'] != null && map['user'] != null) {
      return map;
    }
    final inner = map['data'];
    if (inner is Map &&
        inner['token'] != null &&
        inner['user'] != null) {
      return Map<String, dynamic>.from(inner);
    }
    throw 'Invalid server response: missing required data';
  }

  Future<UserModel> guest() async {
    final authService = AuthService();
    try {
      final response = await loginDataProvider.guest();
      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data == null || data['token'] == null || data['user'] == null) {
          throw 'Invalid server response: missing required data';
        }

        return _completeSessionFromLoginData(data, authService);
      } else {
        String errorMessage = response['errorMessage'] ?? 'Guest login failed';
        errorMessage = _cleanErrorMessage(errorMessage);
        throw errorMessage;
      }
    } catch (e) {
      if (e is String) {
        rethrow;
      }
      String errorMessage = _cleanErrorMessage(e.toString());
      throw errorMessage;
    }
  }

  Future<UserModel> _completeSessionFromLoginData(
    Map<String, dynamic> data,
    AuthService authService,
  ) async {
    final token = data['token'] as String;
    final permissions = data['permissions'] as List<dynamic>?;
    final loginUser = UserModel.fromMap(
      Map<String, dynamic>.from(data['user'] as Map<String, dynamic>)
        ..['permissions'] = permissions ?? [],
    );

    await authService.storeTokenOnly(
      token: token,
      refreshToken: data['refresh_token']?.toString(),
      expiresIn: data['expires_in'] is int ? data['expires_in'] as int : null,
    );

    try {
      final profileUser = await authService.fetchProfileAndStore(
        permissions: permissions,
      );
      return profileUser ?? loginUser;
    } catch (_) {
      await authService.storeUserSession(
        user: loginUser,
        token: token,
        refreshToken: data['refresh_token']?.toString(),
        expiresIn: data['expires_in'] is int ? data['expires_in'] as int : null,
      );
      return loginUser;
    }
  }

  Future<void> _maybeRefreshBiometricCredentials({
    required String emailOrPhone,
    required String password,
    required String fieldType,
  }) async {
    final biometric = BiometricCredentialService();
    if (!await biometric.isBiometricLoginEnabled()) return;
    await biometric.saveCredentials(
      identifier: emailOrPhone,
      password: password,
      fieldType: fieldType,
    );
  }

  String _cleanErrorMessage(String message) {
    // Remove various prefixes that might appear
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    if (message.startsWith('ApiException: ')) {
      message = message.substring(14);
    }
    if (message.startsWith('FormatException: ')) {
      message = message.substring(17);
    }
    return message;
  }
}
