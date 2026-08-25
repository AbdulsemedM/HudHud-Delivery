import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class ProductPriceFilterValues {
  final String? minPrice;
  final String? maxPrice;

  const ProductPriceFilterValues({this.minPrice, this.maxPrice});

  bool get hasFilter =>
      (minPrice != null && minPrice!.isNotEmpty) ||
      (maxPrice != null && maxPrice!.isNotEmpty);
}

/// Shows min/max price filter; returns [ProductPriceFilterValues] on Apply, null on dismiss without apply.
Future<ProductPriceFilterValues?> showProductPriceFilterSheet(
  BuildContext context, {
  String? initialMin,
  String? initialMax,
}) {
  return showModalBottomSheet<ProductPriceFilterValues>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ProductPriceFilterSheetBody(
      initialMin: initialMin,
      initialMax: initialMax,
    ),
  );
}

class _ProductPriceFilterSheetBody extends StatefulWidget {
  final String? initialMin;
  final String? initialMax;

  const _ProductPriceFilterSheetBody({
    this.initialMin,
    this.initialMax,
  });

  @override
  State<_ProductPriceFilterSheetBody> createState() =>
      _ProductPriceFilterSheetBodyState();
}

class _ProductPriceFilterSheetBodyState
    extends State<_ProductPriceFilterSheetBody> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.initialMin ?? '');
    _maxController = TextEditingController(text: widget.initialMax ?? '');
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final min = _minController.text.trim();
    final max = _maxController.text.trim();
    final minVal = min.isEmpty ? null : double.tryParse(min);
    final maxVal = max.isEmpty ? null : double.tryParse(max);
    if (min.isNotEmpty && minVal == null) {
      setState(() => _error = 'Enter a valid minimum price');
      return;
    }
    if (max.isNotEmpty && maxVal == null) {
      setState(() => _error = 'Enter a valid maximum price');
      return;
    }
    if (minVal != null && maxVal != null && minVal > maxVal) {
      setState(() => _error = 'Minimum cannot exceed maximum');
      return;
    }
    Navigator.pop(
      context,
      ProductPriceFilterValues(
        minPrice: min.isEmpty ? null : min,
        maxPrice: max.isEmpty ? null : max,
      ),
    );
  }

  void _clear() {
    Navigator.pop(
      context,
      const ProductPriceFilterValues(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Price range',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Min price',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Max price',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
