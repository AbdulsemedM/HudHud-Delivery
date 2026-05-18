import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? networkImageUrl;
  final String? localImagePath;
  final VoidCallback onImageTap;

  const ProfileImagePicker({
    super.key,
    this.networkImageUrl,
    this.localImagePath,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onImageTap,
      child: Stack(
        children: [
          UserAvatar(
            radius: 40,
            imageUrl: networkImageUrl,
            localImagePath: localImagePath,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputType keyboardType;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PhoneNumberField extends StatelessWidget {
  final String countryCode;
  final TextEditingController numberController;
  final ValueChanged<Country> onCountryChanged;

  const PhoneNumberField({
    super.key,
    required this.countryCode,
    required this.numberController,
    required this.onCountryChanged,
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
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
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

class UpdateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const UpdateButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A148C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Update',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
