import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/greeting_utils.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'appearance_screen.dart';
import 'personal_details_screen.dart';
import 'terms_conditions_screen.dart';
import 'notifications_screen.dart';
import 'faqs_screen.dart';
import 'change_password_screen.dart';
import 'language_screen.dart';
import 'package:hudhud_delivery/features/wishlist/presentation/screen/wishlist_screen.dart';

String _themeModeLabel(AppLocalizations l10n, ThemeController themeController) {
  switch (themeController.themeMode) {
    case ThemeMode.light:
      return l10n.themeLight;
    case ThemeMode.dark:
      return l10n.themeDark;
    case ThemeMode.system:
      return l10n.themeSystem;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  final AuthService _authService = AuthService();
  bool _smsNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserProfile(forceRefresh: true) ??
        await _authService.getStoredUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.logoutTitle),
          content: Text(l10n.logoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionLogOut),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        final authService = AuthService();
        await authService.clearAllData();

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.logoutError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final greeting = GreetingUtils.getTimeBasedGreeting(l10n);
    final userName = _user?.name?.split(' ').first ?? l10n.userDefault;
    final theme = Theme.of(context);
    final themeController = Provider.of<ThemeController>(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              l10n.settingsProfile,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.45)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.35),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: getDisplayAvatarUrl(_user) != null
                              ? Image.network(
                                  getDisplayAvatarUrl(_user)!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: AppColors.primaryColor,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/profile.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Icon(
                            Icons.verified,
                            color: AppColors.primaryColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $userName',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? '—',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: l10n.settingsAccount),
            _SectionCard(
              children: [
                _MenuItem(
                  icon: Icons.person,
                  title: l10n.settingsPersonalDetails,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalDetailsScreen(),
                      ),
                    ).then((_) => _loadUserData());
                  },
                ),
                _MenuItem(
                  icon: Icons.palette,
                  title: l10n.settingsAppearance,
                  trailing: Text(
                    _themeModeLabel(l10n, themeController),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppearanceScreen(),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  title: l10n.settingsChangePassword,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    ).then((result) {
                      if (result is String && result.isNotEmpty && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: l10n.settingsPreferences),
            _SectionCard(
              children: [
                _MenuItem(
                  icon: Icons.language,
                  title: l10n.settingsLanguage,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageScreen(),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: l10n.settingsNotifications,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (_) => createNotificationsBloc(),
                          child: const NotificationsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _MenuItemWithToggle(
                  icon: Icons.sms_outlined,
                  title: l10n.settingsSmsNotifications,
                  value: _smsNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _smsNotificationsEnabled = value;
                    });
                  },
                ),
                _MenuItem(
                  icon: Icons.favorite_border,
                  title: l10n.settingsWishlist,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WishlistScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: l10n.settingsSupport),
            _SectionCard(
              children: [
                _MenuItem(
                  icon: Icons.lock,
                  title: l10n.settingsTermsConditions,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  title: l10n.settingsFaqs,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FAQsScreen(),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.support_agent,
                  title: l10n.settingsHelpDesk,
                  onTap: () {
                    // TODO: Navigate to help desk
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MenuItem(
              icon: Icons.logout,
              title: l10n.settingsLogOut,
              onTap: () => _handleLogout(context),
              isDestructive: true,
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                l10n.settingsVersion,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemWithToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MenuItemWithToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
