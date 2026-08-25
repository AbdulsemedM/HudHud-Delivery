import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_phone_number_field.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/terms_conditions_screen.dart';
import 'package:hudhud_delivery/features/signup/bloc/signup_bloc.dart';
import 'package:hudhud_delivery/features/signup/presentation/screen/verify_contact_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class SignupTitle extends StatelessWidget {
  const SignupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.signupTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AuthScreenColors.textPrimaryOf(context),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.signupSubtitle,
          style: TextStyle(
            color: AuthScreenColors.textSecondaryOf(context),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => SignupFormState();
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
  final String? referralCode;

  SignupFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
    this.referralCode,
  });
}

final GlobalKey<SignupFormState> signupFormKey = GlobalKey<SignupFormState>();

class SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _dataProtectionAccepted = false;
  String _dialCode = kDefaultPhoneDialCode;
  String _countryIso = 'ET';
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openTerms;
    _privacyTap = TapGestureRecognizer()..onTap = _openTerms;
  }

  SignupFormData getFormData() {
    final referral = _referralController.text.trim();
    return SignupFormData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
      phoneNumber: normalizePhoneToBackend(
        '$_dialCode${cleanNationalPhoneDigits(_phoneController.text)}',
      ),
      referralCode: referral.isEmpty ? null : referral,
    );
  }

  bool isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  bool areCheckboxesAccepted() {
    return _termsAccepted && _dataProtectionAccepted;
  }

  int _passwordStrengthScore(String password) {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 6) score++;
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'))) {
      score++;
    }
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;/]'))) {
      score++;
    }
    return score.clamp(0, 4);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: AuthScreenColors.textSecondaryOf(context),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TermsConditionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final checkboxStyle = TextStyle(
      color: AuthScreenColors.textMutedOf(context),
      fontSize: 13,
      height: 1.4,
    );
    const linkStyle = TextStyle(
      color: AuthScreenColors.orange,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 1.4,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(l10n.firstName),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        color: AuthScreenColors.textPrimaryOf(context),
                        fontSize: 15,
                      ),
                      decoration: authFieldDecoration(context, hint: l10n.hintFirstName),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(l10n.lastName),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        color: AuthScreenColors.textPrimaryOf(context),
                        fontSize: 15,
                      ),
                      decoration: authFieldDecoration(context, hint: l10n.hintLastName),
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
          const SizedBox(height: 16),
          _buildLabel(l10n.emailAddress),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(
              color: AuthScreenColors.textPrimaryOf(context),
              fontSize: 15,
            ),
            decoration: authFieldDecoration(
              context,
              hint: l10n.hintEmailExample,
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: AuthScreenColors.textSecondaryOf(context),
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationEmailRequired;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return l10n.validationEmailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel(l10n.phoneNumber),
          const SizedBox(height: 6),
          AuthPhoneNumberField(
            countryCode: _dialCode,
            countryIsoCode: _countryIso,
            numberController: _phoneController,
            hintText: l10n.hintPhoneNational,
            onCountryChanged: (Country country) {
              setState(() {
                _dialCode = '+${country.phoneCode}';
                _countryIso = country.countryCode;
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationPhoneRequired;
              }
              final digits = cleanNationalPhoneDigits(value);
              if (digits.length < 8 || digits.length > 12) {
                return l10n.validationPhoneInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel(l10n.referralCodeOptional),
          const SizedBox(height: 6),
          TextFormField(
            controller: _referralController,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              color: AuthScreenColors.textPrimaryOf(context),
              fontSize: 15,
            ),
            decoration: authFieldDecoration(context, hint: l10n.hintReferralCode),
          ),
          const SizedBox(height: 16),
          _buildLabel(l10n.labelPassword),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: AuthScreenColors.textPrimaryOf(context),
              fontSize: 15,
            ),
            decoration: authFieldDecoration(
              context,
              hint: l10n.hintCreatePassword,
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: AuthScreenColors.textSecondaryOf(context),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AuthScreenColors.textSecondaryOf(context),
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationPasswordRequired;
              }
              if (value.length < 6) {
                return l10n.validationPasswordMin;
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          _PasswordStrengthMeter(
            score: _passwordStrengthScore(_passwordController.text),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.passwordStrengthHint,
            style: TextStyle(
              color: AuthScreenColors.textSecondaryOf(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel(l10n.confirmNewPassword),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: TextStyle(
              color: AuthScreenColors.textPrimaryOf(context),
              fontSize: 15,
            ),
            decoration: authFieldDecoration(
              context,
              hint: l10n.hintReenterPassword,
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: AuthScreenColors.textSecondaryOf(context),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AuthScreenColors.textSecondaryOf(context),
                ),
                onPressed: () {
                  setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  );
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationPasswordRequired;
              }
              if (value != _passwordController.text) {
                return l10n.validationPasswordsDoNotMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _SignupCheckboxRow(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() => _termsAccepted = value ?? false);
            },
            child: Text.rich(
              TextSpan(
                style: checkboxStyle,
                children: [
                  TextSpan(text: l10n.signupAcceptTermsPrefix),
                  TextSpan(
                    text: l10n.signupTermsLink,
                    style: linkStyle,
                    recognizer: _termsTap,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SignupCheckboxRow(
            value: _dataProtectionAccepted,
            onChanged: (value) {
              setState(() => _dataProtectionAccepted = value ?? false);
            },
            child: Text.rich(
              TextSpan(
                style: checkboxStyle,
                children: [
                  TextSpan(text: l10n.signupConsentDataPrefix),
                  TextSpan(
                    text: l10n.signupDataProtectionLink,
                    style: linkStyle,
                    recognizer: _privacyTap,
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

class _PasswordStrengthMeter extends StatelessWidget {
  const _PasswordStrengthMeter({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final filled = index < score;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            decoration: BoxDecoration(
              color: filled
                  ? AuthScreenColors.lavender
                  : AuthScreenColors.surfaceBorderOf(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
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
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AuthScreenColors.orange,
            checkColor: Colors.black,
            side: BorderSide(
              color: AuthScreenColors.textSecondaryOf(context),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class SignupButton extends StatelessWidget {
  final bool resumeAfterAuth;

  const SignupButton({super.key, this.resumeAfterAuth = false});

  void _handleSignup(BuildContext context, AppLocalizations l10n) {
    final formState = signupFormKey.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.signupFormIncomplete),
          backgroundColor: AuthScreenColors.orange,
        ),
      );
      return;
    }

    if (!formState.isFormValid()) {
      return;
    }

    if (!formState.areCheckboxesAccepted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.signupAcceptLegalRequired),
          backgroundColor: AuthScreenColors.orange,
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

    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          if (resumeAfterAuth) {
            Navigator.push<bool>(
              context,
              MaterialPageRoute<bool>(
                builder: (context) => const VerifyContactScreen(
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
              backgroundColor: const Color(0xFFEF5350),
            ),
          );
        }
      },
      child: BlocBuilder<SignupBloc, SignupState>(
        builder: (context, state) {
          final isLoading = state is SignupLoading;
          return AuthGradientButton(
            label: l10n.createAccount,
            loading: isLoading,
            onPressed: isLoading ? null : () => _handleSignup(context, l10n),
          );
        },
      ),
    );
  }
}
