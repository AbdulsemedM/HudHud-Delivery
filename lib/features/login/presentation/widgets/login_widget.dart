import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_identifier_screen.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_phone_number_field.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_method_tabs.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final logoColor = AuthScreenColors.textPrimaryOf(context);
    return Image.asset(
      'assets/images/logo.png',
      width: 140,
      fit: BoxFit.contain,
      color: logoColor,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.delivery_dining, color: logoColor, size: 72);
      },
    );
  }
}

class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AuthScreenColors.textPrimaryOf(context),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginSubtitle,
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
  final _biometricService = BiometricCredentialService();
  bool _isPasswordVisible = false;
  LoginMethod _method = LoginMethod.phone;
  String _dialCode = kDefaultPhoneDialCode;
  String _countryIso = 'ET';
  bool _showBiometric = false;
  bool _useFaceIcon = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refreshBiometricVisibility);
    _phoneController.addListener(_refreshBiometricVisibility);
    _loadBiometricAvailability();
  }

  Future<void> _loadBiometricAvailability() async {
    if (kIsWeb) return;
    final useFace = await _biometricService.prefersFaceIcon();
    if (!mounted) return;
    setState(() => _useFaceIcon = useFace);
    await _refreshBiometricVisibility();
  }

  Future<void> _refreshBiometricVisibility() async {
    if (kIsWeb) {
      if (_showBiometric && mounted) {
        setState(() => _showBiometric = false);
      }
      return;
    }

    final supported = await _biometricService.isDeviceSupported();
    final enabledSession = await _biometricService.hasEnabledSession();
    if (!supported || !enabledSession) {
      if (_showBiometric && mounted) {
        setState(() => _showBiometric = false);
      }
      return;
    }

    final attempted = _currentIdentifierOrEmpty();
    var matches = true;
    if (attempted.isNotEmpty) {
      matches = await _biometricService.matchesStoredLoginIdentifier(
        attempted,
        fieldType: _method == LoginMethod.email ? 'email' : 'phone',
      );
    }

    if (!mounted) return;
    if (_showBiometric != matches) {
      setState(() => _showBiometric = matches);
    }
  }

  String _currentIdentifierOrEmpty() {
    if (_method == LoginMethod.email) {
      return _emailController.text.trim();
    }
    final national = cleanNationalPhoneDigits(_phoneController.text);
    if (national.isEmpty) return '';
    return normalizePhoneToBackend('$_dialCode$national');
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

  void _onBiometricTap() {
    final l10n = context.l10n;
    context.read<LoginBloc>().add(
          BiometricLoginRequested(
            authReason: l10n.biometricAuthReason,
            noCredentialsMessage: l10n.biometricNoCredentials,
            authFailedMessage: l10n.biometricLoginFailed,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) => current is LoginFailure,
      listener: (context, state) {
        if (state is LoginFailure) {
          _loadBiometricAvailability();
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoginMethodTabs(
              selected: _method,
              authStyle: true,
              onChanged: (method) {
                setState(() => _method = method);
                _refreshBiometricVisibility();
              },
            ),
            const SizedBox(height: 20),
            if (_method == LoginMethod.phone)
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
                  _refreshBiometricVisibility();
                },
                validator: (v) => _validatePhone(v, l10n),
              )
            else ...[
              Text(
                l10n.labelEmail,
                style: TextStyle(
                  fontSize: 13,
                  color: AuthScreenColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                  hint: l10n.hintEmail,
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color: AuthScreenColors.textSecondaryOf(context),
                    size: 20,
                  ),
                ),
                validator: (v) => _validateEmail(v, l10n),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.labelPassword,
              style: TextStyle(
                fontSize: 13,
                color: AuthScreenColors.textSecondaryOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: TextStyle(
                color: AuthScreenColors.textPrimaryOf(context),
                fontSize: 15,
              ),
              decoration: authFieldDecoration(
                context,
                hint: l10n.hintPassword,
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
                if (value == null || value.isEmpty) {
                  return l10n.validationPasswordRequired;
                }
                if (value.length < 4) {
                  return l10n.validationPasswordMin;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ForgotPasswordIdentifierScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.forgotPasswordLink,
                  style: const TextStyle(
                    color: AuthScreenColors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                return AuthGradientButton(
                  label: l10n.loginTitle,
                  loading: state.isLoginLoading(LoginAction.credentials),
                  onPressed: state.isAnyLoginLoading ? null : _submitForm,
                );
              },
            ),
            if (_showBiometric) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AuthScreenColors.textSecondaryOf(context),
                      thickness: 0.6,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.loginBiometricOrDivider,
                      style: TextStyle(
                        color: AuthScreenColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AuthScreenColors.textSecondaryOf(context),
                      thickness: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  final loading = state.isLoginLoading(LoginAction.biometric);
                  return Center(
                    child: Semantics(
                      button: true,
                      label: l10n.loginBiometricButtonSemantics,
                      child: IconButton(
                        onPressed:
                            state.isAnyLoginLoading ? null : _onBiometricTap,
                        iconSize: 40,
                        color: AuthScreenColors.orange,
                        icon: loading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AuthScreenColors.orange,
                                ),
                              )
                            : Icon(
                                _useFaceIcon
                                    ? Icons.face_outlined
                                    : Icons.fingerprint_outlined,
                                size: 40,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

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
          ),
        );
  }

  @override
  void dispose() {
    _emailController.removeListener(_refreshBiometricVisibility);
    _phoneController.removeListener(_refreshBiometricVisibility);
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
