import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: isDarkMode ? Border.all(color: AppColors.darkBorder, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.4) 
                : Colors.grey.withOpacity(0.1),
            spreadRadius: isDarkMode ? 0 : 1,
            blurRadius: isDarkMode ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              productImage.startsWith('http') ? productImage : 'https://via.placeholder.com/60',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.darkOnSurface : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${quantity}X ${price.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.darkOnSurface.withOpacity(0.7) : AppColors.lightTextSecondary,
                  ),
                ),
              ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promo Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkOnSurface 
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Enter Promo Code',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkOnSurface.withOpacity(0.6)
                          : AppColors.lightTextSecondary.withOpacity(0.7),
                    ),
                    filled: Theme.of(context).brightness == Brightness.dark,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.primaryLightColor
                            : AppColors.primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_promoController.text.isNotEmpty) {
                    widget.onPromoCodeApplied(_promoController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.primaryLightColor 
                      : AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deliver To',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkOnSurface 
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkSurface 
                  : Colors.white,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.withOpacity(0.5) 
                    : Colors.grey.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkOnSurface 
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkOnSurface.withOpacity(0.7) 
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onChangeAddress,
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.darkOnSurface.withOpacity(0.7) 
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Additional note',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkOnSurface.withOpacity(0.5) 
                    : AppColors.lightTextSecondary.withOpacity(0.7),
              ),
              filled: Theme.of(context).brightness == Brightness.dark,
              fillColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkSurface 
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
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
    _tipController.text = _selectedTip > 0 ? _selectedTip.toString() : '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Tip/Bonus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Suggested tip amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _suggestedTips.map((tip) {
              final bool isSelected = _selectedTip == tip;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTip = tip;
                    _tipController.text = tip.toString();
                  });
                  widget.onTipChanged(tip);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (isDarkMode ? AppColors.primaryLightColor : AppColors.primaryColor)
                        : (isDarkMode ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? (isDarkMode ? AppColors.primaryLightColor : AppColors.primaryColor)
                          : (isDarkMode ? AppColors.darkBorder : Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  child: Text(
                    '${tip.toStringAsFixed(0)} Birr',
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white
                          : (isDarkMode ? AppColors.darkOnSurface : AppColors.lightTextPrimary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Custom tip amount
          TextField(
            controller: _tipController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter custom tip amount',
              hintStyle: TextStyle(
                color: isDarkMode
                    ? AppColors.darkOnSurface.withOpacity(0.6)
                    : AppColors.lightTextSecondary.withOpacity(0.7),
              ),
              filled: isDarkMode,
              fillColor: isDarkMode ? AppColors.darkSurface : null,
              prefixIcon: const Icon(Icons.attach_money, size: 20),
              suffixIcon: TextButton(
                onPressed: () {
                  if (_tipController.text.isNotEmpty) {
                    final double customTip = double.tryParse(_tipController.text) ?? 0.0;
                    setState(() {
                      _selectedTip = customTip;
                    });
                    widget.onTipChanged(customTip);
                  }
                },
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.primaryLightColor : AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? AppColors.darkBorder
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? AppColors.darkBorder
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? AppColors.primaryLightColor
                      : AppColors.primaryColor,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                final double customTip = double.tryParse(value) ?? 0.0;
                setState(() {
                  _selectedTip = customTip;
                });
                widget.onTipChanged(customTip);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }
}

class OrderSummarySection extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double extras;
  final double serviceCharge;
  final double deliveryFee;
  final double total;
  final double tipAmount;

  const OrderSummarySection({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.extras,
    required this.serviceCharge,
    required this.deliveryFee,
    required this.total,
    this.tipAmount = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal, false),
          _buildSummaryRow('Discount', -discount, false, isDiscount: true),
          _buildSummaryRow('Extras', extras, false, showPlus: true),
          _buildSummaryRow('Service Charge', serviceCharge, false, showPlus: true),
          _buildSummaryRow('Delivery Fee', deliveryFee, false, showPlus: true),
          if (tipAmount > 0) _buildSummaryRow('Tip', tipAmount, false, showPlus: true),
          const Divider(thickness: 1),
          _buildSummaryRow('Total Amount', total, true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    bool isTotal, {
    bool isDiscount = false,
    bool showPlus = false,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal 
                    ? (Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.primaryLightColor 
                        : AppColors.primaryColor) 
                    : (Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.darkOnSurface 
                        : AppColors.lightTextPrimary),
              ),
            ),
            Text(
              '${isDiscount ? '(-)' : showPlus ? '(+)' : ''} ${amount.toStringAsFixed(2)} Br',
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal 
                    ? (Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.primaryLightColor 
                        : AppColors.primaryColor) 
                    : (Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.darkOnSurface 
                        : AppColors.lightTextPrimary),
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.primaryLightColor 
              : AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Confirm Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}