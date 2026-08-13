import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../model/payment_initiate_result.dart';

bool _usesEbirrPhoneFormat(String methodCode) =>
    isEbirrPaymentMethodCode(methodCode);

/// Phone hint / format guide per payment method.
String paymentPhoneHint(String methodCode) {
  switch (methodCode) {
    case 'waafi':
      return '254712345678';
    case 'edahab':
      return '656013956';
    case 'sahay':
      return '0911679409';
    default:
      if (_usesEbirrPhoneFormat(methodCode)) return '0915741199';
      return 'Phone number';
  }
}

String paymentPhoneLabel(String methodCode) {
  switch (methodCode) {
    case 'waafi':
      return 'Phone (254XXXXXXXXX)';
    case 'edahab':
      return 'Phone (65XXXXXXXXX)';
    case 'sahay':
      return 'Phone (09xxxxxxxx)';
    default:
      if (_usesEbirrPhoneFormat(methodCode)) {
        return 'Phone (09xxxxxxxx)';
      }
      return 'Phone number';
  }
}

/// Normalizes phone to the backend format expected by each method.
String normalizePaymentPhone(String? phone, String methodCode) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  switch (methodCode) {
    case 'waafi':
      if (digits.startsWith('254') && digits.length >= 12) {
        return digits.substring(0, 12);
      }
      if (digits.startsWith('0') && digits.length >= 10) {
        return '254${digits.substring(1, 10)}';
      }
      if (digits.length == 9) return '254$digits';
      return digits;
    case 'edahab':
      if (digits.startsWith('65')) return digits;
      if (digits.startsWith('0')) return '65${digits.substring(1)}';
      return digits;
    case 'sahay':
      if (digits.startsWith('251') && digits.length >= 12) {
        return digits.substring(0, 12);
      }
      if (digits.startsWith('0') && digits.length >= 10) {
        return '251${digits.substring(1, 10)}';
      }
      if (digits.length == 9) return '251$digits';
      if (digits.length > 9) {
        return '251${digits.substring(digits.length - 9)}';
      }
      return '251${digits.padLeft(9, '0')}';
    default:
      if (_usesEbirrPhoneFormat(methodCode)) {
        if (digits.startsWith('251') && digits.length >= 12) {
          return digits.substring(0, 12);
        }
        if (digits.startsWith('0') && digits.length >= 10) {
          return '251${digits.substring(1, 10)}';
        }
        if (digits.length == 9) return '251$digits';
        if (digits.length > 9) {
          return '251${digits.substring(digits.length - 9)}';
        }
        return '251${digits.padLeft(9, '0')}';
      }
      return digits;
  }
}

/// Returns an error message if phone is invalid for [methodCode], else null.
String? validatePaymentPhone(String? phone, String methodCode) {
  final normalized = normalizePaymentPhone(phone, methodCode);
  if (normalized.isEmpty) {
    return 'Phone number is required';
  }
  switch (methodCode) {
    case 'waafi':
      if (!RegExp(r'^254\d{9}$').hasMatch(normalized)) {
        return 'Enter a valid Waafi number (254XXXXXXXXX)';
      }
    case 'edahab':
      if (!RegExp(r'^65\d{7,9}$').hasMatch(normalized)) {
        return 'Enter a valid eDahab number (65XXXXXXXXX)';
      }
    case 'sahay':
      if (!RegExp(r'^2519\d{8}$').hasMatch(normalized)) {
        return 'Enter a valid phone number (09xxxxxxxx)';
      }
    default:
      if (_usesEbirrPhoneFormat(methodCode)) {
        if (!RegExp(r'^2519\d{8}$').hasMatch(normalized)) {
          return 'Enter a valid phone number (09xxxxxxxx)';
        }
      }
  }
  return null;
}

class PaymentDetailsForm extends StatefulWidget {
  final String paymentMethodCode;
  final String? initialPhone;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final String ebirrProvider;
  final ValueChanged<String>? onEbirrProviderChanged;
  final bool useHpp;
  final ValueChanged<bool>? onUseHppChanged;

  const PaymentDetailsForm({
    super.key,
    required this.paymentMethodCode,
    this.initialPhone,
    required this.onChanged,
    this.ebirrProvider = 'kaafi',
    this.onEbirrProviderChanged,
    this.useHpp = false,
    this.onUseHppChanged,
  });

  @override
  State<PaymentDetailsForm> createState() => _PaymentDetailsFormState();
}

class _PaymentDetailsFormState extends State<PaymentDetailsForm> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPhone ?? '';
    final display = initial.replaceAll(RegExp(r'\D'), '');
    _phoneController = TextEditingController(text: display);
    _emitDetails();
  }

  @override
  void didUpdateWidget(covariant PaymentDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentMethodCode != widget.paymentMethodCode ||
        oldWidget.ebirrProvider != widget.ebirrProvider ||
        oldWidget.useHpp != widget.useHpp) {
      _emitDetails();
    }
  }

  void _emitDetails({String? ebirrProvider, bool? useHpp}) {
    final details = <String, dynamic>{};
    if (paymentMethodNeedsDetailsForm(widget.paymentMethodCode)) {
      final phone = normalizePaymentPhone(
        _phoneController.text,
        widget.paymentMethodCode,
      );
      if (phone.isNotEmpty) {
        details['phone'] = phone;
      }
      if (widget.paymentMethodCode == 'waafi') {
        details['use_hpp'] = useHpp ?? widget.useHpp;
      }
      if (widget.paymentMethodCode == 'ebirr') {
        details['provider'] = ebirrProvider ?? widget.ebirrProvider;
      }
    }
    // Defer — initState/didUpdateWidget can run while the parent is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onChanged(details);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final outline = scheme.outline.withValues(alpha: 0.55);
    final radius = BorderRadius.circular(AppColors.radiusLG);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        fontSize: 14,
        color: scheme.onSurface,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!paymentMethodNeedsDetailsForm(widget.paymentMethodCode)) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final code = widget.paymentMethodCode;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment details',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: scheme.onSurface),
            decoration: _fieldDecoration(
              context,
              label: paymentPhoneLabel(code),
              hint: paymentPhoneHint(code),
            ),
            onChanged: (_) => _emitDetails(),
          ),
          if (code == 'waafi') ...[
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Use hosted payment page',
                style: TextStyle(color: scheme.onSurface),
              ),
              subtitle: Text(
                'Open Waafi Pay in a secure browser page',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              value: widget.useHpp,
              activeThumbColor: AppColors.primaryColor,
              onChanged: (value) {
                widget.onUseHppChanged?.call(value);
                _emitDetails(useHpp: value);
              },
            ),
          ],
          if (code == 'ebirr') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  widget.ebirrProvider == 'coop' ? 'coop' : 'kaafi',
              style: TextStyle(color: scheme.onSurface),
              dropdownColor: scheme.surface,
              decoration: _fieldDecoration(
                context,
                label: 'Provider',
              ),
              items: const [
                DropdownMenuItem(value: 'kaafi', child: Text('Kaafi')),
                DropdownMenuItem(value: 'coop', child: Text('Coop')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.onEbirrProviderChanged?.call(value);
                  _emitDetails(ebirrProvider: value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

Map<String, dynamic> buildInitiatePaymentDetails({
  required String paymentMethodCode,
  required Map<String, dynamic> collectedDetails,
  required int orderId,
}) {
  final details = <String, dynamic>{};

  if (paymentMethodNeedsDetailsForm(paymentMethodCode)) {
    final phoneRaw = collectedDetails['phone']?.toString();
    final phone = normalizePaymentPhone(phoneRaw, paymentMethodCode);
    if (phone.isNotEmpty) {
      details['phone'] = phone;
    }
  }

  if (paymentMethodCode == 'waafi') {
    details['use_hpp'] = collectedDetails['use_hpp'] == true;
  }

  if (paymentMethodCode == 'ebirr') {
    final provider = collectedDetails['provider']?.toString();
    if (provider == 'kaafi' || provider == 'coop') {
      details['provider'] = provider;
    } else {
      details['provider'] = 'kaafi';
    }
  }
  // ebirr_kaafi / ebirr_coop: provider is encoded in payment_method_code.

  return details;
}
