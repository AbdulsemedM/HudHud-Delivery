import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Shows a sign-in dialog for guest browse mode.
/// Returns true if the user authenticated (including after resume login).
Future<bool> showGuestSignInRequiredDialog(
  BuildContext context, {
  String? title,
  String? message,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title ?? l10n.guestSignInRequiredTitle),
      content: Text(message ?? l10n.guestSignInRequiredMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.actionSignIn),
        ),
      ],
    ),
  );
  if (result != true || !context.mounted) return false;

  final loginSucceeded = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const LoginScreen(resumeAfterAuth: true),
    ),
  );
  if (loginSucceeded != true || !context.mounted) return false;

  return AuthService().isAuthenticated();
}

/// Returns true when the user may proceed with a backend call.
Future<bool> requireSignInForBackend(
  BuildContext context, {
  String? message,
}) async {
  if (!GuestBrowseService().isGuestBrowseMode) return true;
  return showGuestSignInRequiredDialog(
    context,
    message: message ?? AppLocalizations.of(context)!.guestServiceSignIn,
  );
}

bool isGuestBrowseActive() => GuestBrowseService().isGuestBrowseMode;
