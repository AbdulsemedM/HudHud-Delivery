import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/features/login/data/repository/login_repository.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_brand_header.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_widget.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_navigation.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/features/signup/presentation/screen/signup_screen.dart';

/// True while a [LoginScreen] is in the widget tree (used to avoid 401 re-push loops).
bool loginScreenIsActive = false;

class LoginScreen extends StatefulWidget {
  /// When true, successful auth pops back to the caller instead of opening dashboard.
  final bool resumeAfterAuth;

  const LoginScreen({Key? key, this.resumeAfterAuth = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();
    loginScreenIsActive = true;
    _loginBloc = LoginBloc(
      LoginRepository(LoginDataProvider(apiService: ApiService.instance)),
    );
  }

  @override
  void dispose() {
    loginScreenIsActive = false;
    _loginBloc.close();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final l10n = context.l10n;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AuthScreenColors.surfaceOf(dialogContext),
        title: Text(
          l10n.exitAppTitle,
          style: TextStyle(color: AuthScreenColors.textPrimaryOf(dialogContext)),
        ),
        content: Text(
          l10n.exitAppMessage,
          style: TextStyle(color: AuthScreenColors.textSecondaryOf(dialogContext)),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.actionCancel,
              style: TextStyle(color: AuthScreenColors.textSecondaryOf(dialogContext)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthScreenColors.orange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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

  void _openSignup(BuildContext context) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => SignupScreen(
          resumeAfterAuth: widget.resumeAfterAuth,
        ),
      ),
    ).then((signupSucceeded) {
      if (!context.mounted) return;
      if (signupSucceeded == true && widget.resumeAfterAuth) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _maybeOfferBiometricOptIn() async {
    if (kIsWeb) return;
    final biometric = BiometricCredentialService();
    if (!await biometric.shouldOfferOptIn()) return;
    if (!mounted) return;

    final l10n = context.l10n;
    final enable = await AuthModal.dialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AuthAlertDialog(
          title: l10n.biometricOptInTitle,
          content: Text(
            l10n.biometricOptInMessage,
            style: TextStyle(
              color: AuthScreenColors.textSecondaryOf(dialogContext),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            AuthDialogAction(
              label: l10n.biometricOptInNotNow,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AuthDialogAction(
              label: l10n.biometricOptInEnable,
              filled: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (enable == true) {
      final authenticated = await biometric.authenticate(
        localizedReason: l10n.biometricAuthReason,
      );
      if (!authenticated) {
        await biometric.optOut();
        return;
      }
      final ok = await biometric.enableBiometricLogin();
      if (!ok && mounted) {
        AuthSnackBar.info(context, l10n.biometricNoCredentials);
      }
    } else {
      await biometric.optOut();
    }
  }

  Future<void> _navigateAfterSuccess({
    required bool phoneEnrollmentRequired,
  }) async {
    if (!mounted) return;
    await navigateAfterAuthenticatedLogin(
      context,
      phoneEnrollmentRequired: phoneEnrollmentRequired,
      resumeAfterAuth: widget.resumeAfterAuth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _loginBloc,
      child: PopScope(
        canPop: widget.resumeAfterAuth,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (widget.resumeAfterAuth) {
            Navigator.of(context).pop(false);
            return;
          }
          await _onWillPop();
        },
        child: BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) =>
              current is LoginSuccess || current is LoginFailure,
          listener: (context, state) async {
            if (state is LoginSuccess) {
              if (state.action == LoginAction.credentials) {
                await _maybeOfferBiometricOptIn();
              }
              await _navigateAfterSuccess(
                phoneEnrollmentRequired: state.phoneEnrollmentRequired,
              );
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: AuthDarkScaffold(
            showBackButton: widget.resumeAfterAuth,
            child: Builder(
              builder: (context) {
                final l10n = context.l10n;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const AuthBrandHeader(),
                    const SizedBox(height: 20),
                    const LoginTitle(),
                    const SizedBox(height: 24),
                    const LoginForm(),
                    const SizedBox(height: 20),
                    _SignUpPrompt(onPressed: () => _openSignup(context)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AuthScreenColors.textSecondaryOf(context),
                            thickness: 0.6,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.loginOrContinueWith,
                            style: TextStyle(
                              color: AuthScreenColors.textSecondaryOf(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AuthScreenColors.textSecondaryOf(context),
                            thickness: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (defaultTargetPlatform != TargetPlatform.iOS) ...[
                      const _GoogleSignInButton(),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = '${l10n.loginNoAccountPrompt}${l10n.actionSignUp}';
    return Semantics(
      label: label,
      button: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onPressed,
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              color: AuthScreenColors.textMutedOf(context),
              fontSize: 14,
              height: 1.35,
            ),
            children: [
              TextSpan(text: l10n.loginNoAccountPrompt),
              TextSpan(
                text: l10n.actionSignUp,
                style: const TextStyle(
                  color: AuthScreenColors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final loading = state.isLoginLoading(LoginAction.google);
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: state.isAnyLoginLoading
                ? null
                : () => context.read<LoginBloc>().add(GoogleLoginRequested()),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AuthScreenColors.surfaceBorderOf(context),
                width: 1.25,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: AuthScreenColors.surfaceOf(context),
            ),
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AuthScreenColors.orange,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Google_Favicon_2025.svg.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.g_mobiledata,
                            size: 22,
                            color: AuthScreenColors.textMutedOf(context),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.continueWithGoogle,
                        style: TextStyle(
                          color: AuthScreenColors.textPrimaryOf(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
