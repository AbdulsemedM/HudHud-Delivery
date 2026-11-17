import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'package:hudhud_delivery/app/services/phone_sign_in_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';

/// Code entry for passwordless sign-in.
///
/// Deliberately self-contained: it takes the service and a callback rather than
/// reaching into the app's bloc or router, so wiring it is one Navigator call
/// and nothing here depends on how the surrounding app manages state.
///
/// A single centred field rather than six boxes, for three reasons:
///   - iOS offers the code through `autofillHints: [AutofillHints.oneTimeCode]`
///     on a text field; the app's existing OtpInputFields sets
///     `keyboardType: TextInputType.none` for its custom keypad, which would
///     stop the keyboard offering anything.
///   - six 66px boxes overflow a 360dp phone.
///   - sms_autofill fills a controller directly, so one field is all it needs.
class PhoneSignInCodeScreen extends StatefulWidget {
  const PhoneSignInCodeScreen({
    super.key,
    required this.phone,
    required this.onSignedIn,
    this.resendAfterSeconds = 60,
    this.service,
  });

  /// The NORMALISED number returned by requestCode. Sending a differently
  /// formatted value to verify fails with NO_CODE.
  final String phone;

  /// Called once the session is persisted. `created` is true when this phone
  /// had no account; the rider app additionally checks `onboardingRequired`.
  final void Function(PhoneSignInVerifyResult result) onSignedIn;

  /// From the request response — never hardcode 60, or the client and server
  /// can disagree about when a resend is allowed.
  final int resendAfterSeconds;

  final PhoneSignInService? service;

  @override
  State<PhoneSignInCodeScreen> createState() => _PhoneSignInCodeScreenState();
}

class _PhoneSignInCodeScreenState extends State<PhoneSignInCodeScreen>
    with CodeAutoFill {
  late final PhoneSignInService _service =
      widget.service ?? PhoneSignInService();

  final TextEditingController _controller = TextEditingController();

  bool _submitting = false;
  bool _resending = false;
  String? _error;
  int _secondsLeft = 0;
  Timer? _timer;

  static const int _codeLength = 6;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _startResendCountdown(widget.resendAfterSeconds);

    // Android SMS Retriever. Requires the 11-char app hash on the last line of
    // the SMS, which the backend adds from SMS_APP_HASH_CUSTOMER. If that env
    // value is empty or the app has been re-signed, the SMS still arrives and
    // the user types the code — this just stops firing, silently.
    if (_isAndroid) {
      listenForCode();
    }
  }

  /// sms_autofill calls this when it reads a matching SMS.
  @override
  void codeUpdated() {
    final value = code;
    if (value == null || value.isEmpty) return;

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    setState(() {
      _controller.text = digits.length > _codeLength
          ? digits.substring(0, _codeLength)
          : digits;
      _error = null;
    });

    if (_controller.text.length == _codeLength) {
      _submit();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isAndroid) {
      cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    if (seconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final code = _controller.text.trim();
    if (code.length != _codeLength) {
      setState(() => _error = context.l10n.enterVerificationCodeError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await _service.verifyCode(
        phone: widget.phone,
        code: code,
      );
      if (!mounted) return;
      widget.onSignedIn(result);
    } on PhoneSignInException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });

      // Only a wrong code leaves the user anywhere useful. Everything else
      // (expired, burned, no code, suspended, not-a-rider) needs a fresh code
      // or a different action, so send them back rather than letting them
      // retype into a code that can no longer work.
      if (!e.isRetryableOnCodeScreen) {
        _controller.clear();
        if (e.code == 'NO_CODE' ||
            e.code == 'CODE_EXPIRED' ||
            e.code == 'TOO_MANY_ATTEMPTS') {
          _startResendCountdown(0);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = context.l10n.actionTryAgain;
      });
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;

    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      final result = await _service.requestCode(widget.phone);
      if (!mounted) return;
      setState(() => _resending = false);
      _startResendCountdown(result.resendAfterSeconds);
      _controller.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.codeSentPhoneDefault)),
      );
    } on PhoneSignInException catch (e) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _error = e.message;
      });
      // Honour the server's own backoff rather than guessing.
      if (e.retryAfterSeconds != null) {
        _startResendCountdown(e.retryAfterSeconds!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AuthScaffold(
      showBackButton: true,
      onBack: () => Navigator.of(context).maybePop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            l10n.verificationCodeLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            // Existing key, already translated into every supported language.
            l10n.verifyPhoneBody(_displayPhone(widget.phone)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          TextField(
            controller: _controller,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            // iOS reads the code from the notification and offers it here. No
            // package needed on iOS; this attribute is the whole mechanism.
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: _codeLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 14,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              errorText: _error,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onChanged: (value) {
              if (_error != null) setState(() => _error = null);
              if (value.length == _codeLength) _submit();
            },
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 24),
          AuthGradientButton(
            label: l10n.actionVerify,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: (_secondsLeft > 0 || _resending) ? null : _resend,
              child: Text(
                _secondsLeft > 0
                    ? '${l10n.actionResend} ($_secondsLeft)'
                    : l10n.actionResend,
                style: TextStyle(
                  color: _secondsLeft > 0
                      ? theme.colorScheme.onSurfaceVariant
                      : AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `251911223344` reads better as `+251 91 122 3344`.
  String _displayPhone(String normalized) {
    if (normalized.length != 12) return normalized;
    final n = normalized;
    return '+${n.substring(0, 3)} ${n.substring(3, 5)} ${n.substring(5, 8)} ${n.substring(8)}';
  }
}
