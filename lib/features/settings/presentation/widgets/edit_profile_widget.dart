import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

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
    final indigo = AuthScreenColors.isDark(context)
        ? AppColors.brandIndigoBright
        : AppColors.brandIndigo;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onImageTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuthScreenColors.surfaceOf(context),
                border: Border.all(color: indigo, width: 2.5),
                boxShadow: AppColors.softShadow(context),
              ),
              child: UserAvatar(
                radius: 50,
                imageUrl: networkImageUrl,
                localImagePath: localImagePath,
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AuthScreenColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AuthScreenColors.backgroundOf(context),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
    final radius = BorderRadius.circular(16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AuthScreenColors.textSecondaryOf(context),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AuthScreenColors.textPrimaryOf(context),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AuthScreenColors.surfaceOf(context),
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: AuthScreenColors.surfaceBorderOf(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: AuthScreenColors.surfaceBorderOf(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AuthScreenColors.orange,
                width: 1.6,
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
      height: 56,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthScreenColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AuthScreenColors.orange.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
