import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/models/user_model.dart';

/// Typed failure from authenticated phone enrollment endpoints.
///
/// Callers must keep the HudHud Sanctum session; never clear the token for these.
class PhoneEnrollmentException implements Exception {
  PhoneEnrollmentException(
    this.message, {
    required this.code,
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String message;
  final String code;
  final int? statusCode;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}

class PhoneEnrollmentStatus {
  const PhoneEnrollmentStatus({
    required this.phone,
    required this.phoneVerified,
    required this.phoneEnrollmentRequired,
  });

  final String? phone;
  final bool phoneVerified;
  final bool phoneEnrollmentRequired;
}

class PhoneEnrollmentRequestResult {
  const PhoneEnrollmentRequestResult({
    required this.phone,
    required this.resendAvailableInSeconds,
    required this.message,
  });

  final String phone;
  final int resendAvailableInSeconds;
  final String message;
}

class PhoneEnrollmentVerifyResult {
  const PhoneEnrollmentVerifyResult({
    required this.user,
    required this.message,
  });

  final UserModel user;
  final String message;
}

/// Authenticated phone enrollment + SMS OTP (Sanctum Bearer).
class PhoneEnrollmentService {
  PhoneEnrollmentService({
    ApiService? apiService,
    AuthService? authService,
  })  : _api = apiService ?? ApiService.instance,
        _auth = authService ?? AuthService();

  final ApiService _api;
  final AuthService _auth;

  Future<PhoneEnrollmentStatus> getStatus() async {
    try {
      final response = await _api.get(ApiConstants.phoneEnrollmentStatus);
      final data = _asMap(response.data);
      if (response.statusCode == 200 && data['success'] == true) {
        return PhoneEnrollmentStatus(
          phone: data['phone']?.toString(),
          phoneVerified: data['phone_verified'] == true,
          phoneEnrollmentRequired: data['phone_enrollment_required'] == true,
        );
      }
      throw PhoneEnrollmentException(
        data['message']?.toString() ?? 'Unable to check phone enrollment status.',
        code: data['code']?.toString() ?? 'PHONE_ENROLLMENT_STATUS_FAILED',
        statusCode: response.statusCode,
      );
    } on PhoneEnrollmentException {
      rethrow;
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  Future<PhoneEnrollmentRequestResult> requestOtp(String inputPhone) async {
    try {
      final response = await _api.post(
        ApiConstants.phoneEnrollmentRequest,
        data: {'phone': normalizePhoneToBackend(inputPhone)},
      );
      final data = _asMap(response.data);
      if (response.statusCode == 202 && data['success'] == true) {
        return PhoneEnrollmentRequestResult(
          phone: data['phone']?.toString() ?? normalizePhoneToBackend(inputPhone),
          resendAvailableInSeconds: _parseInt(
                data['resend_available_in_seconds'],
              ) ??
              60,
          message: data['message']?.toString() ??
              'A verification code has been sent to your phone number.',
        );
      }
      throw PhoneEnrollmentException(
        data['message']?.toString() ?? 'Failed to send verification code.',
        code: data['code']?.toString() ?? 'PHONE_ENROLLMENT_REQUEST_FAILED',
        statusCode: response.statusCode,
        retryAfterSeconds: _parseInt(
          data['retry_after_seconds'] ?? data['retry_after'],
        ),
      );
    } on PhoneEnrollmentException {
      rethrow;
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  Future<PhoneEnrollmentVerifyResult> verifyOtp(String code) async {
    try {
      final response = await _api.post(
        ApiConstants.phoneEnrollmentVerify,
        data: {'code': code.trim()},
      );
      final data = _asMap(response.data);
      if (response.statusCode == 200 &&
          (data['code']?.toString() == 'PHONE_VERIFIED' ||
              data['success'] == true)) {
        final userMap = data['user'];
        if (userMap is! Map) {
          throw PhoneEnrollmentException(
            'Invalid verification response.',
            code: 'PHONE_VERIFICATION_INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }
        final user = UserModel.fromMap(Map<String, dynamic>.from(userMap));
        await _auth.updateCurrentUser(user);
        return PhoneEnrollmentVerifyResult(
          user: user,
          message:
              data['message']?.toString() ?? 'Phone number verified successfully.',
        );
      }
      throw PhoneEnrollmentException(
        data['message']?.toString() ?? 'Failed to verify phone.',
        code: data['code']?.toString() ?? 'PHONE_VERIFICATION_FAILED',
        statusCode: response.statusCode,
        retryAfterSeconds: _parseInt(
          data['retry_after_seconds'] ?? data['retry_after'],
        ),
      );
    } on PhoneEnrollmentException {
      rethrow;
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  PhoneEnrollmentException _fromApiException(ApiException e) {
    final data = e.data is Map ? Map<String, dynamic>.from(e.data as Map) : null;
    final code = e.code ??
        data?['code']?.toString() ??
        data?['error_code']?.toString() ??
        'PHONE_ENROLLMENT_ERROR';
    final retry = e.retryAfter ??
        _parseInt(
          data?['retry_after_seconds'] ??
              data?['retry_after'] ??
              data?['resend_available_in_seconds'],
        );
    return PhoneEnrollmentException(
      e.message.isNotEmpty ? e.message : 'Phone enrollment failed.',
      code: code,
      statusCode: e.statusCode,
      retryAfterSeconds: retry,
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
