import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/phone_enrollment_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/support_chat_start_screen.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_phone_number_field.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_navigation.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

enum _EnrollmentStep { phone, otp }

/// Mandatory authenticated phone enrollment + SMS OTP gate.
///
/// Does not clear the HudHud token on OTP/SMS failures. Sign-out is allowed.
class PhoneEnrollmentScreen extends StatefulWidget {
  const PhoneEnrollmentScreen({
    super.key,
    this.resumeAfterAuth = false,
  });

  /// When true, successful verification pops `true` instead of opening Dashboard.
  final bool resumeAfterAuth;

  @override
  State<PhoneEnrollmentScreen> createState() => _PhoneEnrollmentScreenState();
}

class _PhoneEnrollmentScreenState extends State<PhoneEnrollmentScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _enrollment = PhoneEnrollmentService();

  _EnrollmentStep _step = _EnrollmentStep.phone;
  String _countryCode = '+251';
  String _countryIso = 'ET';
  String? _canonicalPhone;
  bool _loading = false;
  bool _showDeliveryRetry = false;
  int _resendSeconds = 0;
  int _verifyLockSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _prefillFromSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromSession() async {
    final user = AuthService().currentUser ?? await AuthService().getStoredUser();
    final phone = user?.phone;
    if (phone == null || phone.trim().isEmpty) return;
    final parts = splitPhoneForDisplay(phone);
    if (!mounted) return;
    setState(() {
      _countryCode = parts.countryDialCode;
      _phoneController.text = parts.nationalNumber;
      _canonicalPhone = normalizePhoneToBackend(phone);
    });
  }

  void _startCountdown(int seconds, {required bool forResend}) {
    _countdownTimer?.cancel();
    setState(() {
      if (forResend) {
        _resendSeconds = seconds;
      } else {
        _verifyLockSeconds = seconds;
      }
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (forResend && _resendSeconds > 0) {
          _resendSeconds--;
        }
        if (!forResend && _verifyLockSeconds > 0) {
          _verifyLockSeconds--;
        }
        if (_resendSeconds <= 0 && _verifyLockSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  String _messageForError(AppLocalizations l10n, PhoneEnrollmentException e) {
    switch (e.code) {
      case 'PHONE_NUMBER_INVALID':
        return l10n.phoneEnrollmentPhoneInvalid;
      case 'PHONE_ALREADY_IN_USE':
        return l10n.phoneEnrollmentPhoneInUse;
      case 'PHONE_CHANGE_REQUIRES_SUPPORT':
        return l10n.phoneEnrollmentChangeRequiresSupport;
      case 'PHONE_ENROLLMENT_COOLDOWN':
        return l10n.phoneEnrollmentCooldown;
      case 'PHONE_ENROLLMENT_RATE_LIMITED':
      case 'PHONE_VERIFICATION_RATE_LIMITED':
        return l10n.phoneEnrollmentRateLimited;
      case 'PHONE_VERIFICATION_DELIVERY_RETRY_REQUIRED':
        return l10n.phoneEnrollmentDeliveryFailed;
      case 'PHONE_ENROLLMENT_NOT_PENDING':
        return l10n.phoneEnrollmentNotPending;
      case 'PHONE_VERIFICATION_CODE_EXPIRED':
        return l10n.phoneEnrollmentCodeExpired;
      case 'PHONE_VERIFICATION_CODE_INVALID':
        return l10n.phoneEnrollmentCodeInvalid;
      default:
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
        backgroundColor: AuthScreenColors.orange,
      ),
    );
  }

  String _composedPhoneInput() {
    final national = cleanNationalPhoneDigits(_phoneController.text);
    final dial = _countryCode.replaceAll(RegExp(r'\D'), '');
    return '$dial$national';
  }

  Future<void> _requestOtp({bool isResend = false}) async {
    final l10n = context.l10n;
    if (_step == _EnrollmentStep.phone) {
      if (!_phoneFormKey.currentState!.validate()) return;
    }
    if (_resendSeconds > 0 && isResend) return;

    setState(() {
      _loading = true;
      _showDeliveryRetry = false;
    });

    try {
      final input = _composedPhoneInput();
      final result = await _enrollment.requestOtp(input);
      if (!mounted) return;
      setState(() {
        _canonicalPhone = result.phone;
        _step = _EnrollmentStep.otp;
        _otpController.clear();
        _loading = false;
      });
      _startCountdown(result.resendAvailableInSeconds, forResend: true);
      if (result.message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } on PhoneEnrollmentException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showDeliveryRetry =
            e.code == 'PHONE_VERIFICATION_DELIVERY_RETRY_REQUIRED';
      });
      final retry = e.retryAfterSeconds;
      if (e.code == 'PHONE_ENROLLMENT_COOLDOWN' && retry != null && retry > 0) {
        _startCountdown(retry, forResend: true);
        setState(() => _step = _EnrollmentStep.otp);
      }
      if ((e.code == 'PHONE_ENROLLMENT_RATE_LIMITED' ||
              e.code == 'PHONE_VERIFICATION_RATE_LIMITED') &&
          retry != null &&
          retry > 0) {
        _startCountdown(retry, forResend: true);
      }
      if (e.code == 'PHONE_ENROLLMENT_NOT_PENDING' ||
          e.code == 'PHONE_VERIFICATION_CODE_EXPIRED') {
        setState(() => _step = _EnrollmentStep.phone);
      }
      if (e.code == 'PHONE_CHANGE_REQUIRES_SUPPORT') {
        _showError(_messageForError(l10n, e));
        return;
      }
      _showError(_messageForError(l10n, e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(l10n.phoneEnrollmentGenericError);
    }
  }

  Future<void> _verifyOtp() async {
    final l10n = context.l10n;
    if (!_otpFormKey.currentState!.validate()) return;
    if (_verifyLockSeconds > 0) return;

    setState(() => _loading = true);
    try {
      await _enrollment.verifyOtp(_otpController.text.trim());
      if (!mounted) return;
      await _finishSuccess();
    } on PhoneEnrollmentException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final retry = e.retryAfterSeconds;
      if (e.code == 'PHONE_VERIFICATION_RATE_LIMITED' &&
          retry != null &&
          retry > 0) {
        _startCountdown(retry, forResend: false);
      }
      if (e.code == 'PHONE_ENROLLMENT_NOT_PENDING' ||
          e.code == 'PHONE_VERIFICATION_CODE_EXPIRED') {
        setState(() => _step = _EnrollmentStep.phone);
      }
      _showError(_messageForError(l10n, e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(l10n.phoneEnrollmentGenericError);
    }
  }

  Future<void> _finishSuccess() async {
    await refreshSessionProfileAfterLogin();
    if (!mounted) return;
    if (widget.resumeAfterAuth) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _openSupport() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SupportChatStartScreen()),
    );
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final shouldLogout = await AuthModal.confirm(
      context: context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessage,
      confirmLabel: l10n.actionLogOut,
      cancelLabel: l10n.actionCancel,
      destructive: true,
    );
    if (shouldLogout != true || !mounted) return;

    try {
      await AuthService().logout();
      await GuestBrowseService().enterGuestBrowseMode();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AuthSnackBar.error(context, l10n.logoutError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onOtp = _step == _EnrollmentStep.otp;
    final displayPhone = _canonicalPhone ?? _composedPhoneInput();

    return PopScope(
      canPop: false,
      child: AuthDarkScaffold(
        showBackButton: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              onOtp ? l10n.phoneEnrollmentOtpTitle : l10n.phoneEnrollmentTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AuthScreenColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              onOtp
                  ? l10n.phoneEnrollmentOtpSubtitle(displayPhone)
                  : l10n.phoneEnrollmentSubtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AuthScreenColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            if (!onOtp) _buildPhoneStep(l10n) else _buildOtpStep(l10n),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loading ? null : _openSupport,
              child: Text(
                l10n.phoneEnrollmentContactSupport,
                style: const TextStyle(color: AuthScreenColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: _loading ? null : _signOut,
              child: Text(
                l10n.phoneEnrollmentSignOut,
                style: const TextStyle(color: AuthScreenColors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep(AppLocalizations l10n) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthPhoneNumberField(
            countryCode: _countryCode,
            countryIsoCode: _countryIso,
            numberController: _phoneController,
            enabled: !_loading,
            onCountryChanged: (Country c) {
              setState(() {
                _countryCode = '+${c.phoneCode}';
                _countryIso = c.countryCode;
              });
            },
            validator: (v) {
              final national = cleanNationalPhoneDigits(v);
              if (national.length < 9) {
                return l10n.phoneEnrollmentPhoneInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AuthGradientButton(
            label: _showDeliveryRetry
                ? l10n.phoneEnrollmentRetry
                : l10n.phoneEnrollmentSendCode,
            loading: _loading,
            onPressed: _loading || _resendSeconds > 0
                ? null
                : () => _requestOtp(),
          ),
          if (_resendSeconds > 0) ...[
            const SizedBox(height: 12),
            Text(
              l10n.phoneEnrollmentResendIn(_resendSeconds),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AuthScreenColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtpStep(AppLocalizations l10n) {
    final canResend = !_loading && _resendSeconds <= 0;
    final canVerify = !_loading && _verifyLockSeconds <= 0;

    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forgotPasswordOtpLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AuthScreenColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: canVerify,
            style: const TextStyle(
              color: AuthScreenColors.textPrimary,
              fontSize: 18,
              letterSpacing: 8,
              fontWeight: FontWeight.w600,
            ),
            decoration: authFieldDecoration().copyWith(counterText: ''),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.length != 6) return l10n.validationOtpLength;
              return null;
            },
          ),
          const SizedBox(height: 24),
          AuthGradientButton(
            label: l10n.phoneEnrollmentVerify,
            loading: _loading,
            onPressed: canVerify ? _verifyOtp : null,
          ),
          const SizedBox(height: 12),
          if (_showDeliveryRetry)
            TextButton(
              onPressed: _loading ? null : () => _requestOtp(isResend: true),
              child: Text(l10n.phoneEnrollmentRetry),
            )
          else
            TextButton(
              onPressed: canResend ? () => _requestOtp(isResend: true) : null,
              child: Text(
                _resendSeconds > 0
                    ? l10n.phoneEnrollmentResendIn(_resendSeconds)
                    : l10n.phoneEnrollmentResend,
                style: TextStyle(
                  color: canResend
                      ? AuthScreenColors.orange
                      : AuthScreenColors.textSecondary,
                ),
              ),
            ),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _step = _EnrollmentStep.phone;
                      _otpController.clear();
                    }),
            child: Text(
              l10n.phoneEnrollmentChangeNumber,
              style: const TextStyle(color: AuthScreenColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
