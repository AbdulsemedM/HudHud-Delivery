import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/auth_screen_presence.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_navigation.dart';
import 'package:hudhud_delivery/features/phone_signin/presentation/screen/phone_sign_in_screen.dart';

/// The first thing a signed-out customer sees: their phone number.
///
/// Sign-in here is passwordless — a number and a six-digit code — and that is
/// the path almost everyone should take. It needs no password to remember, it
/// creates the account when there isn't one, and the code now arrives by
/// Telegram as well as SMS, so a dead SMS gateway no longer closes the app.
///
/// Password sign-in is still here, one tap away. Removing it would lock out
/// anyone whose number has changed, anyone who cannot receive a code, and the
/// staff accounts that sign in with an email — and it would do so silently,
/// at the moment they most need in. A link costs one tap; no route costs a
/// support call.
class AuthEntryScreen extends StatefulWidget {
  const AuthEntryScreen({super.key, this.resumeAfterAuth = false});

  /// When true, a successful sign-in pops `true` back to whatever asked for
  /// it (checkout, wishlist) rather than opening the dashboard.
  final bool resumeAfterAuth;

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  bool get resumeAfterAuth => widget.resumeAfterAuth;

  // A 401 pushes the customer back here. Registering while this screen is
  // mounted is what stops a stale token stacking one sign-in screen per
  // failed request.
  @override
  void initState() {
    super.initState();
    authScreenMounted();
  }

  @override
  void dispose() {
    authScreenUnmounted();
    super.dispose();
  }

  Future<void> _usePassword(BuildContext context) async {
    final resumed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LoginScreen(resumeAfterAuth: resumeAfterAuth),
      ),
    );

    if (resumeAfterAuth && resumed == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  /// Back on the root screen: confirm before leaving the app, which is
  /// what this app has always done — the confirmation followed the root
  /// here when the password screen stopped being it.
  Future<bool> _confirmExit(BuildContext context) async {
    final l10n = context.l10n;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AuthScreenColors.surfaceOf(dialogContext),
        title: Text(
          l10n.exitAppTitle,
          style:
              TextStyle(color: AuthScreenColors.textPrimaryOf(dialogContext)),
        ),
        content: Text(
          l10n.exitAppMessage,
          style:
              TextStyle(color: AuthScreenColors.textSecondaryOf(dialogContext)),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.actionCancel,
              style: TextStyle(
                  color: AuthScreenColors.textSecondaryOf(dialogContext)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthScreenColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(l10n.actionExit),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: resumeAfterAuth,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmExit(context);
      },
      child: PhoneSignInScreen(
      // The number was just proved by a code, so asking the customer to verify
      // the phone they signed in with would be the same check twice.
      onSignedIn: (_) async {
        if (!context.mounted) return;
        if (resumeAfterAuth) {
          Navigator.of(context).pop(true);
          return;
        }
        await navigateAfterAuthenticatedLogin(
          context,
          phoneEnrollmentRequired: false,
          resumeAfterAuth: false,
        );
      },
        footer: _PasswordLink(onPressed: () => _usePassword(context)),
      ),
    );
  }
}

class _PasswordLink extends StatelessWidget {
  const _PasswordLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AuthScreenColors.orange,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(context.l10n.signInWithPassword),
      ),
    );
  }
}
