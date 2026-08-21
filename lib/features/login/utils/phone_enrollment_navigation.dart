import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/dashboard_navigation.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/addresses_list_screen.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/phone_enrollment_screen.dart';

/// Pull latest profile into [AuthService] so Home/Settings see it immediately.
Future<void> refreshSessionProfileAfterLogin() async {
  try {
    await AuthService().getUserProfile(forceRefresh: true);
  } catch (_) {
    // Keep cached session user; Home will still load from storage.
  }
}

/// After a successful Sanctum login, open enrollment or the normal app.
Future<void> navigateAfterAuthenticatedLogin(
  BuildContext context, {
  required bool phoneEnrollmentRequired,
  required bool resumeAfterAuth,
}) async {
  if (!context.mounted) return;

  if (phoneEnrollmentRequired) {
    if (resumeAfterAuth) {
      final enrolled = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const PhoneEnrollmentScreen(resumeAfterAuth: true),
        ),
      );
      if (!context.mounted) return;
      if (enrolled == true) {
        await refreshSessionProfileAfterLogin();
        if (!context.mounted) return;
        Navigator.of(context).pop(true);
        _refreshHomeIfDashboardAlive();
      }
      return;
    }

    await refreshSessionProfileAfterLogin();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PhoneEnrollmentScreen()),
      (route) => false,
    );
    return;
  }

  await refreshSessionProfileAfterLogin();
  if (!context.mounted) return;

  if (resumeAfterAuth) {
    Navigator.of(context).pop(true);
    _refreshHomeIfDashboardAlive();
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const DashboardScreen()),
    (route) => false,
  );
}

void _refreshHomeIfDashboardAlive() {
  DashboardNavigation.instance.goToHome(refreshHome: true);
  CourierHomeRefresh.instance.notifyRefresh();
  syncDefaultAddressFromApi();
}

/// Opens the enrollment gate (e.g. from home/courier when phone is empty).
Future<bool> openPhoneEnrollmentGate(
  BuildContext context, {
  bool resumeAfterAuth = true,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PhoneEnrollmentScreen(resumeAfterAuth: resumeAfterAuth),
    ),
  );
  if (result == true) {
    await refreshSessionProfileAfterLogin();
    _refreshHomeIfDashboardAlive();
  }
  return result == true;
}
