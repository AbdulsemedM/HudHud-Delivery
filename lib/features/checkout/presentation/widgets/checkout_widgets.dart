import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payment/presentation/widgets/payment_widgets.dart';

class CheckoutHeroHeader extends StatelessWidget {
  final int itemCount;
  final double subtotal;

  const CheckoutHeroHeader({
    super.key,
    required this.itemCount,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryDarkColor,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Almost there!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Review & place order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                _HeroStat(
                  icon: Icons.shopping_bag_outlined,
                  label: '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                _HeroStat(
                  icon: Icons.payments_outlined,
                  label: 'ETB ${subtotal.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? accentColor;

  const CheckoutSectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder.withValues(alpha: 0.8),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class CheckoutProductCard extends StatelessWidget {
  final String productName;
  final String productImage;
  final int quantity;
  final double price;

  const CheckoutProductCard({
    super.key,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineTotal = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  productImage.startsWith('http')
                      ? productImage
                      : 'https://via.placeholder.com/72',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.fastfood_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryDarkColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '×$quantity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ETB ${price.toStringAsFixed(2)} each',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ETB ${lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class PromoCodeSection extends StatefulWidget {
  final Function(String) onPromoCodeApplied;

  const PromoCodeSection({
    super.key,
    required this.onPromoCodeApplied,
  });

  @override
  State<PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends State<PromoCodeSection> {
  final TextEditingController _promoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.local_offer_outlined,
              color: AppColors.primaryColor.withValues(alpha: 0.85),
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilledButton(
              onPressed: () {
                if (_promoController.text.isNotEmpty) {
                  widget.onPromoCodeApplied(_promoController.text.trim());
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }
}

class DeliveryAddressSection extends StatelessWidget {
  final String currentAddress;
  final VoidCallback onChangeAddress;

  const DeliveryAddressSection({
    super.key,
    required this.currentAddress,
    required this.onChangeAddress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.08),
            AppColors.secondaryColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery address',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentAddress,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onChangeAddress,
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: const Text('Change'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class NotesSection extends StatelessWidget {
  final TextEditingController notesController;

  const NotesSection({
    super.key,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Any special instructions for the rider?',
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceVariant
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8, top: 12),
          child: Icon(
            Icons.sticky_note_2_outlined,
            color: scheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      ),
    );
  }
}

class TipSection extends StatefulWidget {
  final Function(double) onTipChanged;
  final double currentTip;

  const TipSection({
    super.key,
    required this.onTipChanged,
    required this.currentTip,
  });

  @override
  State<TipSection> createState() => _TipSectionState();
}

class _TipSectionState extends State<TipSection> {
  final TextEditingController _tipController = TextEditingController();
  final List<double> _suggestedTips = [10.0, 20.0, 50.0, 100.0];
  double _selectedTip = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedTip = widget.currentTip;
    _tipController.text = _selectedTip > 0 ? _selectedTip.toStringAsFixed(0) : '';
  }

  void _selectTip(double tip) {
    setState(() {
      _selectedTip = tip;
      _tipController.text = tip.toStringAsFixed(0);
    });
    widget.onTipChanged(tip);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TipChip(
                label: 'No tip',
                selected: _selectedTip == 0,
                onTap: () => _selectTip(0),
              ),
              const SizedBox(width: 8),
              ..._suggestedTips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TipChip(
                    label: 'ETB ${tip.toStringAsFixed(0)}',
                    selected: _selectedTip == tip,
                    onTap: () => _selectTip(tip),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tipController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Custom amount',
            hintStyle: TextStyle(color: scheme.onSurfaceVariant),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            prefixText: 'ETB ',
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_circle_outline),
              color: AppColors.primaryColor,
              onPressed: () {
                final customTip = double.tryParse(_tipController.text) ?? 0;
                _selectTip(customTip);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (value) {
            _selectTip(double.tryParse(value) ?? 0);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryColor
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class OrderSummarySection extends StatelessWidget {
  final double subtotal;
  final double total;
  final double tipAmount;

  const OrderSummarySection({
    super.key,
    required this.subtotal,
    required this.total,
    this.tipAmount = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', amount: subtotal),
          const _SummaryRow(label: 'Delivery fee', amount: 0, muted: true),
          if (tipAmount > 0) _SummaryRow(label: 'Tip', amount: tipAmount),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: List.generate(
                24,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    margin: EdgeInsets.only(right: i == 23 ? 0 : 4),
                    color: scheme.outline.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
                ).createShader(bounds),
                child: Text(
                  'ETB ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool muted;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            muted && amount == 0
                ? 'Free'
                : 'ETB ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: muted ? AppColors.successColor : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

const List<Map<String, dynamic>> _kCheckoutPaymentMethods = [
  {'id': 'cash_on_delivery', 'name': 'Cash', 'enabled': true},
  {'id': 'telebirr', 'name': 'TeleBirr', 'enabled': true},
  {'id': 'cbe', 'name': 'CBE Birr', 'enabled': true},
  {'id': 'chapa', 'name': 'Chapa', 'enabled': true},
  {'id': 'amole', 'name': 'Amole', 'enabled': true},
  {'id': 'wallet', 'name': 'Wallet', 'enabled': true},
  {'id': 'card', 'name': 'Card', 'enabled': true},
  {'id': 'ebirr', 'name': 'eBirr', 'enabled': true},
];

class PaymentMethodGridSection extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const PaymentMethodGridSection({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kCheckoutPaymentMethods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final method = _kCheckoutPaymentMethods[index];
          final id = method['id'] as String;
          final name = method['name'] as String;
          final enabled = method['enabled'] as bool;
          final isSelected = selectedId == id;
          final color = PaymentMethodCard.colorForId(id);
          final icon = PaymentMethodCard.iconForId(id);

          return GestureDetector(
            onTap: enabled ? () => onSelected(id) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 92,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.18),
                          color.withValues(alpha: 0.08),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Opacity(
                opacity: enabled ? 1 : 0.45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? color
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Icon(Icons.check_circle, color: color, size: 14),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CheckoutBottomBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final VoidCallback onConfirm;

  const CheckoutBottomBar({
    super.key,
    required this.total,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total to pay',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETB ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ConfirmOrderButton(
                onPressed: onConfirm,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const ConfirmOrderButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 52,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Place Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class CheckoutSuccessDialog extends StatelessWidget {
  final String orderId;
  final VoidCallback onDone;

  const CheckoutSuccessDialog({
    super.key,
    required this.orderId,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.successColor.withValues(alpha: 0.15),
                    AppColors.primaryColor.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successColor,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order placed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order #$orderId is on its way. We\'ll keep you updated.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back to shopping',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
