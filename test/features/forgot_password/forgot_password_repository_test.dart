import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/forgot_password/data/data_provider/forgot_password_data_source.dart';
import 'package:hudhud_delivery/features/forgot_password/data/repository/forgot_password_repository.dart';

class _FakeForgotPasswordDataSource implements ForgotPasswordDataSource {
  Map<String, dynamic>? requestResetOtpResponse;
  Map<String, dynamic>? verifyOtpResponse;
  Map<String, dynamic>? resendOtpResponse;
  Map<String, dynamic>? resetWithTokenResponse;

  String? lastMethod;
  String? lastIdentifier;

  @override
  Future<Map<String, dynamic>> requestResetOtp({
    required String identifier,
    required String method,
  }) async {
    lastIdentifier = identifier;
    lastMethod = method;
    return requestResetOtpResponse!;
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String resetId,
    required String otp,
  }) async =>
      verifyOtpResponse!;

  @override
  Future<Map<String, dynamic>> resendOtp({required String resetId}) async =>
      resendOtpResponse!;

  @override
  Future<Map<String, dynamic>> resetWithToken({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async =>
      resetWithTokenResponse!;
}

void main() {
  group('ForgotPasswordRepository.methodForIdentifier', () {
    test('email address returns email', () {
      expect(
        ForgotPasswordRepository.methodForIdentifier('user@example.com'),
        'email',
      );
    });

    test('phone number returns phone', () {
      expect(
        ForgotPasswordRepository.methodForIdentifier('+251911234567'),
        'phone',
      );
    });
  });

  group('ForgotPasswordRepository.requestResetOtp', () {
    late _FakeForgotPasswordDataSource fake;
    late ForgotPasswordRepository repository;

    setUp(() {
      fake = _FakeForgotPasswordDataSource();
      repository = ForgotPasswordRepository(fake);
    });

    test('parses reset_id and expires_in_minutes on 200', () async {
      fake.requestResetOtpResponse = {
        'statusCode': 200,
        'data': {
          'message': 'Password reset OTP sent successfully.',
          'reset_id': '9ccdecb5-56d0-48c9-8050-ec86dd8150ed',
          'expires_in_minutes': 15,
        },
        'errorMessage': null,
      };

      final result = await repository.requestResetOtp('user@example.com');

      expect(result.resetId, '9ccdecb5-56d0-48c9-8050-ec86dd8150ed');
      expect(result.expiresInMinutes, 15);
      expect(fake.lastMethod, 'email');
      expect(fake.lastIdentifier, 'user@example.com');
    });

    test('defaults expires_in_minutes to 15 when missing', () async {
      fake.requestResetOtpResponse = {
        'statusCode': 201,
        'data': {'reset_id': 'abc-123'},
        'errorMessage': null,
      };

      final result = await repository.requestResetOtp('user@example.com');

      expect(result.expiresInMinutes, 15);
    });

    test('throws on missing reset_id', () async {
      fake.requestResetOtpResponse = {
        'statusCode': 200,
        'data': {'message': 'ok'},
        'errorMessage': null,
      };

      expect(
        () => repository.requestResetOtp('user@example.com'),
        throwsA('Invalid server response'),
      );
    });

    test('throws with remaining_attempts on error', () async {
      fake.requestResetOtpResponse = {
        'statusCode': 422,
        'data': {'remaining_attempts': 2},
        'errorMessage': 'Invalid OTP',
      };

      expect(
        () => repository.requestResetOtp('user@example.com'),
        throwsA('Invalid OTP (2 attempts left)'),
      );
    });
  });

  group('ForgotPasswordRepository.verifyOtp', () {
    late _FakeForgotPasswordDataSource fake;
    late ForgotPasswordRepository repository;

    setUp(() {
      fake = _FakeForgotPasswordDataSource();
      repository = ForgotPasswordRepository(fake);
    });

    test('parses reset_token on 200', () async {
      fake.verifyOtpResponse = {
        'statusCode': 200,
        'data': {
          'message': 'OTP verified successfully.',
          'reset_token': 'token-abc',
          'expires_in_minutes': 60,
        },
        'errorMessage': null,
      };

      final result = await repository.verifyOtp(
        resetId: 'reset-id',
        otp: '846226',
      );

      expect(result.resetToken, 'token-abc');
      expect(result.expiresInMinutes, 60);
    });

    test('defaults expires_in_minutes to 60 when missing', () async {
      fake.verifyOtpResponse = {
        'statusCode': 200,
        'data': {'reset_token': 'token-abc'},
        'errorMessage': null,
      };

      final result = await repository.verifyOtp(
        resetId: 'reset-id',
        otp: '846226',
      );

      expect(result.expiresInMinutes, 60);
    });

    test('throws with locked_until on error', () async {
      fake.verifyOtpResponse = {
        'statusCode': 429,
        'data': {'locked_until': '2026-05-18T12:00:00Z'},
        'errorMessage': 'Too many attempts',
      };

      expect(
        () => repository.verifyOtp(resetId: 'id', otp: '000000'),
        throwsA(contains('Too many attempts')),
      );
    });
  });

  group('ForgotPasswordRepository.resetPassword', () {
    late _FakeForgotPasswordDataSource fake;
    late ForgotPasswordRepository repository;

    setUp(() {
      fake = _FakeForgotPasswordDataSource();
      repository = ForgotPasswordRepository(fake);
    });

    test('returns message from response on 200', () async {
      fake.resetWithTokenResponse = {
        'statusCode': 200,
        'data': {'message': 'Password has been reset successfully!'},
        'errorMessage': null,
      };

      final message = await repository.resetPassword(
        resetToken: 'token',
        password: '98899889bA!',
        passwordConfirmation: '98899889bA!',
      );

      expect(message, 'Password has been reset successfully!');
    });

    test('throws on non-2xx', () async {
      fake.resetWithTokenResponse = {
        'statusCode': 400,
        'data': null,
        'errorMessage': 'Token expired',
      };

      expect(
        () => repository.resetPassword(
          resetToken: 'token',
          password: 'pass',
          passwordConfirmation: 'pass',
        ),
        throwsA('Token expired'),
      );
    });
  });
}
