import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../screen/verify_contact_screen.dart';
import '../../bloc/signup_bloc.dart';

class SignupTitle extends StatelessWidget {
  const SignupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actionSignUp,
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

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  _SignupFormState createState() => _SignupFormState();
}

Widget createSignupForm() {
  return SignupForm(key: signupFormKey);
}

class SignupFormData {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;

  SignupFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
  });
}

final GlobalKey<_SignupFormState> signupFormKey =
    GlobalKey<_SignupFormState>();

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _phoneNumber = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _dataProtectionAccepted = false;

  String? validateAndFormatPhoneNumber(String input) {
    input = input.trim().replaceAll(RegExp(r'\s+'), '');

    if (!RegExp(r'^\d+$').hasMatch(input)) {
      return null;
    }

    if (input.startsWith('0')) {
      input = input.substring(1);
    }

    if ((input.startsWith('9') || input.startsWith('7')) &&
        input.length == 9) {
      return input;
    }

    return null;
  }

  SignupFormData getFormData() {
    return SignupFormData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
      phoneNumber:
          _phoneNumber.isNotEmpty ? _phoneNumber : _phoneController.text.trim(),
    );
  }

  bool isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  bool areCheckboxesAccepted() {
    return _termsAccepted && _dataProtectionAccepted;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final checkboxBodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: 1.4,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context, l10n.firstName),
                    const SizedBox(height: AppColors.spaceSM),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _fieldDecoration(
                        theme: theme,
                        hint: l10n.hintFirstName,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterRecipientName;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppColors.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context, l10n.lastName),
                    const SizedBox(height: AppColors.spaceSM),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _fieldDecoration(
                        theme: theme,
                        hint: l10n.hintLastName,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterRecipientName;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          _buildLabel(context, l10n.emailAddress),
          const SizedBox(height: AppColors.spaceSM),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _fieldDecoration(
              theme: theme,
              hint: l10n.hintEmailExample,
            ),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationEmailRequired;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return l10n.validationEmailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: AppColors.spaceMD),
          _buildLabel(context, l10n.phoneNumber),
          const SizedBox(height: AppColors.spaceSM),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration(
              theme: theme,
              hint: l10n.hintPhoneExample,
            ),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            onChanged: (value) {
              _phoneNumber = value;
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.pleaseEnterRecipientPhone;
              }
              return null;
            },
          ),
          const SizedBox(height: AppColors.spaceMD),
          _buildLabel(context, l10n.labelPassword),
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
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationPasswordRequired;
              }
              if (value.length < 8) {
                return l10n.validationPasswordMin;
              }
              return null;
            },
          ),
          const SizedBox(height: AppColors.spaceMD),
          _buildLabel(context, l10n.confirmNewPassword),
          const SizedBox(height: AppColors.spaceSM),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: _fieldDecoration(
              theme: theme,
              hint: l10n.hintEnterPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationPasswordRequired;
              }
              if (value != _passwordController.text) {
                return l10n.validationPasswordRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: AppColors.spaceLG),
          _SignupCheckboxRow(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
            child: RichText(
              text: TextSpan(
                style: checkboxBodyStyle,
                children: [
                  TextSpan(text: '${l10n.actionAccept} '),
                  TextSpan(
                    text: l10n.settingsTermsConditions,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppColors.spaceSM),
          _SignupCheckboxRow(
            value: _dataProtectionAccepted,
            onChanged: (value) {
              setState(() {
                _dataProtectionAccepted = value ?? false;
              });
            },
            child: RichText(
              text: TextSpan(
                style: checkboxBodyStyle,
                children: [
                  TextSpan(text: '${l10n.actionAccept} '),
                  TextSpan(
                    text: l10n.verificationStatus,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupCheckboxRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget child;

  const _SignupCheckboxRow({
    required this.value,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: child,
          ),
        ),
      ],
    );
  }
}

class SignupButton extends StatelessWidget {
  const SignupButton({super.key});

  void _handleSignup(BuildContext context, AppLocalizations l10n) {
    final formState = signupFormKey.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationHandymanSelectLocation),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!formState.isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationHandymanSelectLocation),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!formState.areCheckboxesAccepted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentSelectMethodFirst),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final formData = formState.getFormData();

    context.read<SignupBloc>().add(
          SignupFormSubmitted(
            '${formData.firstName} ${formData.lastName}',
            formData.email,
            formData.phoneNumber,
            formData.password,
            formData.password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileRefreshed),
              backgroundColor: AppColors.successColor,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const VerifyContactScreen(),
            ),
            (route) => false,
          );
        } else if (state is SignupFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<SignupBloc, SignupState>(
        builder: (context, state) {
          final isLoading = state is SignupLoading;
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _handleSignup(context, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.actionSignUp,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
