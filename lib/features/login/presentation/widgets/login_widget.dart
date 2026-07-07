import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/validation/login_validators.dart';
import 'package:hudhud_delivery/core/widgets/phone_number_field.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_identifier_screen.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_method_tabs.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

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
            color: theme.colorScheme.shadow.withValues(alpha: 0.22),
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
    final headline = theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
          letterSpacing: 0.2,
        ) ??
        TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
          letterSpacing: 0.2,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.loginTitle,
          style: headline,
        ),
        // const SizedBox(height: 8),
        // Text(
        //   l10n.loginSubtitle,
        //   style: theme.textTheme.bodyMedium?.copyWith(
        //         color: theme.colorScheme.onSurfaceVariant,
        //         height: 1.45,
        //       ) ??
        //       TextStyle(
        //         fontSize: 14,
        //         color: theme.colorScheme.onSurfaceVariant,
        //         height: 1.45,
        //       ),
        // ),
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
  bool _isPasswordVisible = false;
  LoginMethod _method = LoginMethod.phone;
  String _countryCode = kDefaultPhoneDialCode;
  bool _showBiometricButton = false;
  bool _useFaceBiometricIcon = false;

  @override
  void initState() {
    super.initState();
    _refreshBiometricButton();
  }

  Future<void> _refreshBiometricButton() async {
    if (kIsWeb) return;
    final biometric = BiometricCredentialService();
    final hasCreds = await biometric.hasStoredCredentials();
    final types = await biometric.getAvailableBiometrics();
    if (!mounted) return;
    setState(() {
      _showBiometricButton = hasCreds;
      _useFaceBiometricIcon = types.contains(BiometricType.face) ||
          types.contains(BiometricType.strong);
    });
  }

  void _onBiometricTap(BuildContext context, AppLocalizations l10n) {
    context.read<LoginBloc>().add(
          BiometricLoginRequested(
            authReason: l10n.biometricAuthReason,
            noCredentialsMessage: l10n.biometricNoCredentials,
            authFailedMessage: l10n.biometricLoginFailed,
          ),
        );
  }

  Widget _buildBiometricLoginButton(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isLoading,
    bool isAnyLoading,
  ) {
    final primary = theme.brightness == Brightness.dark
        ? AppColors.primaryLightColor
        : AppColors.primaryColor;

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.loginBiometricOrDivider,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: l10n.loginBiometricButtonSemantics,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isAnyLoading ? null : () => _onBiometricTap(context, l10n),
              customBorder: const CircleBorder(),
              child: Ink(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface.withValues(alpha: 0.92),
                  border: Border.all(color: primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(22),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      )
                    : Icon(
                        _useFaceBiometricIcon
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                        size: 36,
                        color: primary,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    final fill = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFEBF2FA);

    return InputDecoration(
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintText: hintText,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
    );
  }

  // Widget _fieldLabel(BuildContext context, String text) {
  //   final theme = Theme.of(context);
  //   return Text(
  //     text,
  //     style: TextStyle(
  //       fontSize: 13,
  //       color: theme.colorScheme.onSurfaceVariant,
  //       fontWeight: FontWeight.w500,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          current is LoginFailure || current is LoginSuccess,
      listener: (context, state) {
        _refreshBiometricButton();
      },
      child: Form(
      key: _formKey,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoginMethodTabs(
                selected: _method,
                onChanged: (method) {
                  setState(() => _method = method);
                },
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _method == LoginMethod.email
                    ? _buildEmailPane(context, l10n, theme)
                    : _buildPhonePane(context, l10n, theme),
              ),
              const SizedBox(height: 16),
              // _fieldLabel(context, '${l10n.labelPassword}*'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _fieldDecoration(
                  context,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                  hintText: l10n.hintPassword,
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ForgotPasswordIdentifierScreen(),
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
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  if (_showBiometricButton && !kIsWeb) {
                    return _buildBiometricLoginButton(
                      context,
                      l10n,
                      theme,
                      state.isLoginLoading(LoginAction.biometric),
                      state.isAnyLoginLoading,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    final signInBackground =
                        theme.brightness == Brightness.dark
                            ? AppColors.primaryLightColor
                            : AppColors.primaryColor;
                    final isLoading =
                        state.isLoginLoading(LoginAction.credentials);
                    return ElevatedButton(
                      onPressed: state.isAnyLoginLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: signInBackground,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation:
                            theme.brightness == Brightness.dark ? 2 : 1,
                        shadowColor:
                            signInBackground.withValues(alpha: 0.35),
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
                              l10n.loginTitle,
                              style: const TextStyle(
                                color: Colors.white,
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
    ),
    );
  }

  Widget _buildEmailPane(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      key: const ValueKey('login_email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _fieldLabel(context, '${l10n.labelEmail}*'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: _fieldDecoration(
            context,
            prefixIcon: Icon(
              Icons.alternate_email_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            hintText: l10n.hintEmail,
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
          ),
          validator: (value) => validateLoginEmail(value, l10n),
        ),
      ],
    );
  }

  Widget _buildPhonePane(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      key: const ValueKey('login_phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _fieldLabel(context, '${l10n.labelPhone}*'),
        const SizedBox(height: 6),
        PhoneNumberField(
          countryCode: _countryCode,
          numberController: _phoneController,
          hintText: l10n.hintPhoneNational,
          validator: (value) => validateLoginPhoneNational(value, l10n),
          onCountryChanged: (Country country) {
            setState(() {
              _countryCode = '+${country.phoneCode}';
            });
          },
        ),
      ],
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();

    if (_method == LoginMethod.email) {
      context.read<LoginBloc>().add(
            LoginFormSubmitted(
              _emailController.text.trim(),
              password,
              'email',
            ),
          );
      return;
    }

    final normalized = normalizeLoginPhone(
      _countryCode,
      _phoneController.text,
    );
    context.read<LoginBloc>().add(
          LoginFormSubmitted(normalized, password, 'phone'),
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
