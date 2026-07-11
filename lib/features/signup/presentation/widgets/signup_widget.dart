import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/signup/bloc/signup_bloc.dart';
import 'package:hudhud_delivery/features/signup/presentation/screen/verify_contact_screen.dart';

class SignupTitle extends StatelessWidget {
  const SignupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actionSignUp,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.loginSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
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
  State<SignupForm> createState() => _SignupFormState();
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
  final String referralCode;

  SignupFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
    required this.referralCode,
  });
}

final GlobalKey<_SignupFormState> signupFormKey = GlobalKey<_SignupFormState>();

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralCodeController = TextEditingController();
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

    if ((input.startsWith('9') || input.startsWith('7')) && input.length == 9) {
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
      referralCode: _referralCodeController.text.trim(),
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
    _referralCodeController.dispose();
    super.dispose();
  }

  TextStyle _signupLabelStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 13,
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
  }

  InputDecoration _signupFieldDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.surfaceContainerHighest;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final iconMuted = theme.colorScheme.onSurfaceVariant;
    final checkboxBodyStyle = TextStyle(
      fontSize: 13,
      color: theme.colorScheme.onSurfaceVariant,
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
                    Text(l10n.firstName, style: _signupLabelStyle(context)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _signupFieldDecoration(
                        context,
                        hintText: l10n.hintFirstName,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.validationTitleRequired;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.lastName, style: _signupLabelStyle(context)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _signupFieldDecoration(
                        context,
                        hintText: l10n.hintLastName,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.validationTitleRequired;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.emailAddress, style: _signupLabelStyle(context)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _signupFieldDecoration(
              context,
              hintText: l10n.hintEmailExample,
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
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
          const SizedBox(height: 16),
          Text(l10n.phoneNumber, style: _signupLabelStyle(context)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _signupFieldDecoration(
              context,
              hintText: l10n.hintPhoneExample,
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
            onChanged: (value) {
              _phoneNumber = value;
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationPhoneRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(l10n.referralCode, style: _signupLabelStyle(context)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _referralCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: _signupFieldDecoration(
              context,
              hintText: l10n.verificationCodeHintExample,
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.labelPassword, style: _signupLabelStyle(context)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: _signupFieldDecoration(
              context,
              hintText: l10n.hintEnterPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: iconMuted,
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
              if (value == null || value.trim().isEmpty) {
                return l10n.validationPasswordRequired;
              }
              if (value.length < 8) {
                return l10n.validationPasswordMin;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.confirmNewPassword,
            style: _signupLabelStyle(context),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: _signupFieldDecoration(
              context,
              hintText: l10n.hintEnterPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: iconMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationConfirmPasswordRequired;
              }
              if (value != _passwordController.text) {
                return l10n.validationPasswordsDoNotMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.settingsTermsConditions,
                    style: checkboxBodyStyle.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _dataProtectionAccepted,
                onChanged: (value) {
                  setState(() {
                    _dataProtectionAccepted = value ?? false;
                  });
                },
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.accountVerificationPhoneSubtitle,
                    style: checkboxBodyStyle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SignupButton extends StatelessWidget {
  final bool resumeAfterAuth;

  const SignupButton({super.key, this.resumeAfterAuth = false});

  void _handleSignup(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formState = signupFormKey.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationEmailOrPhoneRequired),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (!formState.isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationEmailOrPhoneRequired),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (!formState.areCheckboxesAccepted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.accountVerificationBannerTitle),
          backgroundColor: theme.colorScheme.error,
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
            formData.referralCode,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          if (resumeAfterAuth) {
            Navigator.push<bool>(
              context,
              MaterialPageRoute<bool>(
                builder: (context) => VerifyContactScreen(
                  resumeAfterAuth: true,
                ),
              ),
            ).then((verified) {
              if (verified == true && context.mounted) {
                Navigator.pop(context, true);
              }
            });
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const VerifyContactScreen(),
              ),
              (route) => false,
            );
          }
        } else if (state is SignupFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<SignupBloc, SignupState>(
        builder: (context, state) {
          final isLoading = state is SignupLoading;
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryDarkColor,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleSignup(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
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
                          color: Colors.white,
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
