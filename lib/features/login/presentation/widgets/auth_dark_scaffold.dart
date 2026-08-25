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
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 28),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        if (showBackButton)
                          IconButton(
                            onPressed:
                                onBack ?? () => Navigator.of(context).maybePop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: scheme.onSurface,
                            ),
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

/// @deprecated Use [AuthScaffold] instead.
typedef AuthDarkScaffold = AuthScaffold;
