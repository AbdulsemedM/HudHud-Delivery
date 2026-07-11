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
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/core/utils/support_launcher.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/setting_widget.dart';
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
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Color _pageBackground(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return theme.scaffoldBackgroundColor;
    }
    return AppColors.lightBackground;
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
        ? l10n.emDash
        : '${l10n.currencyEtb} ${_walletTotal!.toStringAsFixed(2)}';
    final avatarUrl = getDisplayAvatarUrl(_user);

    return Scaffold(
      backgroundColor: _pageBackground(theme),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ProfileHeaderCard(
                displayName: displayName,
                phone: phone,
                avatarUrl: avatarUrl,
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
                    child: SettingsStatCard(
                      icon: Icons.local_activity_outlined,
                      iconColor: colorScheme.primary,
                      title: l10n.profileCoupons,
                      value: '0',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.profileCouponsComingSoon)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SettingsStatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: colorScheme.primary,
                      title: l10n.profileWallet,
                      value: walletText,
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
              SectionHeader(title: l10n.settingsAccount),
              SettingsGroupCard(
                children: [
                  SettingsListTile(
                    icon: Icons.person_outline,
                    title: l10n.profileMenuProfile,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalDetailsScreen(),
                        ),
                      ).then((_) => _loadUserData());
                    },
                  ),
                  SettingsListTile(
                    icon: Icons.location_on_outlined,
                    title: l10n.profileMenuAddresses,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressesListScreen(),
                        ),
                      );
                    },
                  ),
                  SettingsListTile(
                    icon: Icons.favorite_outline,
                    title: l10n.profileMenuFavorites,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WishlistScreen(),
                        ),
                      );
                    },
                  ),
                  SettingsListTile(
                    icon: Icons.volunteer_activism_outlined,
                    title: l10n.tipsHistoryTitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TipsHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  SettingsListTile(
                    icon: Icons.chat_bubble_outline,
                    title: l10n.profileMenuMessages,
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
                  if (!kIsWeb)
                    SettingsSwitchTile(
                      icon: _useFaceBiometricIcon
                          ? Icons.face_outlined
                          : Icons.fingerprint_outlined,
                      iconColor: colorScheme.primary,
                      title: l10n.settingsBiometricLogin,
                      subtitle: l10n.settingsBiometricLoginSubtitle,
                      value: _biometricEnabled,
                      onChanged: _biometricAvailable && !_biometricBusy
                          ? _onBiometricLoginChanged
                          : null,
                    ),
                  SettingsListTile(
                    icon: Icons.manage_accounts_outlined,
                    title: l10n.profileMenuAccountSettings,
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
              SectionHeader(title: l10n.sosSettingsTitle),
              SettingsGroupCard(
                children: [
                  SettingsListTile(
                    icon: Icons.sos_outlined,
                    title: l10n.sosSettingsTitle,
                    iconColor: AppColors.errorColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SosSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(title: l10n.settingsPreferences),
              SettingsGroupCard(
                children: [
                  SettingsListTile(
                    icon: Icons.settings_outlined,
                    title: l10n.settingsGeneralPreferences,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppearanceScreen(),
                        ),
                      );
                    },
                  ),
                  SettingsListTile(
                    icon: Icons.pedal_bike_outlined,
                    title: l10n.settingsDeliveryPreferences,
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
                  SettingsListTile(
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
                  SettingsListTile(
                    icon: Icons.language_outlined,
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
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(title: l10n.settingsSupport),
              SettingsGroupCard(
                children: [
                  SettingsListTile(
                    icon: Icons.support_agent_outlined,
                    title: l10n.settingsSupport,
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
                  SettingsListTile(
                    icon: Icons.email_outlined,
                    title: l10n.settingsContactEmail,
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
              const SizedBox(height: 20),
              SectionHeader(title: l10n.actionLogOut),
              SettingsGroupCard(
                children: [
                  SettingsLogoutTile(
                    onTap: () => _handleLogout(context),
                  ),
                ],
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
          SettingsGroupCard(
            children: [
              SettingsListTile(
                icon: Icons.palette_outlined,
                title: l10n.settingsAppearance,
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
              SettingsListTile(
                icon: Icons.lock_outline,
                title: l10n.settingsChangePassword,
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
                          backgroundColor: AppColors.successColor,
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
          SettingsGroupCard(
            children: [
              SettingsSwitchTile(
                icon: Icons.sms_outlined,
                iconColor: colorScheme.primary,
                title: l10n.settingsSmsNotifications,
                value: _sms,
                onChanged: (v) {
                  setState(() => _sms = v);
                  widget.onSmsChanged(v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
