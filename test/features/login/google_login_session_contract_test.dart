import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/login_device_metadata.dart';
import 'package:hudhud_delivery/features/login/utils/google_login_session.dart';

void main() {
  group('ApiConstants.isUnauthenticatedAuthPath', () {
    test('recognizes session-creation and password-reset paths', () {
      expect(ApiConstants.isUnauthenticatedAuthPath('auth/google-login'), isTrue);
      expect(ApiConstants.isUnauthenticatedAuthPath('/api/auth/google-login'), isTrue);
      expect(
        ApiConstants.isUnauthenticatedAuthPath(
          'https://example.com/api/auth/google-login',
        ),
        isTrue,
      );
      expect(ApiConstants.isUnauthenticatedAuthPath('login'), isTrue);
      expect(ApiConstants.isUnauthenticatedAuthPath('register'), isTrue);
      expect(
        ApiConstants.isUnauthenticatedAuthPath('password/reset-otp'),
        isTrue,
      );
      expect(
        ApiConstants.isUnauthenticatedAuthPath('auth/google-login?x=1'),
        isTrue,
      );
    });

    test('rejects protected paths', () {
      expect(ApiConstants.isUnauthenticatedAuthPath('profile'), isFalse);
      expect(ApiConstants.isUnauthenticatedAuthPath('auth/logout'), isFalse);
      expect(ApiConstants.isUnauthenticatedAuthPath('auth/refresh'), isFalse);
      expect(ApiConstants.isUnauthenticatedAuthPath('auth/guest'), isFalse);
      expect(ApiConstants.isUnauthenticatedAuthPath(null), isFalse);
      expect(ApiConstants.isUnauthenticatedAuthPath(''), isFalse);
    });
  });

  group('unauthorizedErrorMessage', () {
    test('preserves API message for google-login 401', () {
      expect(
        unauthorizedErrorMessage(
          requestPath: 'auth/google-login',
          apiMessage: 'Google ID token is invalid.',
        ),
        'Google ID token is invalid.',
      );
      expect(
        unauthorizedErrorMessage(
          requestPath: 'auth/google-login',
          apiMessage: '',
        ),
        'Authentication failed. Please try again.',
      );
    });

    test('uses session-expired copy for protected endpoints', () {
      expect(
        unauthorizedErrorMessage(
          requestPath: 'profile',
          apiMessage: 'Unauthenticated.',
        ),
        'Your session has expired. Please login again.',
      );
    });
  });

  group('LoginDeviceMetadata.applyTo', () {
    test('writes contract device fields when present', () {
      const meta = LoginDeviceMetadata(
        fcmToken: 'fcm-abc',
        deviceType: 'android',
        deviceId: 'stable-id',
        appVersion: '1.0.0',
        osVersion: 'Android 15',
      );
      final body = <String, dynamic>{
        'id_token': 'jwt',
        'user_type': 'customer',
      };
      meta.applyTo(body);

      expect(body['id_token'], 'jwt');
      expect(body['user_type'], 'customer');
      expect(body['fcm_token'], 'fcm-abc');
      expect(body['device_type'], 'android');
      expect(body['device_id'], 'stable-id');
      expect(body['app_version'], '1.0.0');
      expect(body['os_version'], 'Android 15');
      expect(body.containsKey('device_token'), isFalse);
    });
  });

  group('normalizeGoogleLoginPayload', () {
    test('accepts flat successful session', () {
      final session = normalizeGoogleLoginPayload({
        'success': true,
        'message': 'Login successful!',
        'token': 'sanctum-token',
        'user': {'id': 1, 'email': 'a@b.com'},
      });
      expect(session['token'], 'sanctum-token');
      expect(session['user'], isA<Map>());
    });

    test('accepts nested data session', () {
      final session = normalizeGoogleLoginPayload({
        'success': true,
        'data': {
          'token': 'nested-token',
          'user': {'id': 2},
        },
      });
      expect(session['token'], 'nested-token');
    });

    test('rejects empty token and success false', () {
      expect(
        () => normalizeGoogleLoginPayload({
          'success': true,
          'token': '',
          'user': {'id': 1},
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => normalizeGoogleLoginPayload({
          'success': false,
          'message': 'Nope',
          'token': 'x',
          'user': {'id': 1},
        }),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', 'Nope'),
        ),
      );
    });
  });

  group('googleSignInFailureMessage', () {
    test('prefers API message over code fallbacks', () {
      expect(
        googleSignInFailureMessage(
          code: 'GOOGLE_ID_TOKEN_INVALID',
          apiMessage: 'Custom audience error from API',
        ),
        'Custom audience error from API',
      );
    });

    test('maps known Google codes when message is generic', () {
      expect(
        googleSignInFailureMessage(
          code: 'GOOGLE_IDENTITY_UNVERIFIED',
          apiMessage: 'Google sign-in failed.',
        ),
        'Please choose a verified Google account and try again.',
      );
      expect(
        googleSignInFailureMessage(
          code: 'GOOGLE_ID_TOKEN_INVALID',
          apiMessage: '',
        ),
        'Google sign-in expired. Please try again.',
      );
      expect(
        googleSignInFailureMessage(
          code: 'GOOGLE_LOGIN_TEMPORARILY_UNAVAILABLE',
          apiMessage: 'Google login failed',
        ),
        'Google sign-in is temporarily unavailable. Please try again.',
      );
    });
  });
}
