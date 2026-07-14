import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

/// Always-dark chrome for screens opened from Profile, matching
/// [AuthScreenColors] independent of the app light/dark theme.
class ProfileDarkPage extends StatelessWidget {
  const ProfileDarkPage({
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
    final authTheme = AuthScreenColors.darkTheme(Theme.of(context));

    return Theme(
      data: authTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AuthScreenColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AuthScreenColors.background,
          appBar: AppBar(
            backgroundColor: AuthScreenColors.background,
            foregroundColor: AuthScreenColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: centerTitle,
            leading: leading,
            title: titleWidget ??
                Text(
                  title!,
                  style: const TextStyle(
                    color: AuthScreenColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            iconTheme:
                const IconThemeData(color: AuthScreenColors.textPrimary),
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
