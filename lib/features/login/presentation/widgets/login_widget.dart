import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.26),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 60,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('assets/images/logo.png'),
      ),
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
          l10n.loginTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginSubtitle,
          style: TextStyle(
            fontSize: 13,
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

  /// Email or phone validation using [l10n] for error messages.
  String? _validateEmailOrPhone(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.validationEmailOrPhoneRequired;
    }

    final trimmedValue = value.trim();

    // Check if it's an email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (emailRegex.hasMatch(trimmedValue)) {
      return null; // Valid email
    }

    // Remove spaces, dashes, parentheses, and other formatting characters
    String cleanedPhone = trimmedValue.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    if (cleanedPhone.startsWith('+')) {
      if (RegExp(r'^\+[0-9]{10,15}$').hasMatch(cleanedPhone)) {
        return null; // Valid international phone
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
        return null; // Valid Ethiopian phone
      }

      if (cleanedPhone.length >= 10 && cleanedPhone.length <= 15) {
        return null; // Valid phone (generic)
      }
    }

    return l10n.validationEmailOrPhoneInvalid;
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
                // Email or Phone Input
                Text(
                  l10n.labelEmailOrPhone,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailPhoneController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: l10n.hintEmailPhone,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
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
                      borderSide:
                          BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  validator: (value) =>
                      _validateEmailOrPhone(value, l10n),
                ),
                const SizedBox(height: 16),
                // Password Input
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
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: l10n.hintPassword,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
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
                      borderSide:
                          BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            const SizedBox(height: 24),
            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is LoginLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: state is LoginLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l10n.loginTitle,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
      // Determine if it's email or phone
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final isEmail = emailRegex.hasMatch(emailOrPhone);

      context.read<LoginBloc>().add(
            LoginFormSubmitted(
              emailOrPhone,
              _passwordController.text.trim(),
              isEmail ? "email" : "phone",
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
