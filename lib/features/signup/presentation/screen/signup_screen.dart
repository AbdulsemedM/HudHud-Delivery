import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/features/login/data/repository/login_repository.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_navigation.dart';
import 'package:hudhud_delivery/features/signup/bloc/signup_bloc.dart';
import 'package:hudhud_delivery/features/signup/data/data_provider/signup_data_provider.dart';
import 'package:hudhud_delivery/features/signup/data/repository/signup_repository.dart';
import 'package:hudhud_delivery/features/signup/presentation/widgets/signup_widget.dart';

class SignupScreen extends StatefulWidget {
  final bool resumeAfterAuth;

  const SignupScreen({super.key, this.resumeAfterAuth = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final SignupBloc _signupBloc;
  late final LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();
    _signupBloc = SignupBloc(
      SignupRepository(
        SignupDataProvider(apiService: ApiService.instance),
      ),
    );
    _loginBloc = LoginBloc(
      LoginRepository(LoginDataProvider(apiService: ApiService.instance)),
    );
  }

  @override
  void dispose() {
    _signupBloc.close();
    _loginBloc.close();
    super.dispose();
  }

  Future<void> _onGoogleSuccess(
    BuildContext context, {
    required bool phoneEnrollmentRequired,
  }) async {
    await navigateAfterAuthenticatedLogin(
      context,
      phoneEnrollmentRequired: phoneEnrollmentRequired,
      resumeAfterAuth: widget.resumeAfterAuth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _signupBloc),
        BlocProvider.value(value: _loginBloc),
      ],
      child: BlocListener<LoginBloc, LoginState>(
        listenWhen: (previous, current) =>
            current is LoginSuccess || current is LoginFailure,
        listener: (context, state) {
          if (state is LoginSuccess) {
            _onGoogleSuccess(
              context,
              phoneEnrollmentRequired: state.phoneEnrollmentRequired,
            );
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: const Color(0xFFEF5350),
              ),
            );
          }
        },
        child: AuthDarkScaffold(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SignupTopBar(),
                  const SizedBox(height: 20),
                  const SignupTitle(),
                  const SizedBox(height: 24),
                  createSignupForm(),
                  const SizedBox(height: 24),
                  SignupButton(resumeAfterAuth: widget.resumeAfterAuth),
                  const SizedBox(height: 20),
                  _SignInPrompt(
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: AuthScreenColors.textSecondary,
                          thickness: 0.6,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.loginOrContinueWith,
                          style: const TextStyle(
                            color: AuthScreenColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: AuthScreenColors.textSecondary,
                          thickness: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _GoogleSignInButton(),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignupTopBar extends StatelessWidget {
  const _SignupTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AuthScreenColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.chevron_left_rounded,
                color: AuthScreenColors.textPrimary,
                size: 28,
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_shipping_rounded,
                size: 24,
                color: AuthScreenColors.orange,
              ),
            ),
            const SizedBox(width: 8),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hud',
                    style: TextStyle(
                      color: AuthScreenColors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  TextSpan(
                    text: 'Hud',
                    style: TextStyle(
                      color: AuthScreenColors.lavender,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onPressed,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            color: AuthScreenColors.textMuted,
            fontSize: 14,
            height: 1.35,
          ),
          children: [
            TextSpan(text: l10n.alreadyHaveAccount),
            TextSpan(
              text: l10n.loginTitle,
              style: const TextStyle(
                color: AuthScreenColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
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
              side: const BorderSide(
                color: AuthScreenColors.surfaceBorder,
                width: 1.25,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: AuthScreenColors.surface,
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
                          return const Icon(
                            Icons.g_mobiledata,
                            size: 22,
                            color: AuthScreenColors.textMuted,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.continueWithGoogle,
                        style: const TextStyle(
                          color: AuthScreenColors.textPrimary,
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
