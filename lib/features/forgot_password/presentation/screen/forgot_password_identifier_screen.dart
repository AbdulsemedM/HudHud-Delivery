import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/validation/email_or_phone_validator.dart';
import 'package:hudhud_delivery/features/forgot_password/bloc/forgot_password_request_cubit.dart';
import 'package:hudhud_delivery/features/forgot_password/data/repository/forgot_password_repository.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_otp_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_brand_header.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_phone_number_field.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_method_tabs.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class ForgotPasswordIdentifierScreen extends StatelessWidget {
  const ForgotPasswordIdentifierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ForgotPasswordRequestCubit(ForgotPasswordRepository.createDefault()),
      child: const _ForgotPasswordIdentifierView(),
    );
  }
}

class _ForgotPasswordIdentifierView extends StatefulWidget {
  const _ForgotPasswordIdentifierView();

  @override
  State<_ForgotPasswordIdentifierView> createState() =>
      _ForgotPasswordIdentifierViewState();
}

class _ForgotPasswordIdentifierViewState
    extends State<_ForgotPasswordIdentifierView> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  LoginMethod _method = LoginMethod.phone;
  String _dialCode = kDefaultPhoneDialCode;
  String _countryIso = 'ET';

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _identifier() {
    if (_method == LoginMethod.email) {
      return _emailController.text.trim();
    }
    return normalizePhoneToBackend(
      '$_dialCode${cleanNationalPhoneDigits(_phoneController.text)}',
    );
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEmailRequired;
    }
    return validateEmailOrPhone(value, l10n);
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

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final identifier = _identifier();
    final cubit = context.read<ForgotPasswordRequestCubit>();
    final result = await cubit.submit(identifier);
    if (!mounted || result == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordOtpScreen(
          resetId: result.resetId,
          identifier: identifier,
          expiresInMinutes: result.expiresInMinutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthDarkScaffold(
      showBackButton: true,
      child: BlocConsumer<ForgotPasswordRequestCubit, ForgotPasswordRequestState>(
        listenWhen: (p, c) => p.error != c.error && c.error != null,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AuthScreenColors.orange,
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
                const AuthDashedCurve(),
                const SizedBox(height: 12),
                Text(
                  l10n.forgotPasswordRequestTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AuthScreenColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.forgotPasswordRequestSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AuthScreenColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                LoginMethodTabs(
                  selected: _method,
                  authStyle: true,
                  onChanged: (m) => setState(() => _method = m),
                ),
                const SizedBox(height: 20),
                if (_method == LoginMethod.phone)
                  AuthPhoneNumberField(
                    countryCode: _dialCode,
                    countryIsoCode: _countryIso,
                    numberController: _phoneController,
                    hintText: l10n.hintPhoneNational,
                    enabled: !state.loading,
                    onCountryChanged: (Country country) {
                      setState(() {
                        _dialCode = '+${country.phoneCode}';
                        _countryIso = country.countryCode;
                      });
                    },
                    validator: (v) => _validatePhone(v, l10n),
                  )
                else ...[
                  Text(
                    l10n.labelEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AuthScreenColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !state.loading,
                    style: const TextStyle(
                      color: AuthScreenColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: authFieldDecoration(
                      hint: l10n.hintEmail,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: AuthScreenColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    validator: (v) => _validateEmail(v, l10n),
                  ),
                ],
                const SizedBox(height: 28),
                AuthGradientButton(
                  label: l10n.forgotPasswordSendCode,
                  loading: state.loading,
                  onPressed: state.loading ? null : _onSubmit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
