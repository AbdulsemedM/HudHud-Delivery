import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/forgot_password/bloc/forgot_password_reset_cubit.dart';
import 'package:hudhud_delivery/features/forgot_password/data/repository/forgot_password_repository.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';

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
        title: Text(l10n.snackbarSuccessLabel),
        content: Text(message.isNotEmpty ? message : l10n.forgotPasswordSuccessMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionOk),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ForgotPasswordResetCubit, ForgotPasswordResetState>(
          listenWhen: (p, c) => p.error != c.error && c.error != null,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.forgotPasswordNewTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.forgotPasswordNewSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.labelPassword,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure1,
                      enabled: !state.loading,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure1 ? Icons.visibility : Icons.visibility_off,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              setState(() => _obscure1 = !_obscure1),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.validationPasswordRequired;
                        }
                        if (v.length < 8) {
                          return l10n.validationPasswordMin;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.forgotPasswordLabelConfirmPassword,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscure2,
                      enabled: !state.loading,
                      decoration: InputDecoration(
                        hintText: l10n.forgotPasswordHintConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure2 ? Icons.visibility : Icons.visibility_off,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              setState(() => _obscure2 = !_obscure2),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
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
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state.loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.forgotPasswordSaveButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
