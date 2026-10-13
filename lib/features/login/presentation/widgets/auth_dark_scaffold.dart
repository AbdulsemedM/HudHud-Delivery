import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/core/widgets/theme_toggle_button.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.onBack,
    this.showThemeToggle = true,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 32),
  });

  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showThemeToggle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final authTheme = AuthScreenColors.themeFor(context);
    final scheme = authTheme.colorScheme;

    return Theme(
      data: authTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: Scaffold(
          backgroundColor: authTheme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBackButton || showThemeToggle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                    child: Row(
                      children: [
                        if (showBackButton)
                          _AuthBackButton(
                            onPressed: onBack ??
                                () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        if (showThemeToggle)
                          ThemeToggleIconButton(iconColor: scheme.onSurface),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: padding,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackButton extends StatelessWidget {
  const _AuthBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: AuthScreenColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AuthScreenColors.surfaceBorderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 26,
              color: AuthScreenColors.textPrimaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// @deprecated Use [AuthScaffold] instead.
typedef AuthDarkScaffold = AuthScaffold;
