import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';

const List<double> kWalletFundingQuickAmounts = [100, 250, 500, 1000];

class WalletFundingSubmitBar extends StatelessWidget {
  const WalletFundingSubmitBar({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: AppColors.buttonHeightMD,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthScreenColors.orange,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              disabledBackgroundColor:
                  AuthScreenColors.orange.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Clear, minimal body for add / withdraw.
class WalletFundingFormBody extends StatelessWidget {
  const WalletFundingFormBody({
    super.key,
    required this.amountController,
    required this.currency,
    required this.amountHint,
    required this.amountValidator,
    required this.methodSectionTitle,
    required this.methods,
    required this.selectedMethodId,
    required this.isLoadingMethods,
    required this.onMethodSelected,
    required this.ebirrProvider,
    required this.useHpp,
    required this.onEbirrProviderChanged,
    required this.onUseHppChanged,
    required this.onPaymentDetailsChanged,
    this.onQuickAmountSelected,
    this.emptyMethodsMessage,
  });

  final TextEditingController amountController;
  final String currency;
  final String amountHint;
  final FormFieldValidator<String> amountValidator;
  final String methodSectionTitle;
  final List<Map<String, dynamic>> methods;
  final String? selectedMethodId;
  final bool isLoadingMethods;
  final ValueChanged<String> onMethodSelected;
  final String ebirrProvider;
  final bool useHpp;
  final ValueChanged<String> onEbirrProviderChanged;
  final ValueChanged<bool> onUseHppChanged;
  final ValueChanged<Map<String, dynamic>> onPaymentDetailsChanged;
  final ValueChanged<double>? onQuickAmountSelected;
  final String? emptyMethodsMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: TextStyle(
              color: AuthScreenColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: AuthScreenColors.textPrimaryOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: amountHint,
              suffixText: currency,
              suffixStyle: TextStyle(
                color: AuthScreenColors.textMutedOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            validator: amountValidator,
          ),
          if (onQuickAmountSelected != null) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kWalletFundingQuickAmounts.map((amount) {
                final label = amount == amount.roundToDouble()
                    ? amount.toStringAsFixed(0)
                    : amount.toStringAsFixed(2);
                return OutlinedButton(
                  onPressed: () => onQuickAmountSelected!(amount),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuthScreenColors.textPrimaryOf(context),
                    side: BorderSide(color: AuthScreenColors.surfaceBorderOf(context)),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(label),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 28),
          Text(
            methodSectionTitle,
            style: TextStyle(
              color: AuthScreenColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 12),
          if (isLoadingMethods)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AuthScreenColors.orange,
                ),
              ),
            )
          else if (methods.isEmpty)
            Text(
              emptyMethodsMessage ?? 'No payment methods available',
              style: TextStyle(color: AuthScreenColors.textSecondaryOf(context)),
            )
          else
            ...methods.map((method) {
              final id = method['id']?.toString() ?? '';
              final name = method['name']?.toString() ?? id;
              final selected = selectedMethodId == id;
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: id.isEmpty ? null : () => onMethodSelected(id),
                  selected: selected,
                  selectedTileColor:
                      AuthScreenColors.orange.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected
                          ? AuthScreenColors.orange
                          : AuthScreenColors.surfaceBorderOf(context),
                    ),
                  ),
                  tileColor: AuthScreenColors.surfaceOf(context),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: AuthScreenColors.textPrimaryOf(context),
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected
                        ? AuthScreenColors.orange
                        : AuthScreenColors.textSecondaryOf(context),
                    size: 22,
                  ),
                ),
              );
            }),
          if (selectedMethodId != null) ...[
            const SizedBox(height: 8),
            PaymentDetailsForm(
              key: ValueKey(selectedMethodId),
              paymentMethodCode: selectedMethodId!,
              ebirrProvider: ebirrProvider,
              useHpp: useHpp,
              onEbirrProviderChanged: onEbirrProviderChanged,
              onUseHppChanged: onUseHppChanged,
              onChanged: onPaymentDetailsChanged,
            ),
          ],
        ],
      ),
    );
  }
}
