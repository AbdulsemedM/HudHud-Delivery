import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_model.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_widgets.dart';
import 'package:hudhud_delivery/features/tips/bloc/tips_bloc.dart';
import 'package:hudhud_delivery/features/tips/model/tip_rate_model.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class TipOrderCard extends StatefulWidget {
  final OrderModel order;

  const TipOrderCard({super.key, required this.order});

  @override
  State<TipOrderCard> createState() => _TipOrderCardState();
}

class _TipOrderCardState extends State<TipOrderCard> {
  int? _selectedRateId;
  String _recipientType = 'driver';
  final _messageController = TextEditingController();
  final _customAmountController = TextEditingController();
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    context.read<TipsBloc>().add(const LoadTipRatesEvent());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  TipRateModel? _selectedRate(List<TipRateModel> rates) {
    if (_selectedRateId == null) {
      final defaultRate = rates.cast<TipRateModel?>().firstWhere(
            (r) => r!.isDefault,
            orElse: () => rates.isNotEmpty ? rates.first : null,
          );
      return defaultRate;
    }
    for (final r in rates) {
      if (r.id == _selectedRateId) return r;
    }
    return rates.isNotEmpty ? rates.first : null;
  }

  void _onRateSelected(TipRateModel rate) {
    setState(() => _selectedRateId = rate.id);
    if (rate.isCustom) return;
    context.read<TipsBloc>().add(
          CalculateTipEvent(
            orderId: widget.order.id,
            tipOptionId: rate.id,
          ),
        );
  }

  void _onCustomCalculate() {
    final blocState = context.read<TipsBloc>().state;
    final rates = blocState is TipsLoaded ? blocState.rates : <TipRateModel>[];
    final rate = _selectedRate(rates);
    if (rate == null || !rate.isCustom) return;
    final custom = num.tryParse(_customAmountController.text.trim());
    if (custom == null || custom <= 0) return;
    context.read<TipsBloc>().add(
          CalculateTipEvent(
            orderId: widget.order.id,
            tipOptionId: rate.id,
            customAmount: custom,
          ),
        );
  }

  void _submit(TipsLoaded state) {
    final rate = _selectedRate(state.rates);
    final calc = state.calculateResult;
    if (rate == null || calc == null || calc.amount <= 0) return;
    context.read<TipsBloc>().add(
          SubmitTipEvent(
            orderId: widget.order.id,
            amount: calc.amount,
            tipOptionId: rate.id,
            recipientType: _recipientType,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
            isAnonymous: _isAnonymous,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<TipsBloc, TipsState>(
      listener: (context, state) {
        if (state is TipsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is TipsLoaded && state.tipSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.tipsSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TipsLoading) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.tipsAddTitle)),
            ),
          );
        }

        if (state is! TipsLoaded) return const SizedBox.shrink();

        if (state.tipSubmitted) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.tipsSuccess,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.rates.isEmpty) {
          return const SizedBox.shrink();
        }

        final selected = _selectedRate(state.rates);
        if (selected != null && _selectedRateId == null && !selected.isCustom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onRateSelected(selected);
          });
        }

        final calc = state.calculateResult;
        final canSubmit = calc != null &&
            calc.amount > 0 &&
            !state.isSubmitting &&
            !state.isCalculating &&
            (selected == null ||
                !selected.isCustom ||
                _customAmountController.text.trim().isNotEmpty);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tipsAddTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.rates.map((rate) {
                    final isSelected = selected?.id == rate.id;
                    return ChoiceChip(
                      label: Text(rate.name),
                      selected: isSelected,
                      onSelected: (_) => _onRateSelected(rate),
                    );
                  }).toList(),
                ),
                if (selected?.isCustom == true) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: l10n.enterCustomTip,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calculate_outlined),
                        onPressed: _onCustomCalculate,
                      ),
                    ),
                    onSubmitted: (_) => _onCustomCalculate(),
                  ),
                ],
                if (state.isCalculating)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  )
                else if (calc != null && calc.amount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.tipsCalculatedAmount(calc.amount.toString()),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  l10n.tipsRecipientLabel,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'driver',
                      label: Text(l10n.tipsRecipientDriver),
                    ),
                    ButtonSegment(
                      value: 'vendor',
                      label: Text(l10n.tipsRecipientVendor),
                    ),
                    ButtonSegment(
                      value: 'both',
                      label: Text(l10n.tipsRecipientBoth),
                    ),
                  ],
                  selected: {_recipientType},
                  onSelectionChanged: (s) {
                    setState(() => _recipientType = s.first);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.tipsMessageHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tipsAnonymous),
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    PaymentMethodCard.iconForId('wallet'),
                    color: PaymentMethodCard.colorForId('wallet'),
                  ),
                  title: Text(l10n.tipsPaymentWallet),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    PaymentMethodCard.iconForId('card'),
                    color: Colors.grey,
                  ),
                  title: Text(l10n.tipsPaymentCard),
                  subtitle: Text(l10n.tipsCardComingSoon),
                  enabled: false,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSubmit ? () => _submit(state) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.tipsSubmit),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
