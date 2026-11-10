import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/app/services/phone_sign_in_service.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// DEBUG-ONLY harness for the passwordless phone sign-in service.
///
/// Reached from a button on the login screen that only exists in debug builds.
/// Pops `true` once verify succeeds (the session is already stored by then),
/// so the login screen can continue with its normal post-login navigation.
class PhoneSignInTestScreen extends StatefulWidget {
  const PhoneSignInTestScreen({super.key});

  @override
  State<PhoneSignInTestScreen> createState() => _PhoneSignInTestScreenState();
}

class _PhoneSignInTestScreenState extends State<PhoneSignInTestScreen> {
  final _service = PhoneSignInService();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  /// Normalised phone returned by requestCode — must be sent back to verify.
  String? _requestedPhone;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _resendTimer;
  StreamSubscription<String>? _smsSub;
  String? _appSignature;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      SmsAutoFill().getAppSignature.then((sig) {
        if (mounted) setState(() => _appSignature = sig);
      }).catchError((Object e) {
        _addLog('getAppSignature failed: $e');
      });
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _smsSub?.cancel();
    if (Platform.isAndroid) SmsAutoFill().unregisterListener();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _addLog(String line) {
    final t = TimeOfDay.now().format(context);
    setState(() => _log.insert(0, '[$t] $line'));
  }

  Future<void> _startSmsListener() async {
    if (!Platform.isAndroid) return;
    await _smsSub?.cancel();
    try {
      await SmsAutoFill().listenForCode();
      _smsSub = SmsAutoFill().code.listen((code) {
        if (!mounted || code.isEmpty) return;
        _codeCtrl.text = code;
        _addLog('SMS auto-read: $code');
      });
      _addLog('SMS Retriever listening (2 min window)');
    } catch (e) {
      _addLog('SMS Retriever failed to start: $e');
    }
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendIn = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _request() async {
    final input = _phoneCtrl.text.trim();
    if (input.isEmpty) return _addLog('Enter a phone number first');
    setState(() => _busy = true);
    try {
      await _startSmsListener();
      final r = await _service.requestCode(input);
      _requestedPhone = r.phone;
      _addLog('REQUEST OK → phone=${r.phone}, expires_in=${r.expiresInSeconds}s, '
          'resend_after=${r.resendAfterSeconds}s\n"${r.message}"');
      _startResendCountdown(r.resendAfterSeconds);
    } on PhoneSignInException catch (e) {
      _addLog(_describe('REQUEST', e));
    } catch (e) {
      _addLog('REQUEST unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final phone = _requestedPhone;
    if (phone == null) return _addLog('Request a code first');
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return _addLog('Enter the code');
    setState(() => _busy = true);
    try {
      final r = await _service.verifyCode(
        phone: phone,
        code: code,
        deviceName: 'hudhud-customer-debug',
      );
      _addLog('VERIFY OK → user #${r.user.id} ${r.user.name}, '
          'created=${r.created}, onboarding_required=${r.onboardingRequired}, '
          'token=${r.token.substring(0, r.token.length.clamp(0, 8))}…');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Signed in'),
          content: Text(
            'Session stored for ${r.user.name}.\n'
            '${r.created ? 'A NEW account was created.' : 'Existing account.'}\n\n'
            'Continue into the app?',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PhoneSignInException catch (e) {
      _addLog(_describe('VERIFY', e));
      if (!e.isRetryableOnCodeScreen) {
        _addLog('→ not retryable on this screen: request a new code');
      }
    } catch (e) {
      _addLog('VERIFY unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(String step, PhoneSignInException e) =>
      '$step FAILED → code=${e.code}, status=${e.statusCode}'
      '${e.retryAfterSeconds != null ? ', retry_after=${e.retryAfterSeconds}s' : ''}'
      '\n"${e.message}"';

  @override
  Widget build(BuildContext context) {
    final canResend = !_busy && _resendIn <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Phone sign-in (debug)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '09XXXXXXXX or +2519XXXXXXXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: canResend ? _request : null,
              child: Text(_resendIn > 0
                  ? 'Resend in ${_resendIn}s'
                  : (_requestedPhone == null ? 'Send code' : 'Resend code')),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy || _requestedPhone == null ? null : _verify,
              child: const Text('Verify & sign in'),
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_appSignature != null) ...[
              const SizedBox(height: 16),
              SelectableText(
                'Android app hash (last line of SMS): $_appSignature',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Divider(height: 32),
            Text('Log', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final line in _log)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableText(
                  line,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
