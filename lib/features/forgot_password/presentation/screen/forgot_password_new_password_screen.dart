import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/validation/password_validator.dart';
import 'package:hudhud_delivery/features/forgot_password/bloc/forgot_password_reset_cubit.dart';
import 'package:hudhud_delivery/features/forgot_password/data/repository/forgot_password_repository.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_ui.dart';

class ForgotPasswordNewPasswordScreen extends StatelessWidget {
  const ForgotPasswordNewPasswordScreen({
    super.key,
    required this.resetToken,
  });

  final String resetToken;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordResetCubit(
        ForgotPasswordRepository.createDefault(),
        resetToken: resetToken,
      ),
      child: const _ForgotPasswordNewPasswordView(),
    );
  }
}

class _ForgotPasswordNewPasswordView extends StatefulWidget {
  const _ForgotPasswordNewPasswordView();

  @override
  State<_ForgotPasswordNewPasswordView> createState() =>
      _ForgotPasswordNewPasswordViewState();
}

class _ForgotPasswordNewPasswordViewState
    extends State<_ForgotPasswordNewPasswordView> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<ForgotPasswordResetCubit>();
    final message = await cubit.submit(
      password: _passwordController.text,
      passwordConfirmation: _confirmController.text,
    );
    if (!mounted || message == null) return;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuthScreenColors.surfaceOf(ctx),
        icon: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.successColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.successColor,
            size: 40,
          ),
        ),
        title: Text(
          l10n.snackbarSuccessLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthScreenColors.textPrimaryOf(ctx),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message.isNotEmpty ? message : l10n.forgotPasswordSuccessMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthScreenColors.textSecondaryOf(ctx),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          AuthGradientButton(
            label: l10n.actionOk,
            showArrow: false,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthDarkScaffold(
      showBackButton: true,
      child: BlocConsumer<ForgotPasswordResetCubit, ForgotPasswordResetState>(
        listenWhen: (p, c) => p.error != c.error && c.error != null,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                AuthHeading(
                  icon: Icons.key_rounded,
                  indigoIcon: true,
                  title: l10n.forgotPasswordNewTitle,
                  subtitle: l10n.forgotPasswordNewSubtitle,
                ),
                const SizedBox(height: 28),
                AuthFieldLabel(l10n.labelPassword),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure1,
                  enabled: !state.loading,
                  style: TextStyle(
                    color: AuthScreenColors.textPrimaryOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: authFieldDecoration(
                    context,
                    hint: l10n.hintPassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 22,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: AuthScreenColors.textSecondaryOf(context),
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) => validatePasswordStrength(v, l10n),
                ),
                const SizedBox(height: 20),
                AuthFieldLabel(l10n.forgotPasswordLabelConfirmPassword),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure2,
                  enabled: !state.loading,
                  style: TextStyle(
                    color: AuthScreenColors.textPrimaryOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: authFieldDecoration(
                    context,
                    hint: l10n.forgotPasswordHintConfirmPassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 22,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: AuthScreenColors.textSecondaryOf(context),
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.validationConfirmPasswordRequired;
                    }
                    if (v != _passwordController.text) {
                      return l10n.validationPasswordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AuthGradientButton(
                  label: l10n.forgotPasswordSaveButton,
                  loading: state.loading,
                  onPressed: state.loading ? null : _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
