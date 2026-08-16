import 'package:flutter/foundation.dart';

import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:hudhud_delivery/app/services/fcm_service.dart';
import 'package:hudhud_delivery/app/services/google_auth_helper.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/models/user_model.dart';

class LoginFailureException implements Exception {
  LoginFailureException(
    this.message, {
    this.attemptsRemaining,
    this.retryAfterSeconds,
    this.isAccountLocked = false,
    this.code,
  });

  final String message;
  final int? attemptsRemaining;
  final int? retryAfterSeconds;
  final bool isAccountLocked;
  final String? code;

  @override
  String toString() => message;
}

class LoginRepository {
  final LoginDataProvider loginDataProvider;
  LoginRepository(this.loginDataProvider);

  Future<UserModel> login(
    String emailOrPhone,
    String password,
    String fieldType,
  ) async {
    AuthService authService = AuthService();
    try {
      final response =
          await loginDataProvider.login(emailOrPhone, password, fieldType);
      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data == null || data['token'] == null || data['user'] == null) {
          throw LoginFailureException(
            'Invalid server response: missing required data',
          );
        }

        final user = await _completeSessionFromLoginData(data, authService);
        await _maybeRefreshBiometricCredentials(
          emailOrPhone: emailOrPhone,
          password: password,
          fieldType: fieldType,
        );
        return user;
      } else {
        throw _loginFailureFromResponse(response);
      }
    } catch (e) {
      if (e is LoginFailureException) rethrow;
      if (e is String) throw LoginFailureException(e);
      throw LoginFailureException(_cleanErrorMessage(e.toString()));
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
      throw _loginFailureFromResponse(
        response,
        fallback: 'Google login failed',
      );
    } on GoogleSignInUserCancelled {
      rethrow;
    } on LoginFailureException {
      rethrow;
    } catch (e, st) {
      debugPrint('[GoogleSignIn] googleLogin failed: $e');
      debugPrint('$st');
      if (e is String) throw LoginFailureException(e);
      throw LoginFailureException(_cleanErrorMessage(e.toString()));
    }
  }

  /// Accepts either `{ token, user }` or `{ success, data: { token, user } }`.
  Map<String, dynamic> _normalizeLoginPayload(dynamic raw) {
    if (raw is! Map) {
      throw LoginFailureException(
        'Invalid server response: missing required data',
      );
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
    throw LoginFailureException(
      'Invalid server response: missing required data',
    );
  }

  Future<UserModel> guest() async {
    final authService = AuthService();
    try {
      final response = await loginDataProvider.guest();
      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data == null || data['token'] == null || data['user'] == null) {
          throw LoginFailureException(
            'Invalid server response: missing required data',
          );
        }

        return _completeSessionFromLoginData(data, authService);
      } else {
        throw _loginFailureFromResponse(
          response,
          fallback: 'Guest login failed',
        );
      }
    } catch (e) {
      if (e is LoginFailureException) rethrow;
      if (e is String) throw LoginFailureException(e);
      throw LoginFailureException(_cleanErrorMessage(e.toString()));
    }
  }

  LoginFailureException _loginFailureFromResponse(
    Map<String, dynamic> response, {
    String fallback = 'Login failed',
  }) {
    var message = _cleanErrorMessage(
      response['errorMessage'] as String? ?? fallback,
    );
    final statusCode = response['statusCode'] as int?;
    final code = response['code']?.toString() ??
        _codeFromData(response['data']);
    final retryAfter = _parseRetryAfter(
      response['retryAfter'] ?? _retryAfterFromData(response['data']),
    );
    final attempts = _parseAttemptsRemaining(response['data']);

    final isLocked = statusCode == 429 ||
        code == 'AUTH_ACCOUNT_LOCKED' ||
        (message.toLowerCase().contains('too many') &&
            message.toLowerCase().contains('attempt'));

    if (attempts != null && !isLocked) {
      message = '$message ($attempts attempts remaining)';
    }
    if (isLocked && retryAfter != null && retryAfter > 0) {
      final minutes = (retryAfter / 60).ceil();
      message = minutes <= 1
          ? '$message Try again in about a minute.'
          : '$message Try again in about $minutes minutes.';
    }

    return LoginFailureException(
      message,
      attemptsRemaining: attempts,
      retryAfterSeconds: retryAfter,
      isAccountLocked: isLocked,
      code: code,
    );
  }

  String? _codeFromData(dynamic data) {
    if (data is! Map) return null;
    return data['code']?.toString() ?? data['error_code']?.toString();
  }

  dynamic _retryAfterFromData(dynamic data) {
    if (data is! Map) return null;
    return data['retry_after'] ?? data['retryAfter'];
  }

  int? _parseRetryAfter(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  int? _parseAttemptsRemaining(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final raw = map['attempts_remaining'] ?? map['remaining_attempts'];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
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
