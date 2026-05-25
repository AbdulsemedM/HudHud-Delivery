import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';

import '../../../signup/presentation/screen/signup_screen.dart';
import '../widgets/login_hero_background.dart';
import '../widgets/login_widget.dart';
import '../../bloc/login_bloc.dart';
import '../../data/repository/login_repository.dart';
import '../../data/data_provider/login_data_provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';

/// True while a [LoginScreen] is in the widget tree (used to avoid 401 re-push loops).
bool loginScreenIsActive = false;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
    final theme = Theme.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exitAppTitle),
        content: Text(l10n.exitAppMessage),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.actionCancel,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.actionExit,
              style: const TextStyle(color: Colors.white),
            ),
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

  LinearGradient _loginBackgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.darkBackground,
          Color.lerp(
                AppColors.primaryDarkColor,
                AppColors.darkBackground,
                0.55,
              ) ??
              AppColors.primaryDarkColor,
          Color.lerp(
                AppColors.secondaryDarkColor,
                AppColors.darkSurface,
                0.35,
              ) ??
              AppColors.secondaryDarkColor,
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primaryLightColor.withValues(alpha: 0.45),
        AppColors.primaryColor.withValues(alpha: 0.92),
        AppColors.secondaryLightColor.withValues(alpha: 0.88),
      ],
    );
  }

  void _openSignup(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const SignupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _loginBloc,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            await _onWillPop();
          }
        },
        child: Builder(
          builder: (context) {
            final l10n = context.l10n;
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            return BlocListener<LoginBloc, LoginState>(
              listenWhen: (previous, current) =>
                  current is LoginSuccess || current is LoginFailure,
              listener: (context, state) {
                if (state is LoginSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
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
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _loginBackgroundGradient(context),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Positioned.fill(
                        child: ExcludeSemantics(
                          child: LoginHeroBlobs(),
                        ),
                      ),
                      Positioned.fill(
                        child: SafeArea(
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 22,
                                sigmaY: 22,
                              ),
                              child: ColoredBox(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.black.withValues(alpha: 0.32)
                                    : Colors.white.withValues(alpha: 0.22),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(22, 8, 22, 28),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                          start: 2,
                                          top: 4,
                                          bottom: 4,
                                          end: 4,
                                        ),
                                        child: Align(
                                          alignment: AlignmentDirectional
                                              .centerStart,
                                          child: _GlassBackButton(
                                            onPressed: () => _onWillPop(),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          top: 8,
                                          bottom: 12,
                                        ),
                                        child: Center(
                                          child: _LoginScreenTopBadge(),
                                        ),
                                      ),
                                      const LoginTitle(),
                                      const SizedBox(height: 20),
                                      const LoginForm(),
                                      const SizedBox(height: 16),
                                      _SignUpPrompt(
                                        onPressed: () =>
                                            _openSignup(context),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: Colors.white.withValues(
                                                alpha: theme.brightness ==
                                                        Brightness.dark
                                                    ? 0.22
                                                    : 0.5,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              l10n.loginOrContinueWith,
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.85),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: Colors.white.withValues(
                                                alpha: theme.brightness ==
                                                        Brightness.dark
                                                    ? 0.22
                                                    : 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const _GoogleSignInButton(
                                        isOnGradientGlass: true,
                                      ),
                                      const SizedBox(height: 8),
                                      const _GuestLoginButton(),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Centered logo image (no chip / extra background).
class _LoginScreenTopBadge extends StatelessWidget {
  const _LoginScreenTopBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: l10n.appTitle,
      child: Image.asset(
        'assets/images/logo.png',
        width: 96,
        height: 96,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Icon(
          Icons.local_shipping_rounded,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.22),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back,
                color: colorScheme.brightness == Brightness.dark
                    ? colorScheme.onSurface
                    : Colors.white,
                size: 22,
              ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.35,
            ),
            children: [
              TextSpan(text: l10n.loginNoAccountPrompt),
              TextSpan(
                text: l10n.actionSignUp,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
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

class _GuestLoginButton extends StatelessWidget {
  const _GuestLoginButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          final loading = state is LoginLoading;
          return TextButton(
            onPressed: loading
                ? null
                : () =>
                    context.read<LoginBloc>().add(GuestLoginRequested()),
            child: loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : Text(
                    l10n.loginContinueAsGuest,
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({this.isOnGradientGlass = false});

  final bool isOnGradientGlass;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final glassBg = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final loading = state is LoginLoading;
        return Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: OutlinedButton(
            onPressed: loading
                ? null
                : () =>
                    context.read<LoginBloc>().add(GoogleLoginRequested()),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.45),
                width: 1.25,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: isOnGradientGlass ? glassBg : colorScheme.surface,
            ),
            child: loading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
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
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.continueWithGoogle,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 16,
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
