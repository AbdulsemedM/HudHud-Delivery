import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

class PhoneNumberField extends StatelessWidget {
  final String countryCode;
  final TextEditingController numberController;
  final ValueChanged<Country> onCountryChanged;
  final String? Function(String?)? validator;
  final String? hintText;

  const PhoneNumberField({
    super.key,
    required this.countryCode,
    required this.numberController,
    required this.onCountryChanged,
    this.validator,
    this.hintText,
  });

  void _showCountryPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: onCountryChanged,
      countryListTheme: CountryListThemeData(
        backgroundColor: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        textStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        searchTextStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fieldDecoration = BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
    );
    final codeText = countryCode.startsWith('+') ? countryCode : '+$countryCode';
    final dialDigits = codeText.replaceFirst('+', '');
    final country = CountryService().findByPhoneCode(dialDigits);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showCountryPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: fieldDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (country != null) ...[
                  Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  codeText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: fieldDecoration,
            child: TextFormField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              validator: validator,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
