import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/app_lock_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_identifier_screen.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_phone_number_field.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_ui.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_method_tabs.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
      width: 140,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.delivery_dining,
          color: AuthScreenColors.textPrimaryOf(context),
          size: 72,
        );
      },
    );
  }
}

class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthHeading(
      title: l10n.welcomeTitle,
      subtitle: l10n.loginSubtitle,
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  LoginMethod _method = LoginMethod.phone;
  String _dialCode = kDefaultPhoneDialCode;
  String _countryIso = 'ET';
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  /// Remember-me pre-fills only the email / phone; the password is never
  /// stored.
  Future<void> _loadRememberedLogin() async {
    if (kIsWeb) return;
    final remembered = await AppLockService().readRememberedLogin();
    if (remembered == null || !mounted) return;

    if (remembered.fieldType == 'email') {
      setState(() {
        _rememberMe = true;
        _method = LoginMethod.email;
        _emailController.text = remembered.identifier;
      });
    } else {
      final parts = splitPhoneForDisplay(remembered.identifier);
      final country = _countryForDialCode(parts.countryDialCode);
      setState(() {
        _rememberMe = true;
        _method = LoginMethod.phone;
        _dialCode = parts.countryDialCode;
        _countryIso = country?.countryCode ?? 'ET';
        _phoneController.text = parts.nationalNumber;
      });
    }
  }

  Country? _countryForDialCode(String dialCode) {
    final digits = dialCode.replaceAll(RegExp(r'\D'), '');
    for (final country in CountryService().getAll()) {
      if (country.phoneCode == digits) return country;
    }
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.validationEmailInvalid;
    }
    return null;
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationPhoneRequired;
    }
    final digits = cleanNationalPhoneDigits(value);
    if (digits.length < 8 || digits.length > 12) {
      return l10n.validationPhoneInvalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoginMethodTabs(
            selected: _method,
            authStyle: true,
            onChanged: (method) {
              setState(() => _method = method);
            },
          ),
          const SizedBox(height: 24),
          if (_method == LoginMethod.phone) ...[
            AuthFieldLabel(l10n.phoneNumber),
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
              validator: (v) => _validatePhone(v, l10n),
            ),
          ] else ...[
            AuthFieldLabel(l10n.labelEmail),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: _fieldTextStyle(context),
              decoration: authFieldDecoration(
                context,
                hint: l10n.hintEmail,
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  size: 22,
                ),
              ),
              validator: (v) => _validateEmail(v, l10n),
            ),
          ],
          const SizedBox(height: 20),
          AuthFieldLabel(l10n.labelPassword),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: _fieldTextStyle(context),
            decoration: authFieldDecoration(
              context,
              hint: l10n.hintPassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 22,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.validationPasswordRequired;
              }
              if (value.length < 4) {
                return l10n.validationPasswordMin;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 2,
                        end: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              activeColor: AuthScreenColors.orange,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              side: BorderSide(
                                color: AuthScreenColors.textMutedOf(context),
                                width: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              l10n.loginRememberMe,
                              style: TextStyle(
                                color:
                                    AuthScreenColors.textSecondaryOf(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ForgotPasswordIdentifierScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AuthScreenColors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.forgotPasswordLink,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              return AuthGradientButton(
                label: l10n.loginTitle,
                loading: state.isLoginLoading(LoginAction.credentials),
                onPressed: state.isAnyLoginLoading ? null : _submitForm,
              );
            },
          ),
        ],
      ),
    );
  }

  TextStyle _fieldTextStyle(BuildContext context) => TextStyle(
        color: AuthScreenColors.textPrimaryOf(context),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final isEmail = _method == LoginMethod.email;
    final identifier = isEmail
        ? _emailController.text.trim()
        : normalizePhoneToBackend(
            '$_dialCode${cleanNationalPhoneDigits(_phoneController.text)}',
          );

    context.read<LoginBloc>().add(
          LoginFormSubmitted(
            identifier,
            _passwordController.text.trim(),
            isEmail ? 'email' : 'phone',
            rememberMe: _rememberMe,
          ),
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
