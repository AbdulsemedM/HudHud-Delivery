/// Abstraction for forgot-password API calls (enables testing).
abstract class ForgotPasswordDataSource {
  Future<Map<String, dynamic>> requestResetOtp({
    required String identifier,
    required String method,
  });

  Future<Map<String, dynamic>> verifyOtp({
    required String resetId,
    required String otp,
  });

  Future<Map<String, dynamic>> resendOtp({required String resetId});

  Future<Map<String, dynamic>> resetWithToken({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  });
}
