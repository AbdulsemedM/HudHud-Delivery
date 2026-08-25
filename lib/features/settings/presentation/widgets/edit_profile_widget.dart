import 'package:flutter/material.dart';
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
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AuthScreenColors.surfaceOf(context),
                shape: BoxShape.circle,
                border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: AuthScreenColors.textMutedOf(context),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AuthScreenColors.textSecondaryOf(context),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AuthScreenColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AuthScreenColors.textPrimaryOf(context),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: AuthScreenColors.signInGradient,
          ),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
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
      ),
    );
  }
}
