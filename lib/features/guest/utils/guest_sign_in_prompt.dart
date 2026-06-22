import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Shows a sign-in dialog for guest browse mode. Returns true if user chose to sign in.
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
  if (result == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return true;
  }
  return false;
}

bool isGuestBrowseActive() => GuestBrowseService().isGuestBrowseMode;
