import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: 140,
      fit: BoxFit.contain,
      color: Colors.white,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.delivery_dining, color: Colors.white, size: 72);
      },
    );
  }
}

class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppColors.spaceSM),
        Text(
          l10n.loginSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  String? _validateEmailOrPhone(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.validationEmailOrPhoneRequired;
    }

    final trimmedValue = value.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (emailRegex.hasMatch(trimmedValue)) {
      return null;
    }

    String cleanedPhone = trimmedValue.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    if (cleanedPhone.startsWith('+')) {
      if (RegExp(r'^\+[0-9]{10,15}$').hasMatch(cleanedPhone)) {
        return null;
      }
    } else {
      if (!RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
        return l10n.validationEmailOrPhoneInvalid;
      }

      if (cleanedPhone.startsWith('0') && cleanedPhone.length > 1) {
        cleanedPhone = cleanedPhone.substring(1);
      }

      if ((cleanedPhone.startsWith('9') || cleanedPhone.startsWith('7')) &&
          cleanedPhone.length == 9) {
        return null;
      }

      if (cleanedPhone.length >= 10 && cleanedPhone.length <= 15) {
        return null;
      }
    }

    return l10n.validationEmailOrPhoneInvalid;
  }

  InputDecoration _fieldDecoration({
    required ThemeData theme,
    required String hint,
    Widget? suffixIcon,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.labelEmailOrPhone,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppColors.spaceSM),
              TextFormField(
                controller: _emailPhoneController,
                keyboardType: TextInputType.text,
                decoration: _fieldDecoration(
                  theme: theme,
                  hint: l10n.hintEmailPhone,
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                validator: (value) => _validateEmailOrPhone(value, l10n),
              ),
              const SizedBox(height: AppColors.spaceMD),
              Text(
                l10n.labelPassword,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppColors.spaceSM),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _fieldDecoration(
                  theme: theme,
                  hint: l10n.hintPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.validationPasswordRequired;
                  }
                  if (value.length < 8) {
                    return l10n.validationPasswordMin;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppColors.spaceLG),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: state is LoginLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: state is LoginLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.loginTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final emailOrPhone = _emailPhoneController.text.trim();
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final isEmail = emailRegex.hasMatch(emailOrPhone);

      context.read<LoginBloc>().add(
            LoginFormSubmitted(
              emailOrPhone,
              _passwordController.text.trim(),
              isEmail ? 'email' : 'phone',
            ),
          );
    }
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
