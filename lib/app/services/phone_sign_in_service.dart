import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/models/user_model.dart';

/// Typed failure from the passwordless sign-in endpoints.
///
/// Unlike [PhoneEnrollmentException], these endpoints are PUBLIC: there is no
/// session to preserve, because this is how a caller with no account and no
/// token gets one.
///
/// [code] mirrors the backend's `code` field exactly, because the UI branches
/// on it: only `CODE_INVALID` should keep the user on the code screen. Every
/// other failure needs a fresh code or a different action.
class PhoneSignInException implements Exception {
  PhoneSignInException(
    this.message, {
    required this.code,
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String message;
  final String code;
  final int? statusCode;
  final int? retryAfterSeconds;

  /// The only failure the user can recover from without a new code.
  bool get isRetryableOnCodeScreen => code == 'CODE_INVALID';

  @override
  String toString() => message;
}

class PhoneSignInRequestResult {
  const PhoneSignInRequestResult({
    required this.phone,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
    required this.message,
  });

  /// Normalised number. Keep this in state and send the SAME value to verify —
  /// a different one fails with NO_CODE.
  final String phone;

  final int expiresInSeconds;

  /// Drive the resend countdown from this rather than a hardcoded 60, so the
  /// client and server cannot disagree about when a resend is allowed.
  final int resendAfterSeconds;

  final String message;
}

class PhoneSignInVerifyResult {
  const PhoneSignInVerifyResult({
    required this.user,
    required this.token,
    required this.created,
    required this.onboardingRequired,
  });

  final UserModel user;
  final String token;

  /// True when this phone had no account and one was just created. Use it to
  /// decide whether to ask "what's your name?" — not to infer anything from
  /// the request step, which deliberately looks identical either way.
  final bool created;

  /// Rider app only. The token is VALID and the user IS signed in; they simply
  /// cannot take jobs until an admin approves onboarding. Never treat this as
  /// a login failure — route to the onboarding flow instead.
  final bool onboardingRequired;
}

/// Passwordless phone sign-in (public endpoints, no Bearer token).
///
/// Mirrors [PhoneEnrollmentService]'s shape deliberately so both phone flows
/// read the same way, but note the differences:
///   - these endpoints are unauthenticated
///   - verify returns a Sanctum token that must be persisted before any
///     authenticated call is made
class PhoneSignInService {
  PhoneSignInService({
    ApiService? apiService,
    AuthService? authService,
    this.app = kPhoneSignInAppCustomer,
  })  : _api = apiService ?? ApiService.instance,
        _auth = authService ?? AuthService();

  final ApiService _api;
  final AuthService _auth;

  /// Which set of rules the backend applies. The customer app must send
  /// `customer`; the rider app sends `rider`. A code issued for one app is
  /// rejected by the other.
  final String app;

  /// Ask for a code.
  ///
  /// The backend answers with an identical 200 whether or not the number has
  /// an account — that is deliberate, so the endpoint cannot be used to
  /// discover who is registered. Do not try to infer "new user" from this
  /// call; [PhoneSignInVerifyResult.created] is the only honest signal.
  Future<PhoneSignInRequestResult> requestCode(String inputPhone) async {
    final normalized = normalizePhoneToBackend(inputPhone);
    try {
      final response = await _api.post(
        ApiConstants.phoneSignInRequest,
        data: {'phone': normalized, 'app': app},
      );
      final data = _asMap(response.data);
      if (response.statusCode == 200 && data['success'] == true) {
        return PhoneSignInRequestResult(
          phone: normalized,
          expiresInSeconds: _parseInt(data['expires_in']) ?? 300,
          resendAfterSeconds: _parseInt(data['resend_after']) ?? 60,
          message: data['message']?.toString() ??
              'If that number can receive SMS, a code is on its way.',
        );
      }
      throw PhoneSignInException(
        data['message']?.toString() ?? 'Could not send a code. Please try again.',
        code: data['code']?.toString() ?? 'PHONE_SIGNIN_REQUEST_FAILED',
        statusCode: response.statusCode,
        retryAfterSeconds: _parseInt(data['retry_after']),
      );
    } on PhoneSignInException {
      rethrow;
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  /// Verify a code and establish the session.
  ///
  /// [phone] must be the SAME value returned by [requestCode]; sending a
  /// differently formatted number fails with NO_CODE.
  ///
  /// The token is persisted before this returns, so callers can make
  /// authenticated requests immediately afterwards.
  Future<PhoneSignInVerifyResult> verifyCode({
    required String phone,
    required String code,
    String? deviceName,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.phoneSignInVerify,
        data: {
          'phone': normalizePhoneToBackend(phone),
          'code': code.trim(),
          'app': app,
          if (deviceName != null && deviceName.trim().isNotEmpty)
            'device_name': deviceName.trim(),
        },
      );
      final data = _asMap(response.data);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token']?.toString();
        final userMap = data['user'];

        if (token == null || token.isEmpty || userMap is! Map) {
          throw PhoneSignInException(
            'Invalid sign-in response.',
            code: 'PHONE_SIGNIN_INVALID_RESPONSE',
            statusCode: response.statusCode,
          );
        }

        final user = UserModel.fromMap(Map<String, dynamic>.from(userMap));

        // Persist before returning: anything the caller does next will be an
        // authenticated request, and a session half-established is worse than
        // none at all. Uses the same storage path as password login, so the
        // rest of the app sees no difference in how the session arrived.
        await _auth.storeUserSession(user: user, token: token);

        return PhoneSignInVerifyResult(
          user: user,
          token: token,
          created: data['created'] == true,
          onboardingRequired: data['onboarding_required'] == true,
        );
      }

      throw PhoneSignInException(
        data['message']?.toString() ?? 'Could not sign you in. Please try again.',
        code: data['code']?.toString() ?? 'PHONE_SIGNIN_VERIFY_FAILED',
        statusCode: response.statusCode,
        retryAfterSeconds: _parseInt(data['retry_after']),
      );
    } on PhoneSignInException {
      rethrow;
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  // ------------------------------------------------------------------ parts

  PhoneSignInException _fromApiException(ApiException e) {
    final data = _asMap(e.data);
    return PhoneSignInException(
      data['message']?.toString() ?? e.message,
      code: data['code']?.toString() ?? e.code ?? 'PHONE_SIGNIN_FAILED',
      statusCode: e.statusCode,
      retryAfterSeconds:
          _parseInt(data['retry_after']) ?? _parseInt(e.retryAfter),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// `app` values the backend accepts. Not interchangeable: a code issued for
/// one is rejected by the other.
const String kPhoneSignInAppCustomer = 'customer';
const String kPhoneSignInAppRider = 'rider';
