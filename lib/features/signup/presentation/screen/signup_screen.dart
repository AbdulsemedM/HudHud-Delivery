import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../login/presentation/widgets/login_widget.dart';
import '../widgets/signup_widget.dart';
import '../../bloc/signup_bloc.dart';
import '../../data/repository/signup_repository.dart';
import '../../data/data_provider/signup_data_provider.dart';

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          // TODO: Implement Google Sign In
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: colorScheme.surface,
        ),
        child: Row(
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
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  final bool resumeAfterAuth;

  const SignupScreen({super.key, this.resumeAfterAuth = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupBloc(
        SignupRepository(
          SignupDataProvider(apiService: ApiService.instance),
        ),
      ),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;
          final screenHeight = MediaQuery.of(context).size.height;

          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Column(
              children: [
                SizedBox(
                  height: screenHeight * 0.28,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            left: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Center(child: LogoWidget()),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(24, 28, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SignupTitle(),
                              const SizedBox(height: AppColors.spaceLG),
                              createSignupForm(),
                              const SizedBox(height: AppColors.spaceMD),
                              SignupButton(resumeAfterAuth: widget.resumeAfterAuth),
                              const SizedBox(height: AppColors.spaceMD),
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    l10n.loginTitle,
                                    style: const TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppColors.spaceMD),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark
                                          ? const Color(0xFF2A2A2A)
                                          : const Color(0xFFEEEEEE),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      l10n.loginOrContinueWith,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark
                                          ? const Color(0xFF2A2A2A)
                                          : const Color(0xFFEEEEEE),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppColors.spaceMD),
                              const _GoogleSignInButton(),
                              const SizedBox(height: AppColors.spaceSM),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
