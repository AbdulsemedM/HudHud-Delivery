import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hudhud_delivery/app/services/phone_sign_in_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/phone_signin/presentation/screen/phone_sign_in_code_screen.dart';

/// Phone entry for passwordless sign-in.
///
/// Self-contained by design: it takes the service and a callback rather than
/// touching the app's bloc or router, so wiring is a single Navigator push and
/// nothing here assumes how the surrounding app manages state.
///
/// Uses only existing l10n keys, so it is already translated into every
/// supported language and needs no `flutter gen-l10n` run.
class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({
    super.key,
    required this.onSignedIn,
    this.service,
  });

  /// Called once a session exists and is persisted.
  ///
  /// `result.created == true` means this phone had no account and one was just
  /// made — the moment to ask for a name. Do NOT try to infer that from the
  /// request step: it returns an identical response either way, on purpose, so
  /// the endpoint cannot be used to discover who is registered.
  final void Function(PhoneSignInVerifyResult result) onSignedIn;

  final PhoneSignInService? service;

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  late final PhoneSignInService _service =
      widget.service ?? PhoneSignInService();

  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final raw = _controller.text.trim();

    try {
      final result = await _service.requestCode(raw);
      if (!mounted) return;
      setState(() => _submitting = false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhoneSignInCodeScreen(
            // The normalised value, not what was typed — verify must receive
            // the same string the request used.
            phone: result.phone,
            resendAfterSeconds: result.resendAfterSeconds,
            service: _service,
            onSignedIn: widget.onSignedIn,
          ),
        ),
      );
    } on PhoneSignInException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverError = context.l10n.actionTryAgain;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.loginTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.loginSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
              ],
              decoration: InputDecoration(
                // Ethiopian numbers only, so the prefix is fixed rather than a
                // country picker. normalizePhoneToBackend accepts 09…, 9…,
                // +251… and 251… all the same, so whatever they type works.
                prefixText: '$kDefaultPhoneDialCode ',
                labelText: l10n.labelEmailOrPhone,
                hintText: '09xx xxx xxx',
                errorText: _serverError,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                // 9 significant digits, with or without a trunk 0 or 251.
                if (digits.length < 9) {
                  return l10n.validationPhoneRequired;
                }
                return null;
              },
              onChanged: (_) {
                if (_serverError != null) setState(() => _serverError = null);
              },
              onFieldSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 24),
            AuthGradientButton(
              label: l10n.actionNext,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
