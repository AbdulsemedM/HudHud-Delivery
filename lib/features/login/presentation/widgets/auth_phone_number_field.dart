import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_field_decoration.dart';

/// Phone input for auth screens: one field with a country-code prefix
/// (flag + dial code, tap to change) and the national number.
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        textStyle: TextStyle(color: AuthScreenColors.textPrimaryOf(context)),
        searchTextStyle: TextStyle(
          color: AuthScreenColors.textPrimaryOf(context),
        ),
        inputDecoration: authFieldDecoration(
          context,
          hint: 'Search country',
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final codeText =
        countryCode.startsWith('+') ? countryCode : '+$countryCode';
    final iso = countryIsoCode.toUpperCase();
    final flag = Country.tryParse(iso)?.flagEmoji;

    final prefix = Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? () => _showCountryPicker(context) : null,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        flag ?? iso,
                        style: TextStyle(
                          fontSize: flag != null ? 20 : 13,
                          fontWeight: FontWeight.w700,
                          color: AuthScreenColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        codeText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AuthScreenColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AuthScreenColors.textMutedOf(context),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 1.2,
            height: 26,
            color: AuthScreenColors.surfaceBorderOf(context),
          ),
        ],
      ),
    );

    return TextFormField(
      controller: numberController,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AuthScreenColors.textPrimaryOf(context),
      ),
      decoration: authFieldDecoration(
        context,
        hint: hintText,
        prefixIcon: prefix,
      ).copyWith(
        prefixIconConstraints: const BoxConstraints(minHeight: 48),
      ),
    );
  }
}
