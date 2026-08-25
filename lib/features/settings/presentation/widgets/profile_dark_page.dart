import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

/// Theme-aware chrome for screens opened from Profile.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.leading,
    this.centerTitle = false,
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? leading;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final authTheme = AuthScreenColors.themeFor(context);
    final scheme = authTheme.colorScheme;

    return Theme(
      data: authTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            backgroundColor: authTheme.scaffoldBackgroundColor,
            foregroundColor: scheme.onSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: centerTitle,
            leading: leading,
            title: titleWidget ??
                Text(
                  title!,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            iconTheme: IconThemeData(color: scheme.onSurface),
            actions: actions,
          ),
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }
}

/// @deprecated Use [ProfilePage] instead.
typedef ProfileDarkPage = ProfilePage;
