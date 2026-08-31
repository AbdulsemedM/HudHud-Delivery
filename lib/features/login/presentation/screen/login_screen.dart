import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
