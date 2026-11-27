import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/app_lock_service.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/auth_entry_screen.dart';

/// Covers the app with a lock screen while the optional app lock is on.
///
/// Locks on a cold start and after [AppLockService.relockAfter] in the
/// background, but only for a signed-in customer on a device that can still
/// authenticate: a phone whose fingerprint and PIN were removed is never
/// stranded behind a lock it cannot open.
///
/// An overlay rather than a route on purpose: the splash screen and sign-in
/// flows replace the whole navigation stack, which would silently drop a lock
/// route. The app underneath stays mounted (no lost state) but is hidden and
/// cannot be touched.
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final AppLockService _appLock = AppLockService();

  bool _locked = false;
  bool _authenticating = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockIfRequired();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The fingerprint / face prompt itself sends the app to the background
    // on some devices; that must not count as leaving the app.
    if (_authenticating || _appLock.isAuthenticating) return;

    if (state == AppLifecycleState.paused) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _backgroundedAt;
      _backgroundedAt = null;
      if (away != null &&
          DateTime.now().difference(away) >= AppLockService.relockAfter) {
        _lockIfRequired();
      }
    }
  }

  Future<bool> _lockApplies() async {
    if (!await _appLock.isEnabled()) return false;
    if (!await _appLock.isDeviceSupported()) return false;
    return AuthService().isAuthenticated();
  }

  Future<void> _lockIfRequired() async {
    if (_locked) return;
    if (!await _lockApplies() || !mounted) return;
    setState(() => _locked = true);
    // Wait for the lock screen to paint before the system prompt covers it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    final reason = context.l10n.appLockReason;
    setState(() => _authenticating = true);
    final ok = await _appLock.authenticate(reason: reason);
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) _locked = false;
    });
  }

  /// The escape hatch: whoever cannot unlock can still sign out and sign in
  /// again with their phone number.
  Future<void> _signOut() async {
    await AuthService().logout();
    if (!mounted) return;
    setState(() => _locked = false);
    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthEntryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    return Stack(
      children: [
        AbsorbPointer(child: ExcludeSemantics(child: widget.child)),
        Positioned.fill(
          child: _LockScreen(
            busy: _authenticating,
            onUnlock: _unlock,
            onSignOut: _signOut,
          ),
        ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.busy,
    required this.onUnlock,
    required this.onSignOut,
  });

  final bool busy;
  final VoidCallback onUnlock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                isDark
                    ? 'assets/images/logo_dark.png'
                    : 'assets/images/logo.png',
                width: 120,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.lock_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.fingerprint_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appLockUnlockTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: busy ? null : onUnlock,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(l10n.appLockUnlockButton),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : onSignOut,
                child: Text(l10n.appLockSignOut),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
