import 'dart:async';
import 'dart:io' show Platform;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/phone_sign_in_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_phone_number_field.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_ui.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:sms_autofill/sms_autofill.dart';

enum _SignInStep { phone, code }

/// Passwordless sign-in: enter phone → receive SMS code → verify.
///
/// [PhoneSignInService.verifyCode] stores the session before returning, so
/// [onSignedIn] only has to run the normal post-login navigation.
class PhoneSignInForm extends StatefulWidget {
  const PhoneSignInForm({super.key, required this.onSignedIn});

  final Future<void> Function(PhoneSignInVerifyResult result) onSignedIn;

  @override
  State<PhoneSignInForm> createState() => _PhoneSignInFormState();
}

class _PhoneSignInFormState extends State<PhoneSignInForm> {
  static const int _codeLength = 6;

  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _service = PhoneSignInService();

  _SignInStep _step = _SignInStep.phone;
  String _dialCode = kDefaultPhoneDialCode;
  String _countryIso = 'ET';

  /// Normalised phone returned by requestCode — verify must send the same value.
  String? _requestedPhone;
  bool _loading = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  StreamSubscription<String>? _smsSub;

  bool get _smsRetrieverSupported => !kIsWeb && Platform.isAndroid;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _smsSub?.cancel();
    if (_smsRetrieverSupported) {
      SmsAutoFill().unregisterListener();
    }
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    if (seconds <= 0) return;
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  /// Android SMS Retriever: fills the code automatically when the SMS ends
  /// with this app's hash. Silently does nothing if unavailable.
  Future<void> _listenForSmsCode() async {
    if (!_smsRetrieverSupported) return;
    await _smsSub?.cancel();
    try {
      await SmsAutoFill().listenForCode();
      _smsSub = SmsAutoFill().code.listen((code) {
        if (!mounted || code.isEmpty || _step != _SignInStep.code) return;
        _codeController.text = code;
        if (code.length == _codeLength && !_loading) _verify();
      });
    } catch (_) {
      // Manual entry still works.
    }
  }

  String _composedPhoneInput() {
    final national = cleanNationalPhoneDigits(_phoneController.text);
    return '$_dialCode$national';
  }

  String _messageFor(AppLocalizations l10n, PhoneSignInException e) {
    switch (e.code) {
      case 'CODE_INVALID':
        return l10n.phoneEnrollmentCodeInvalid;
      case 'CODE_EXPIRED':
      case 'NO_CODE':
        return l10n.phoneEnrollmentCodeExpired;
      case 'PHONE_NUMBER_INVALID':
        return l10n.phoneEnrollmentPhoneInvalid;
      default:
        if (e.statusCode == 429) return l10n.phoneEnrollmentRateLimited;
        return e.message.isNotEmpty
            ? e.message
            : l10n.phoneEnrollmentGenericError;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _requestCode() async {
    final l10n = context.l10n;
    if (_step == _SignInStep.phone &&
        !_phoneFormKey.currentState!.validate()) {
      return;
    }
    if (_loading || _resendSeconds > 0) return;

    setState(() => _loading = true);
    try {
      await _listenForSmsCode();
      final result = await _service.requestCode(_composedPhoneInput());
      if (!mounted) return;
      setState(() {
        _requestedPhone = result.phone;
        _step = _SignInStep.code;
        _codeController.clear();
        _loading = false;
      });
      _startResendCountdown(result.resendAfterSeconds);
    } on PhoneSignInException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final retry = e.retryAfterSeconds;
      if (retry != null && retry > 0) _startResendCountdown(retry);
      _showError(_messageFor(l10n, e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(l10n.phoneEnrollmentGenericError);
    }
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    final phone = _requestedPhone;
    if (phone == null) return;
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final result = await _service.verifyCode(
        phone: phone,
        code: _codeController.text.trim(),
        deviceName: 'hudhud-customer',
      );
      if (!mounted) return;
      await widget.onSignedIn(result);
      if (mounted) setState(() => _loading = false);
    } on PhoneSignInException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _codeController.clear();
      });
      // Anything but a wrong code (expired, no code, too many tries) needs a
      // fresh code: lift the resend wait so the user can request one now.
      if (!e.isRetryableOnCodeScreen &&
          (e.retryAfterSeconds == null || e.retryAfterSeconds! <= 0)) {
        _resendTimer?.cancel();
        setState(() => _resendSeconds = 0);
      }
      final retry = e.retryAfterSeconds;
      if (retry != null && retry > 0) _startResendCountdown(retry);
      _showError(_messageFor(l10n, e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(l10n.phoneEnrollmentGenericError);
    }
  }

  void _changeNumber() {
    setState(() {
      _step = _SignInStep.phone;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _step == _SignInStep.phone
          ? _buildPhoneStep(l10n)
          : _buildCodeStep(l10n),
    );
  }

  Widget _buildPhoneStep(AppLocalizations l10n) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        key: const ValueKey('phone-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFieldLabel(l10n.phoneNumber),
          AuthPhoneNumberField(
            countryCode: _dialCode,
            countryIsoCode: _countryIso,
            numberController: _phoneController,
            hintText: l10n.hintPhoneNational,
            enabled: !_loading,
            onCountryChanged: (Country country) {
              setState(() {
                _dialCode = '+${country.phoneCode}';
                _countryIso = country.countryCode;
              });
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.validationPhoneRequired;
              }
              final digits = cleanNationalPhoneDigits(v);
              if (digits.length < 8 || digits.length > 12) {
                return l10n.validationPhoneInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          AuthGradientButton(
            label: l10n.phoneEnrollmentSendCode,
            loading: _loading,
            onPressed: _loading || _resendSeconds > 0 ? null : _requestCode,
          ),
          if (_resendSeconds > 0) ...[
            const SizedBox(height: 14),
            Center(
              child: AuthPill(
                label: l10n.phoneEnrollmentResendIn(_resendSeconds),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeStep(AppLocalizations l10n) {
    final displayPhone = _requestedPhone ?? _composedPhoneInput();
    return Form(
      key: _codeFormKey,
      child: Column(
        key: const ValueKey('code-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.phoneEnrollmentOtpSubtitle(displayPhone),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AuthScreenColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          AuthFieldLabel(l10n.forgotPasswordOtpLabel),
          AuthCodeField(
            controller: _codeController,
            length: _codeLength,
            enabled: !_loading,
            validator: (v) {
              if ((v?.trim() ?? '').length != _codeLength) {
                return l10n.validationOtpLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AuthGradientButton(
            label: l10n.phoneEnrollmentVerify,
            loading: _loading,
            onPressed: _loading ? null : _verify,
          ),
          const SizedBox(height: 16),
          if (_resendSeconds > 0)
            Center(
              child: AuthPill(
                label: l10n.phoneEnrollmentResendIn(_resendSeconds),
              ),
            )
          else
            Center(
              child: TextButton.icon(
                onPressed: _loading ? null : _requestCode,
                style: _linkStyle(AuthScreenColors.orange),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(l10n.phoneEnrollmentResend),
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: _loading ? null : _changeNumber,
              style: _linkStyle(AuthScreenColors.textSecondaryOf(context)),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(l10n.phoneEnrollmentChangeNumber),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _linkStyle(Color color) => TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}
