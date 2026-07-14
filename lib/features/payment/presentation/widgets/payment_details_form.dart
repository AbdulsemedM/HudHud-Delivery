import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/phone_util.dart';
import '../../model/payment_initiate_result.dart';

class PaymentDetailsForm extends StatefulWidget {
  final String paymentMethodCode;
  final String? initialPhone;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final String ebirrProvider;
  final ValueChanged<String>? onEbirrProviderChanged;

  const PaymentDetailsForm({
    super.key,
    required this.paymentMethodCode,
    this.initialPhone,
    required this.onChanged,
    this.ebirrProvider = 'ebirr',
    this.onEbirrProviderChanged,
  });

  @override
  State<PaymentDetailsForm> createState() => _PaymentDetailsFormState();
}

class _PaymentDetailsFormState extends State<PaymentDetailsForm> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final parts = splitPhoneForDisplay(widget.initialPhone);
    _phoneController = TextEditingController(text: parts.nationalNumber);
    _emitDetails();
  }

  @override
  void didUpdateWidget(covariant PaymentDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentMethodCode != widget.paymentMethodCode ||
        oldWidget.ebirrProvider != widget.ebirrProvider) {
      _emitDetails();
    }
  }

  void _emitDetails({String? ebirrProvider}) {
    final details = <String, dynamic>{};
    if (paymentMethodNeedsDetailsForm(widget.paymentMethodCode)) {
      final phone = normalizePhoneToBackend(_phoneController.text);
      if (phone.isNotEmpty) {
        details['phone'] = phone;
      }
      if (widget.paymentMethodCode == 'ebirr') {
        details['provider'] = ebirrProvider ?? widget.ebirrProvider;
      }
    }
    widget.onChanged(details);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!paymentMethodNeedsDetailsForm(widget.paymentMethodCode)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment details',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '9XXXXXXXX',
              prefixText: '+251 ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emitDetails(),
          ),
          if (widget.paymentMethodCode == 'ebirr') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: widget.ebirrProvider,
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ebirr', child: Text('eBirr')),
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
  final details = Map<String, dynamic>.from(collectedDetails);
  if (paymentMethodCode == 'qpay') {
    details['awb'] =
        'ORD_${orderId}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
  }
  return details;
}
