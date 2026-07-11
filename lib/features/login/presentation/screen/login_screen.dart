import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

import '../../../signup/presentation/screen/signup_screen.dart';
import '../widgets/login_hero_background.dart';
import '../widgets/login_widget.dart';
import '../../bloc/login_bloc.dart';
import '../../data/repository/login_repository.dart';
import '../../data/data_provider/login_data_provider.dart';
import '../../../../core/api/api_service.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';

/// True while a [LoginScreen] is in the widget tree (used to avoid 401 re-push loops).
bool loginScreenIsActive = false;

class LoginScreen extends StatefulWidget {
  /// When true, successful auth pops back to the caller instead of opening dashboard.
  final bool resumeAfterAuth;

  const LoginScreen({Key? key, this.resumeAfterAuth = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final LoginBloc _loginBloc;
  late final AnimationController _cardAnimController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    loginScreenIsActive = true;
    _loginBloc = LoginBloc(
      LoginRepository(LoginDataProvider(apiService: ApiService.instance)),
    );
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    );
    _cardAnimController.forward();
  }

  @override
  void dispose() {
    loginScreenIsActive = false;
    _cardAnimController.dispose();
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

  void _openSignup(BuildContext context) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => SignupScreen(
          resumeAfterAuth: widget.resumeAfterAuth,
        ),
      ),
    ).then((signupSucceeded) {
      if (signupSucceeded == true && mounted && widget.resumeAfterAuth) {
        Navigator.of(context).pop(true);
      }
    });
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
        child: Builder(
          builder: (context) {
            final l10n = context.l10n;
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final screenHeight = MediaQuery.of(context).size.height;
            final topHeight = screenHeight * 0.42;

            return BlocListener<LoginBloc, LoginState>(
              listenWhen: (previous, current) =>
                  current is LoginSuccess || current is LoginFailure,
              listener: (context, state) async {
                if (state is LoginSuccess) {
                  if (widget.resumeAfterAuth) {
                    final authed = await AuthService().isAuthenticated();
                    if (!context.mounted) return;
                    if (authed) {
                      Navigator.pop(context, true);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    }
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  }
                } else if (state is LoginFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              child: Scaffold(
                body: Column(
                  children: [
                    SizedBox(
                      height: topHeight,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.primaryDarkColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const LoginHeroBlobs(),
                            SafeArea(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: 120,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.local_shipping_rounded,
                                          size: 72,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.appTitle,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics:
                                          const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        28,
                                        24,
                                        16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            l10n.loginTitle,
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.loginSubtitle,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 13,
                                              color: isDark
                                                  ? AppColors.mutedDark
                                                  : AppColors.mutedLight,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          const LoginForm(),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: isDark
                                                      ? AppColors.borderDark
                                                      : AppColors.borderLight,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                ),
                                                child: Text(
                                                  l10n.loginOrContinueWith,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? AppColors.mutedDark
                                                        : AppColors.mutedLight,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: isDark
                                                      ? AppColors.borderDark
                                                      : AppColors.borderLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          const _GoogleSignInButton(),
                                          const SizedBox(height: 8),
                                          const _GuestLoginButton(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      0,
                                      24,
                                      16,
                                    ),
                                    child: _SignUpPrompt(
                                      onPressed: () => _openSignup(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
    final colorScheme = Theme.of(context).colorScheme;
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
    return Center(
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          final loading = state.isLoginLoading(LoginAction.guest);
          return TextButton(
            onPressed: state.isAnyLoginLoading
                ? null
                : () =>
                    context.read<LoginBloc>().add(GuestLoginRequested()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
            ),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  )
                : Text(
                    l10n.loginContinueAsGuest,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final loading = state.isLoginLoading(LoginAction.google);
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: state.isAnyLoginLoading
                ? null
                : () =>
                    context.read<LoginBloc>().add(GoogleLoginRequested()),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: theme.colorScheme.surface,
            ),
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
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
                            color: theme.colorScheme.onSurfaceVariant,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.continueWithGoogle,
                        style: TextStyle(
                          color: onSurface,
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
