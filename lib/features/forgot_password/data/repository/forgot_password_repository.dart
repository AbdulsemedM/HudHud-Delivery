import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/forgot_password/data/data_provider/forgot_password_data_provider.dart';
import 'package:hudhud_delivery/features/forgot_password/data/data_provider/forgot_password_data_source.dart';

/// Result of POST /password/reset-otp
class ResetOtpResult {
  const ResetOtpResult({
    required this.resetId,
    required this.expiresInMinutes,
    this.message,
    this.identifierType,
    this.deliveryMethod,
  });

  final String resetId;
  final int expiresInMinutes;
  final String? message;
  final String? identifierType;
  final String? deliveryMethod;
}

/// Result of POST /password/verify-otp
class VerifyOtpResult {
  const VerifyOtpResult({
    required this.resetToken,
    required this.expiresInMinutes,
    this.message,
  });

  final String resetToken;
  final int expiresInMinutes;
  final String? message;
}

class ForgotPasswordRepository {
  ForgotPasswordRepository(this._dataProvider);

  factory ForgotPasswordRepository.createDefault() {
    return ForgotPasswordRepository(
      ForgotPasswordDataProvider(apiService: ApiService.instance),
    );
  }

  final ForgotPasswordDataSource _dataProvider;

  /// Same email/phone heuristic as login form.
  static String methodForIdentifier(String trimmed) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(trimmed) ? 'email' : 'phone';
  }

  static bool _isSuccess(int? code) =>
      code != null && code >= 200 && code < 300;

  static String _cleanErrorMessage(String raw) {
    var s = raw.replaceFirst(RegExp(r'^Validation error:\s*'), '').trim();
    s = s.replaceFirst(RegExp(r'^HTTP \d+:\s*'), '').trim();
    return s;
  }

  Future<ResetOtpResult> requestResetOtp(String identifier) async {
    final trimmed = identifier.trim();
    final method = methodForIdentifier(trimmed);
    final response = await _dataProvider.requestResetOtp(
      identifier: trimmed,
      method: method,
    );
    final code = response['statusCode'] as int?;
    if (_isSuccess(code)) {
      final data = response['data'];
      if (data is! Map) {
        throw 'Invalid server response';
      }
      final map = Map<String, dynamic>.from(data);
      final resetId = map['reset_id']?.toString();
      if (resetId == null || resetId.isEmpty) {
        throw 'Invalid server response';
      }
      final expires = map['expires_in_minutes'];
      final expiresIn = expires is int
          ? expires
          : int.tryParse(expires?.toString() ?? '') ?? 15;
      return ResetOtpResult(
        resetId: resetId,
        expiresInMinutes: expiresIn,
        message: map['message']?.toString(),
        identifierType: map['identifier_type']?.toString(),
        deliveryMethod: map['delivery_method']?.toString(),
      );
    }
    throw _errorFromResponse(response);
  }

  Future<VerifyOtpResult> verifyOtp({
    required String resetId,
    required String otp,
  }) async {
    final response = await _dataProvider.verifyOtp(
      resetId: resetId,
      otp: otp.trim(),
    );
    final code = response['statusCode'] as int?;
    if (_isSuccess(code)) {
      final data = response['data'];
      if (data is! Map) {
        throw 'Invalid server response';
      }
      final map = Map<String, dynamic>.from(data);
      final token = map['reset_token']?.toString();
      if (token == null || token.isEmpty) {
        throw 'Invalid server response';
      }
      final expires = map['expires_in_minutes'];
      final expiresIn = expires is int
          ? expires
          : int.tryParse(expires?.toString() ?? '') ?? 60;
      return VerifyOtpResult(
        resetToken: token,
        expiresInMinutes: expiresIn,
        message: map['message']?.toString(),
      );
    }
    throw _errorFromResponse(response);
  }

  /// Returns updated expiry minutes when present in the response body.
  Future<int?> resendOtp(String resetId) async {
    final response = await _dataProvider.resendOtp(resetId: resetId);
    final code = response['statusCode'] as int?;
    if (_isSuccess(code)) {
      final data = response['data'];
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final expires = map['expires_in_minutes'];
        if (expires is int) return expires;
        return int.tryParse(expires?.toString() ?? '');
      }
      return 15;
    }
    throw _errorFromResponse(response);
  }

  Future<String> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dataProvider.resetWithToken(
      resetToken: resetToken,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    final code = response['statusCode'] as int?;
    if (_isSuccess(code)) {
      final data = response['data'];
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        return map['message']?.toString() ??
            'Password has been reset successfully!';
      }
      return 'Password has been reset successfully!';
    }
    throw _errorFromResponse(response);
  }

  /// Throws a user-facing [String]. Optionally includes [remainingAttempts] in message for OTP.
  String _errorFromResponse(Map<String, dynamic> response) {
    final err = response['errorMessage'] as String? ?? 'Request failed';
    final cleaned = _cleanErrorMessage(err);
    final data = response['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final remaining = map['remaining_attempts'];
      if (remaining != null) {
        return '$cleaned ($remaining attempts left)';
      }
      final lockedUntil = map['locked_until'];
      if (lockedUntil != null) {
        return '$cleaned (${lockedUntil.toString()})';
      }
    }
    return cleaned;
  }
}
