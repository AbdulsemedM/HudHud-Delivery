import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/support_launcher.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/addresses_list_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/sos_settings_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/conversations_list_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/support_chat_start_screen.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'package:hudhud_delivery/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'appearance_screen.dart';
import 'change_password_screen.dart';
// import 'faqs_screen.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'personal_details_screen.dart';
import 'terms_conditions_screen.dart';
import 'package:hudhud_delivery/features/wishlist/presentation/screen/wishlist_screen.dart';
import 'package:hudhud_delivery/features/tips/presentation/screens/tips_history_screen.dart';

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
  double? _walletTotal;
  PackageInfo? _packageInfo;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricBusy = false;
  bool _useFaceBiometricIcon = false;
  final BiometricCredentialService _biometricService =
      BiometricCredentialService();

  static const Color _accentIconRed = AppColors.errorColor;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadUserData(),
      _loadWalletSummary(),
      _loadPackageInfo(),
      _loadBiometricState(),
    ]);
  }

  Future<void> _loadBiometricState() async {
    if (kIsWeb) return;
    final available = await _biometricService.isDeviceSupported();
    final enabled = await _biometricService.isBiometricLoginEnabled();
    final types = await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _useFaceBiometricIcon = types.contains(BiometricType.face);
      });
    }
  }

  Future<void> _onBiometricLoginChanged(bool value) async {
    if (_biometricBusy) return;
    final l10n = context.l10n;

    if (!value) {
      setState(() => _biometricBusy = true);
      await _biometricService.setBiometricLoginEnabled(false);
      if (!mounted) return;
      setState(() {
        _biometricEnabled = false;
        _biometricBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.biometricDisabledSuccess)),
      );
      return;
    }

    if (!_biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.biometricNotAvailable)),
      );
      return;
    }

    final authenticated = await _biometricService.authenticate(
      localizedReason: l10n.biometricAuthReason,
    );
    if (!authenticated || !mounted) return;

    final saved = await _showBiometricEnableDialog();
    if (!mounted) return;
    if (saved) {
      setState(() => _biometricEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.biometricEnabledSuccess)),
      );
    }
  }

  Future<bool> _showBiometricEnableDialog() async {
    final l10n = context.l10n;
    final user = _user;
    final hasEmail = user?.email != null && user!.email!.trim().isNotEmpty;
    final fieldType = hasEmail ? 'email' : 'phone';
    final identifierController = TextEditingController(
      text: hasEmail ? user.email!.trim() : (user?.phone?.trim() ?? ''),
    );
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.biometricEnableEnterPassword),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: identifierController,
                  keyboardType: hasEmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: hasEmail ? l10n.labelEmail : l10n.labelPhone,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return hasEmail
                          ? l10n.validationEmailRequired
                          : l10n.validationPhoneRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.labelPassword,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.validationPasswordRequired;
                    }
                    if (v.length < 8) {
                      return l10n.validationPasswordMin;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.actionSave),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      identifierController.dispose();
      passwordController.dispose();
      return false;
    }

    var identifier = identifierController.text.trim();
    if (fieldType == 'phone') {
      identifier = normalizePhoneToBackend(identifier);
    }
    await _biometricService.saveCredentials(
      identifier: identifier,
      password: passwordController.text,
      fieldType: fieldType,
    );
    identifierController.dispose();
    passwordController.dispose();
    return true;
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

  Future<void> _loadWalletSummary() async {
    try {
      final repo = WalletRepository(
        walletDataProvider: WalletDataProvider(apiService: ApiService.instance),
      );
      final res = await repo.getWallets(perPage: 50);
      double total = 0;
      for (final w in res.wallets) {
        total += w.balanceAmount;
      }
      if (mounted) {
        setState(() => _walletTotal = total);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _walletTotal = null);
      }
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _packageInfo = info);
      }
    } catch (_) {}
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
        await GuestBrowseService().enterGuestBrowseMode();

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
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

  Color _pageBackground(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return theme.scaffoldBackgroundColor;
    }
    return const Color(0xFFF0F2F5);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeController = Provider.of<ThemeController>(context);
    final displayName = _user?.name?.trim().isNotEmpty == true
        ? _user!.name!.trim()
        : l10n.userDefault;
    final phone = _user?.phone?.trim().isNotEmpty == true
        ? _user!.phone!.trim()
        : l10n.emDash;

    final walletText = _walletTotal == null
        ? '—'
        : '${l10n.currencyEtb} ${_walletTotal!.toStringAsFixed(2)}';

    return Scaffold(
      backgroundColor: _pageBackground(theme),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _ProfileHeaderCard(
                displayName: displayName,
                phone: phone,
                user: _user,
                accentRed: _accentIconRed,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ).then((_) => _loadUserData());
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_activity_outlined,
                      iconColor: _accentIconRed,
                      title: l10n.profileCoupons,
                      value: '0',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.profileCouponsComingSoon)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: _accentIconRed,
                      title: l10n.profileWallet,
                      value: walletText,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletScreen(),
                          ),
                        ).then((_) => _loadWalletSummary());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionHeading(title: l10n.settingsAccount),
              _KlikSectionCard(
                colorScheme: colorScheme,
                children: [
                  _KlikTile(
                    icon: Icons.person_outline,
                    iconColor: _accentIconRed,
                    title: l10n.profileMenuProfile,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalDetailsScreen(),
                        ),
                      ).then((_) => _loadUserData());
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.location_on_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.profileMenuAddresses,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressesListScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.sos_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.sosSettingsTitle,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SosSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.favorite_outline,
                    iconColor: _accentIconRed,
                    title: l10n.profileMenuFavorites,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WishlistScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.volunteer_activism_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.tipsHistoryTitle,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TipsHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.chat_bubble_outline,
                    iconColor: _accentIconRed,
                    title: l10n.profileMenuMessages,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ConversationsListScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  if (!kIsWeb)
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: Icon(
                        _useFaceBiometricIcon
                            ? Icons.face_outlined
                            : Icons.fingerprint_outlined,
                        color: _accentIconRed,
                      ),
                      title: Text(
                        l10n.settingsBiometricLogin,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        l10n.settingsBiometricLoginSubtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _biometricEnabled,
                      onChanged: _biometricAvailable && !_biometricBusy
                          ? _onBiometricLoginChanged
                          : null,
                    ),
                  if (!kIsWeb) _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.manage_accounts_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.profileMenuAccountSettings,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _AccountSettingsHubPage(
                            themeModeLabel:
                                _themeModeLabel(l10n, themeController),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeading(title: l10n.settingsPreferences),
              _KlikSectionCard(
                colorScheme: colorScheme,
                children: [
                  _KlikTile(
                    icon: Icons.settings_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.settingsGeneralPreferences,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppearanceScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.pedal_bike_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.settingsDeliveryPreferences,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _DeliveryPreferencesPage(
                            smsEnabled: _smsNotificationsEnabled,
                            onSmsChanged: (v) {
                              setState(() => _smsNotificationsEnabled = v);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeading(title: l10n.settingsAppSettings),
              _KlikSectionCard(
                colorScheme: colorScheme,
                children: [
                  _KlikTile(
                    icon: Icons.notifications_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.settingsNotifications,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
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
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.language_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.settingsLanguage,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.support_agent_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.settingsSupport,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SupportChatStartScreen(),
                        ),
                      );
                    },
                  ),
                  _tileDivider(colorScheme),
                  _KlikTile(
                    icon: Icons.email_outlined,
                    iconColor: _accentIconRed,
                    title: l10n.settingsContactEmail,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () async {
                      final ok = await launchSupportEmail();
                      if (context.mounted && !ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.actionTryAgain)),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentIconRed,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.6),
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: colorScheme.surface,
                  ),
                  onPressed: () => _handleLogout(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: _accentIconRed, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        l10n.actionLogOut,
                        style: textTheme.titleSmall?.copyWith(
                          color: _accentIconRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _LegalFooter(
                colorScheme: colorScheme,
                textTheme: textTheme,
                packageInfo: _packageInfo,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _tileDivider(ColorScheme colorScheme) {
  return Divider(
    height: 1,
    thickness: 1,
    indent: 52,
    color: colorScheme.outlineVariant.withOpacity(0.35),
  );
}

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _KlikSectionCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<Widget> children;

  const _KlikSectionCard({
    required this.colorScheme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.35 : 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _KlikTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final Widget? trailing;

  const _KlikTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.65),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(isDark ? 0.35 : 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String phone;
  final UserModel? user;
  final Color accentRed;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({
    required this.displayName,
    required this.phone,
    required this.user,
    required this.accentRed,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final avatarUrl = getDisplayAvatarUrl(user);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.35 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        phone,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.profileEdit,
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _LoyaltyRibbon(),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl != null) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentRed, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar(),
          ),
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentRed,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 34),
    );
  }
}

/// Decorative loyalty-style badge (not tied to a backend tier).
class _LoyaltyRibbon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFFC107),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final PackageInfo? packageInfo;
  final AppLocalizations l10n;

  const _LegalFooter({
    required this.colorScheme,
    required this.textTheme,
    required this.packageInfo,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year.toString();
    final versionLine = packageInfo != null
        ? l10n.profileVersionFormatted(
            packageInfo!.version,
            packageInfo!.buildNumber,
          )
        : l10n.settingsVersion;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsConditionsScreen(),
                  ),
                );
              },
              child: Text(
                l10n.profileTermsOfUse,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '•',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsConditionsScreen(),
                  ),
                );
              },
              child: Text(
                l10n.profilePrivacyPolicy,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.profileCopyright(year),
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.85),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          versionLine,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _AccountSettingsHubPage extends StatelessWidget {
  final String themeModeLabel;

  const _AccountSettingsHubPage({required this.themeModeLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.profileMenuAccountSettings),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KlikSectionCard(
            colorScheme: colorScheme,
            children: [
              _KlikTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.errorColor,
                title: l10n.settingsAppearance,
                colorScheme: colorScheme,
                textTheme: textTheme,
                trailing: Text(
                  themeModeLabel,
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
              _tileDivider(colorScheme),
              _KlikTile(
                icon: Icons.lock_outline,
                iconColor: AppColors.errorColor,
                title: l10n.settingsChangePassword,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  ).then((result) {
                    if (result is String &&
                        result.isNotEmpty &&
                        context.mounted) {
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
        ],
      ),
    );
  }
}

class _DeliveryPreferencesPage extends StatefulWidget {
  final bool smsEnabled;
  final ValueChanged<bool> onSmsChanged;

  const _DeliveryPreferencesPage({
    required this.smsEnabled,
    required this.onSmsChanged,
  });

  @override
  State<_DeliveryPreferencesPage> createState() =>
      _DeliveryPreferencesPageState();
}

class _DeliveryPreferencesPageState extends State<_DeliveryPreferencesPage> {
  late bool _sms;

  @override
  void initState() {
    super.initState();
    _sms = widget.smsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settingsDeliveryPreferences),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.35),
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              secondary: Icon(
                Icons.sms_outlined,
                color: AppColors.errorColor,
              ),
              title: Text(l10n.settingsSmsNotifications),
              value: _sms,
              onChanged: (v) {
                setState(() => _sms = v);
                widget.onSmsChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
