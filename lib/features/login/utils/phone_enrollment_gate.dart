import 'package:hudhud_delivery/models/user_model.dart';

/// Whether the authenticated user must complete phone enrollment before normal app use.
///
/// Prefer API [phone_enrollment_required] when present; fall back to empty phone or
/// missing [UserModel.phoneVerifiedAt] for older API releases.
bool needsPhoneEnrollment({
  Map<String, dynamic>? loginData,
  required UserModel user,
}) {
  if (loginData != null && loginData['phone_enrollment_required'] == true) {
    return true;
  }
  return userNeedsPhoneEnrollment(user);
}

/// Local/session check used on splash and feature gates.
bool userNeedsPhoneEnrollment(UserModel user) {
  final phone = user.phone;
  final phoneEmpty = phone == null || phone.trim().isEmpty;
  return phoneEmpty || user.phoneVerifiedAt == null;
}

/// Result of a successful credentials / Google login after session storage.
class LoginSessionResult {
  const LoginSessionResult({
    required this.user,
    required this.phoneEnrollmentRequired,
  });

  final UserModel user;
  final bool phoneEnrollmentRequired;
}
