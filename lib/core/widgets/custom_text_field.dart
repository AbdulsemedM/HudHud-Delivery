import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final String? Function(String?)? validator;
  final int maxLines;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final bool filled;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final bool showBorder;
  final double? height;
  final Widget? suffix;
  final VoidCallback? onSuffixPressed;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
    this.maxLines = 1,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius = 12.0,
    this.filled = true,
    this.labelStyle,
    this.hintStyle,
    this.textStyle,
    this.showBorder = false,
    this.height,
    this.suffix,
    this.onSuffixPressed,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = false;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText || widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: widget.labelStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.fillColor ?? 
                (widget.filled ? Colors.grey[100] : Colors.transparent),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.showBorder
                ? Border.all(
                    color: _isFocused
                        ? (widget.borderColor ?? AppColors.primaryColor)
                        : Colors.grey[300]!,
                    width: _isFocused ? 2.0 : 1.0,
                  )
                : null,
            boxShadow: widget.showBorder
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            validator: widget.validator,
            maxLines: widget.maxLines,
            style: widget.textStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ??
                  TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppColors.primaryColor
                          : Colors.grey[600],
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: widget.contentPadding ??
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    
    if (widget.suffix != null) {
      return widget.suffix;
    }
    
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: Colors.grey[600],
        ),
        onPressed: widget.onSuffixPressed,
      );
    }
    
    return null;
  }
}

// Predefined styles for common use cases
class CustomTextFieldStyles {
  // Login/Signup style with shadow and rounded corners
  static CustomTextField authField({
    required String label,
    required String hintText,
    IconData? prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return CustomTextField(
      label: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      isPassword: isPassword,
      keyboardType: keyboardType,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      fillColor: Colors.white,
      borderRadius: 15,
      showBorder: false,
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF34495E),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
    );
  }

  // Simple style with grey background
  static CustomTextField simpleField({
    String? label,
    required String hintText,
    IconData? prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return CustomTextField(
      label: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      isPassword: isPassword,
      keyboardType: keyboardType,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      fillColor: Colors.grey[100],
      borderRadius: 8,
      showBorder: false,
    );
  }

  // Outlined style with border
  static CustomTextField outlinedField({
    String? label,
    required String hintText,
    IconData? prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    Color? borderColor,
  }) {
    return CustomTextField(
      label: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      isPassword: isPassword,
      keyboardType: keyboardType,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      fillColor: Colors.white,
      borderColor: borderColor,
      borderRadius: 12,
      showBorder: true,
      filled: false,
    );
  }

  // Search field style
  static CustomTextField searchField({
    required String hintText,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    return CustomTextField(
      hintText: hintText,
      prefixIcon: Icons.search,
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      fillColor: Colors.grey[100],
      borderRadius: 12,
      showBorder: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}