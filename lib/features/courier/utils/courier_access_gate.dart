import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/widgets/verify_phone_dialog.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_navigation.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/models/user_model.dart';

/// Whether the user may start a new courier delivery.
bool canSendCourierPackage({required bool isGuest, UserModel? user}) =>
    !isGuest && user != null && user.isPhoneVerified;

Future<UserModel?> _loadCurrentUser() async {
  final auth = AuthService();
  final profile = await auth.getUserProfile(forceRefresh: true);
  return profile ?? await auth.getStoredUser();
}

Future<bool> _ensureSignedIn(BuildContext context) async {
  if (!GuestBrowseService().isGuestBrowseMode) {
    return AuthService().isAuthenticated();
  }

  final authed = await showGuestSignInRequiredDialog(
    context,
    message: context.l10n.courierSignInRequired,
  );
  if (!authed || !context.mounted) return false;
  return AuthService().isAuthenticated();
}

Future<bool> _ensurePhoneVerified(BuildContext context) async {
  final user = await _loadCurrentUser();
  if (!context.mounted) return false;

  if (canSendCourierPackage(
    isGuest: GuestBrowseService().isGuestBrowseMode,
    user: user,
  )) {
    return true;
  }

  final phone = user?.phone;
  if (phone == null || phone.isEmpty) {
    final enrolled = await openPhoneEnrollmentGate(context);
    if (!enrolled || !context.mounted) return false;
    final refreshedUser = await _loadCurrentUser();
    return canSendCourierPackage(
      isGuest: GuestBrowseService().isGuestBrowseMode,
      user: refreshedUser,
    );
  }

  final l10n = context.l10n;
  final shouldVerify = await AuthModal.confirm(
    context: context,
    title: l10n.verifyPhone,
    message: l10n.courierPhoneVerificationRequired,
    confirmLabel: l10n.verifyPhone,
  );
  if (shouldVerify != true || !context.mounted) return false;

  final verified = await showVerifyPhoneDialog(context, phone: phone);
  if (verified != true || !context.mounted) return false;

  final refreshedUser = await _loadCurrentUser();
  return canSendCourierPackage(
    isGuest: GuestBrowseService().isGuestBrowseMode,
    user: refreshedUser,
  );
}

/// Requires sign-in and a verified phone before entering send-package flows.
Future<bool> requireCourierSendAccess(BuildContext context) async {
  if (!await _ensureSignedIn(context)) return false;
  if (!context.mounted) return false;
  return _ensurePhoneVerified(context);
}
