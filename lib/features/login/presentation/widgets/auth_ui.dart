import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

/// Shared presentation building blocks for the auth flow (login, signup,
/// forgot password, OTP). Pure UI — no business logic lives here.

/// Soft orange fill behind icons, tuned for the current brightness.
Color authOrangeTintOf(BuildContext context) => AuthScreenColors.isDark(context)
    ? AppColors.orangeTintDark
    : AppColors.orangeTint;

/// Soft indigo fill behind icons / selected states.
Color authIndigoTintOf(BuildContext context) => AuthScreenColors.isDark(context)
    ? AppColors.indigoTintDark
    : AppColors.indigoTint;

/// Brand indigo accent that stays legible in dark mode.
Color authIndigoOf(BuildContext context) => AuthScreenColors.isDark(context)
    ? AppColors.brandIndigoBright
    : AppColors.brandIndigo;

/// Field label shown above an input.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: AuthScreenColors.textPrimaryOf(context),
        ),
      ),
    );
  }
}

/// 72px tinted circle with a rounded icon — the visual anchor of auth steps.
class AuthHeroIcon extends StatelessWidget {
  const AuthHeroIcon({
    super.key,
    required this.icon,
    this.indigo = false,
    this.size = 72,
  });

  final IconData icon;

  /// Use the indigo accent instead of orange.
  final bool indigo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = indigo ? authIndigoOf(context) : AuthScreenColors.orange;
    final bg = indigo ? authIndigoTintOf(context) : authOrangeTintOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withValues(alpha: 0.14), width: 6),
      ),
      child: Icon(icon, color: fg, size: size * 0.44),
    );
  }
}

/// Title + subtitle block used at the top of auth screens.
class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.indigoIcon = false,
    this.center = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool indigoIcon;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        if (icon != null) ...[
          AuthHeroIcon(icon: icon!, indigo: indigoIcon),
          const SizedBox(height: 22),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.18,
            color: AuthScreenColors.textPrimaryOf(context),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AuthScreenColors.textSecondaryOf(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small rounded pill (e.g. a countdown "04:59").
class AuthPill extends StatelessWidget {
  const AuthPill({
    super.key,
    required this.label,
    this.icon = Icons.schedule_rounded,
    this.error = false,
  });

  final String label;
  final IconData icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final fg = error ? AppColors.errorColor : authIndigoOf(context);
    final bg = error
        ? AppColors.errorColor.withValues(alpha: 0.12)
        : authIndigoTintOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin divider with centred text ("or").
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(
        color: AuthScreenColors.surfaceBorderOf(context),
        thickness: 1,
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: AuthScreenColors.textMutedOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// Code entry rendered as individual digit boxes.
///
/// It is a real [TextFormField] (same [controller], [validator], formatters)
/// with transparent text laid over the boxes, so paste, autofill, keyboard
/// and form validation behave exactly like a plain text field.
class AuthCodeField extends StatefulWidget {
  const AuthCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final int length;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  State<AuthCodeField> createState() => _AuthCodeFieldState();
}

class _AuthCodeFieldState extends State<AuthCodeField> {
  static const double _boxHeight = 60;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    final border = AuthScreenColors.surfaceBorderOf(context);
    final surface = AuthScreenColors.surfaceOf(context);

    return Opacity(
      opacity: widget.enabled ? 1 : 0.6,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _boxHeight,
            child: IgnorePointer(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) {
                  final text = value.text;
                  final activeIndex = text.length >= widget.length
                      ? widget.length - 1
                      : text.length;
                  return Row(
                    children: List.generate(widget.length, (i) {
                      final char = i < text.length ? text[i] : '';
                      final filled = char.isNotEmpty;
                      final active = _focusNode.hasFocus &&
                          widget.enabled &&
                          i == activeIndex;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: i == 0 ? 0 : 5,
                            end: i == widget.length - 1 ? 0 : 5,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: filled && !dark
                                  ? AppColors.orangeTint.withValues(alpha: 0.55)
                                  : surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: active
                                    ? AuthScreenColors.orange
                                    : (filled
                                        ? AuthScreenColors.orange
                                            .withValues(alpha: 0.45)
                                        : border),
                                width: active ? 2 : 1.2,
                              ),
                            ),
                            child: filled
                                ? Text(
                                    char,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AuthScreenColors.textPrimaryOf(
                                          context),
                                    ),
                                  )
                                : Container(
                                    width: active ? 2 : 10,
                                    height: active ? 24 : 2,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AuthScreenColors.orange
                                          : AuthScreenColors.textMutedOf(
                                                  context)
                                              .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            showCursor: false,
            enableInteractiveSelection: false,
            cursorColor: Colors.transparent,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.transparent,
              fontSize: 20,
              height: 1.0,
            ),
            decoration: const InputDecoration(
              counterText: '',
              filled: false,
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 20),
              errorStyle: TextStyle(
                color: AppColors.errorColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            validator: widget.validator,
          ),
        ],
      ),
    );
  }
}
