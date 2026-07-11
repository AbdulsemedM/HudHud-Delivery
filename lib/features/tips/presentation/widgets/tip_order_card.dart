import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_model.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_widgets.dart';
import 'package:hudhud_delivery/features/tips/bloc/tips_bloc.dart';
import 'package:hudhud_delivery/features/tips/model/tip_rate_model.dart';
import 'package:shimmer/shimmer.dart';

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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TipsLoading) {
          return const _TipOrderCardShimmer();
        }

        if (state is! TipsLoaded) return const SizedBox.shrink();

        if (state.tipSubmitted) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.r16),
              side: BorderSide(
                color: AppColors.successColor.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppColors.sp16),
              child: Row(
                children: [
                  IconBox(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.successColor,
                  ),
                  const SizedBox(width: AppColors.sp12),
                  Expanded(
                    child: Text(
                      l10n.tipsSuccess,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.successColor,
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.r16),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppColors.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBox(
                      icon: Icons.volunteer_activism_outlined,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: AppColors.sp12),
                    Expanded(
                      child: Text(
                        l10n.tipsAddTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppColors.sp16),
                SectionHeader(title: l10n.tipsAddTitle),
                Wrap(
                  spacing: AppColors.sp8,
                  runSpacing: AppColors.sp8,
                  children: state.rates.map((rate) {
                    final isSelected = selected?.id == rate.id;
                    return FilterChip(
                      label: Text(rate.name),
                      selected: isSelected,
                      showCheckmark: false,
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryColor
                            : theme.colorScheme.onSurface,
                      ),
                      backgroundColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      selectedColor: AppColors.primaryColor.withOpacity(0.12),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryColor.withOpacity(0.5)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.rFull),
                      ),
                      onSelected: (_) => _onRateSelected(rate),
                    );
                  }).toList(),
                ),
                if (selected?.isCustom == true) ...[
                  const SizedBox(height: AppColors.sp12),
                  TextField(
                    controller: _customAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: l10n.enterCustomTip,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkInputFill
                          : AppColors.lightInputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppColors.r12),
                      ),
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
                    padding: EdgeInsets.only(top: AppColors.sp12),
                    child: LinearProgressIndicator(),
                  )
                else if (calc != null && calc.amount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppColors.sp12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppColors.sp12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppColors.r12),
                      ),
                      child: Text(
                        l10n.tipsCalculatedAmount(calc.amount.toString()),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppColors.sp16),
                SectionHeader(title: l10n.tipsRecipientLabel),
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
                const SizedBox(height: AppColors.sp12),
                TextField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.tipsMessageHint,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkInputFill
                        : AppColors.lightInputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.r12),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tipsAnonymous),
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                ),
                const SizedBox(height: AppColors.sp8),
                SectionHeader(title: l10n.tipsPaymentWallet),
                _PaymentOptionTile(
                  icon: PaymentMethodCard.iconForId('wallet'),
                  iconColor: PaymentMethodCard.colorForId('wallet'),
                  title: l10n.tipsPaymentWallet,
                  selected: true,
                ),
                _PaymentOptionTile(
                  icon: PaymentMethodCard.iconForId('card'),
                  iconColor: AppColors.mutedLight,
                  title: l10n.tipsPaymentCard,
                  subtitle: l10n.tipsCardComingSoon,
                  enabled: false,
                ),
                const SizedBox(height: AppColors.sp12),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: canSubmit
                            ? AppColors.primaryGradient
                            : [
                                AppColors.disabledButton,
                                AppColors.disabledButton,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppColors.r12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppColors.r12),
                        onTap: canSubmit ? () => _submit(state) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: state.isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.tipsSubmit,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
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

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppColors.sp8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.sp12,
          vertical: AppColors.sp8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withOpacity(0.06)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppColors.r12),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor.withOpacity(0.35)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            IconBox(icon: icon, color: iconColor),
            const SizedBox(width: AppColors.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.mutedDark
                            : AppColors.mutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _TipOrderCardShimmer extends StatelessWidget {
  const _TipOrderCardShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.grey.shade300;
    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    final placeholder = isDark ? AppColors.surfaceDark : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.r16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppColors.sp16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                width: 140,
                decoration: BoxDecoration(
                  color: placeholder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppColors.sp16),
              Wrap(
                spacing: AppColors.sp8,
                children: List.generate(
                  4,
                  (_) => Container(
                    height: 32,
                    width: 64,
                    decoration: BoxDecoration(
                      color: placeholder,
                      borderRadius: BorderRadius.circular(AppColors.rFull),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppColors.sp16),
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: placeholder,
                  borderRadius: BorderRadius.circular(AppColors.r12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
