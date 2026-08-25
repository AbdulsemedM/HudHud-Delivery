import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';

/// Phone input for auth screens: country chip + national number.
class AuthPhoneNumberField extends StatelessWidget {
  const AuthPhoneNumberField({
    super.key,
    required this.countryCode,
    required this.countryIsoCode,
    required this.numberController,
    required this.onCountryChanged,
    this.validator,
    this.hintText,
    this.enabled = true,
  });

  final String countryCode;
  final String countryIsoCode;
  final TextEditingController numberController;
  final ValueChanged<Country> onCountryChanged;
  final String? Function(String?)? validator;
  final String? hintText;
  final bool enabled;

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: onCountryChanged,
      countryListTheme: CountryListThemeData(
        backgroundColor: AuthScreenColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        textStyle: TextStyle(color: AuthScreenColors.textPrimaryOf(context)),
        searchTextStyle: TextStyle(color: AuthScreenColors.textPrimaryOf(context)),
        inputDecoration: authFieldDecoration(context, hint: 'Search country'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final codeText = countryCode.startsWith('+') ? countryCode : '+$countryCode';
    final iso = countryIsoCode.toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: enabled ? () => _showCountryPicker(context) : null,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: authSurfaceBoxDecoration(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$iso $codeText',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AuthScreenColors.textSecondaryOf(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: numberController,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            validator: validator,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AuthScreenColors.textPrimaryOf(context),
            ),
            decoration: authFieldDecoration(context, hint: hintText),
          ),
        ),
      ],
    );
  }
}
