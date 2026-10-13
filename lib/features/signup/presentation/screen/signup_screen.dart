import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/features/login/data/repository/login_repository.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_brand_header.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_ui.dart';
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
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
        child: AuthDarkScaffold(
          showBackButton: true,
          child: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandHeader(height: 36),
                  const SizedBox(height: 24),
                  const SignupTitle(),
                  const SizedBox(height: 28),
                  createSignupForm(),
                  const SizedBox(height: 28),
                  SignupButton(resumeAfterAuth: widget.resumeAfterAuth),
                  const SizedBox(height: 16),
                  _SignInPrompt(
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (defaultTargetPlatform != TargetPlatform.iOS) ...[
                    const SizedBox(height: 24),
                    AuthOrDivider(label: l10n.loginOrContinueWith),
                    const SizedBox(height: 16),
                    const _GoogleSignInButton(),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AuthScreenColors.textSecondaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(text: l10n.alreadyHaveAccount),
                    TextSpan(
                      text: l10n.loginTitle,
                      style: const TextStyle(
                        color: AuthScreenColors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
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
          height: 56,
          child: OutlinedButton(
            onPressed: state.isAnyLoginLoading
                ? null
                : () => context.read<LoginBloc>().add(GoogleLoginRequested()),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AuthScreenColors.surfaceBorderOf(context),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
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
                        width: 22,
                        height: 22,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
