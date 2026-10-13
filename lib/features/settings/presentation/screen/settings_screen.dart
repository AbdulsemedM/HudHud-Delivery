import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
// import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/easy_mode/easy_mode_controller.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/addresses_list_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/sos_settings_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/conversations_list_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/support_chat_start_screen.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_unread_badge.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_polling_config.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
// import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_controller.dart';
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
// import 'package:hudhud_delivery/features/wishlist/presentation/screen/wishlist_screen.dart';
// import 'package:hudhud_delivery/features/tips/presentation/screens/tips_history_screen.dart';

// String _themeModeLabel(AppLocalizations l10n, ThemeController themeController) {
//   switch (themeController.themeMode) {
//     case ThemeMode.light:
//       return l10n.themeLight;
//     case ThemeMode.dark:
//       return l10n.themeDark;
//     case ThemeMode.system:
//       return l10n.themeSystem;
//   }
// }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  UserModel? _user;
  final AuthService _authService = AuthService();
  // ignore: unused_field
  bool _smsNotificationsEnabled = true;
  double? _walletTotal;
  PackageInfo? _packageInfo;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricHasCredentials = false;
  bool _biometricBusy = false;
  bool _useFaceBiometricIcon = false;
  bool _marketingConsentBusy = false;
  int _chatUnreadCount = 0;
  Timer? _chatUnreadTimer;
  final BiometricCredentialService _biometricService =
      BiometricCredentialService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
    _startChatUnreadPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatUnreadTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _stopChatUnreadPolling();
      case AppLifecycleState.resumed:
        _startChatUnreadPolling(immediate: true);
      case AppLifecycleState.detached:
        break;
    }
  }

  void _startChatUnreadPolling({bool immediate = false}) {
    _chatUnreadTimer?.cancel();
    if (immediate) unawaited(_fetchChatUnreadCount());
    _chatUnreadTimer = Timer.periodic(
      ChatPollingConfig.unreadBadgeInterval,
      (_) => _fetchChatUnreadCount(),
    );
  }

  void _stopChatUnreadPolling() {
    _chatUnreadTimer?.cancel();
    _chatUnreadTimer = null;
  }

  Future<void> _fetchChatUnreadCount() async {
    try {
      final count = await createChatRepository().getUnreadCount();
      if (mounted) setState(() => _chatUnreadCount = count);
    } catch (_) {}
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
    final hasCredentials = await _biometricService.hasCredentialBlob();
    final types = await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricHasCredentials = hasCredentials;
        _useFaceBiometricIcon = types.contains(BiometricType.face);
      });
    }
  }

  Future<void> _onBiometricLoginChanged(bool value) async {
    if (_biometricBusy) return;
    final l10n = context.l10n;

    if (!value) {
      setState(() => _biometricBusy = true);
      await _biometricService.optOut();
      if (!mounted) return;
      setState(() {
        _biometricEnabled = false;
        _biometricBusy = false;
      });
      AuthSnackBar.success(context, l10n.biometricDisabledSuccess);
      return;
    }

    if (!_biometricAvailable) {
      AuthSnackBar.info(context, l10n.biometricNotAvailable);
      return;
    }

    final authenticated = await _biometricService.authenticate(
      localizedReason: l10n.biometricAuthReason,
    );
    if (!authenticated || !mounted) return;

    if (await _biometricService.hasCredentialBlob()) {
      setState(() => _biometricBusy = true);
      final ok = await _biometricService.enableBiometricLogin();
      if (!mounted) return;
      setState(() {
        _biometricEnabled = ok;
        _biometricHasCredentials = true;
        _biometricBusy = false;
      });
      if (ok) {
        AuthSnackBar.success(context, l10n.biometricEnabledSuccess);
      } else {
        AuthSnackBar.info(context, l10n.biometricNoCredentials);
      }
      return;
    }

    final saved = await _showBiometricEnableDialog();
    if (!mounted) return;
    if (saved) {
      setState(() {
        _biometricEnabled = true;
        _biometricHasCredentials = true;
      });
      AuthSnackBar.success(context, l10n.biometricEnabledSuccess);
    }
  }

  Future<void> _onMarketingConsentChanged(bool value) async {
    if (_marketingConsentBusy) return;

    final previous = _user?.marketingConsent ?? false;
    setState(() {
      _marketingConsentBusy = true;
      _user = _user?.copyWith(marketingConsent: value);
    });

    try {
      final updated = await _authService.updateMarketingConsent(value);
      if (!mounted) return;
      setState(() {
        _user = updated;
        _marketingConsentBusy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _user = _user?.copyWith(marketingConsent: previous);
        _marketingConsentBusy = false;
      });
      AuthSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _user = _user?.copyWith(marketingConsent: previous);
        _marketingConsentBusy = false;
      });
      AuthSnackBar.error(context, e.toString());
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

    final saved = await AuthModal.dialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AuthAlertDialog(
          title: l10n.biometricEnableEnterPassword,
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
                SizedBox(height: 12),
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
                    if (v.length < 4) {
                      return l10n.validationPasswordMin;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            AuthDialogAction(
              label: l10n.actionCancel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AuthDialogAction(
              label: l10n.actionSave,
              filled: true,
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(true);
              },
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
    await _biometricService.enableBiometricLogin();
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
      final balance = await repo.getBalance();
      if (mounted) {
        setState(() => _walletTotal = balance.balance);
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
      final shouldLogout = await AuthModal.confirm(
        context: context,
        title: l10n.logoutTitle,
        message: l10n.logoutMessage,
        confirmLabel: l10n.actionLogOut,
        cancelLabel: l10n.actionCancel,
        destructive: true,
      );

      if (shouldLogout == true) {
        final authService = AuthService();
        await authService.logout();

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
        AuthSnackBar.error(context, l10n.logoutError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authTheme = AuthScreenColors.themeFor(context);
    final displayName = _user?.name?.trim().isNotEmpty == true
        ? _user!.name!.trim()
        : l10n.userDefault;
    final phone = _user?.phone?.trim().isNotEmpty == true
        ? _user!.phone!.trim()
        : l10n.emDash;

    final walletText = _walletTotal == null
        ? l10n.emDash
        : '${l10n.currencyEtb} ${_walletTotal!.toStringAsFixed(2)}';

    final indigo = _accentIndigo(context);

    return Theme(
      data: authTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: Scaffold(
          backgroundColor: AuthScreenColors.backgroundOf(context),
          body: SafeArea(
            child: RefreshIndicator(
              color: AuthScreenColors.orange,
              backgroundColor: AuthScreenColors.surfaceOf(context),
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _ProfileHeaderCard(
                    displayName: displayName,
                    phone: phone,
                    user: _user,
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
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: indigo,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.local_activity_rounded,
                            iconColor: AuthScreenColors.orange,
                            title: l10n.profileCoupons,
                            value: '0',
                            onTap: () {
                              AuthSnackBar.comingSoon(
                                context,
                                l10n.profileCouponsComingSoon,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _ProfileSectionLabel(title: l10n.settingsAccount),
                  _ProfileGroupCard(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.person_rounded,
                        color: indigo,
                        title: l10n.profileMenuProfile,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PersonalDetailsScreen(),
                            ),
                          ).then((_) => _loadUserData());
                        },
                      ),
                      const _ProfileTileDivider(),
                      _ProfileMenuTile(
                        icon: Icons.location_on_rounded,
                        color: AuthScreenColors.orange,
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
                      const _ProfileTileDivider(),
                      _ProfileMenuTile(
                        icon: Icons.shield_rounded,
                        color: AppColors.warningColor,
                        title: l10n.sosSettingsTitle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SosSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const _ProfileTileDivider(),
                      // TODO: restore when Wishlist launches
                      // _ProfileMenuTile(
                      //   icon: Icons.favorite_outline,
                      //   title: l10n.profileMenuFavorites,
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const WishlistScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // const _ProfileTileDivider(),
                      // TODO: restore when Tip history launches
                      // _ProfileMenuTile(
                      //   icon: Icons.volunteer_activism_outlined,
                      //   title: l10n.tipsHistoryTitle,
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             const TipsHistoryScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // const _ProfileTileDivider(),
                      _ProfileMenuTile(
                        icon: Icons.chat_bubble_rounded,
                        color: indigo,
                        title: l10n.profileMenuMessages,
                        trailing: ChatUnreadBadge(count: _chatUnreadCount),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ConversationsListScreen(),
                            ),
                          );
                          if (mounted) _fetchChatUnreadCount();
                        },
                      ),
                      if (!kIsWeb) ...[
                        const _ProfileTileDivider(),
                        _ProfileBiometricTile(
                          useFaceIcon: _useFaceBiometricIcon,
                          enabled: _biometricEnabled,
                          deviceSupported: _biometricAvailable,
                          switchEnabled: _biometricAvailable && !_biometricBusy,
                          hasCredentials: _biometricHasCredentials,
                          onChanged: _onBiometricLoginChanged,
                        ),
                      ],
                      // TODO: restore when Account Settings launches
                      // _ProfileMenuTile(
                      //   icon: Icons.tune_rounded,
                      //   title: l10n.profileMenuAccountSettings,
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => _AccountSettingsHubPage(
                      //           themeModeLabel:
                      //               _themeModeLabel(l10n, themeController),
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _ProfileSectionLabel(title: l10n.settingsPreferences),
                  _ProfileGroupCard(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.tune_rounded,
                        color: indigo,
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
                      // const _ProfileTileDivider(),
                      // TODO: restore when Delivery Preferences launches
                      // _ProfileMenuTile(
                      //   icon: Icons.moped_outlined,
                      //   title: l10n.settingsDeliveryPreferences,
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => _DeliveryPreferencesPage(
                      //           smsEnabled: _smsNotificationsEnabled,
                      //           onSmsChanged: (v) {
                      //             setState(() => _smsNotificationsEnabled = v);
                      //           },
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                      const _ProfileTileDivider(),
                      Consumer<EasyModeController>(
                        builder: (context, easyMode, _) {
                          return _ProfileEasyModeTile(
                            enabled: easyMode.enabled,
                            onChanged: (v) => easyMode.setEnabled(v),
                          );
                        },
                      ),
                      const _ProfileTileDivider(),
                      _ProfileMenuTile(
                        icon: Icons.translate_rounded,
                        color: indigo,
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
                  // TODO: restore when home tour replay is needed
                  // if (kDebugMode) ...[
                  //   SizedBox(height: 20),
                  //   const _ProfileSectionLabel(title: 'Developer'),
                  //   _ProfileGroupCard(
                  //     children: [
                  //       _ProfileMenuTile(
                  //         icon: Icons.tour_outlined,
                  //         title: l10n.onboardingDebugReplayTour,
                  //         onTap: () async {
                  //           await OnboardingTourController.resetForTesting();
                  //           if (!context.mounted) return;
                  //           ScaffoldMessenger.of(context).showSnackBar(
                  //             SnackBar(
                  //               content: Text(l10n.onboardingDebugReplayTour),
                  //             ),
                  //           );
                  //         },
                  //       ),
                  //     ],
                  //   ),
                  // ],
                  const SizedBox(height: 26),
                  _ProfileSectionLabel(title: l10n.settingsAppSettings),
                  _ProfileGroupCard(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.notifications_rounded,
                        color: AuthScreenColors.orange,
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
                      const _ProfileTileDivider(),
                      _ProfileMarketingConsentTile(
                        enabled: _user?.marketingConsent ?? false,
                        switchEnabled: !_marketingConsentBusy,
                        onChanged: _onMarketingConsentChanged,
                      ),
                      const _ProfileTileDivider(),
                      _ProfileMenuTile(
                        icon: Icons.headset_mic_rounded,
                        color: AppColors.successColor,
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
                      // TODO: restore as a top-level settings item if needed
                      // const _ProfileTileDivider(),
                      // _ProfileMenuTile(
                      //   icon: Icons.email_outlined,
                      //   title: l10n.settingsContactEmail,
                      //   onTap: () async {
                      //     final ok = await launchSupportEmail();
                      //     if (context.mounted && !ok) {
                      //       AuthSnackBar.error(context, l10n.actionTryAgain);
                      //     }
                      //   },
                      // ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _ProfileGroupCard(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.logout_rounded,
                        color: AppColors.errorColor,
                        title: l10n.actionLogOut,
                        titleColor: AppColors.errorColor,
                        showChevron: false,
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _LegalFooter(
                    packageInfo: _packageInfo,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand indigo tuned for the current brightness.
Color _accentIndigo(BuildContext context) => AuthScreenColors.isDark(context)
    ? AppColors.brandIndigoBright
    : AppColors.brandIndigo;

/// 44px rounded tile with a soft tint fill behind an icon.
class _TintIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TintIconTile({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: dark ? 0.2 : 0.11),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  final String title;

  const _ProfileSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AuthScreenColors.textMutedOf(context),
        ),
      ),
    );
  }
}

class _ProfileGroupCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: AuthScreenColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark
              ? BorderSide(color: AuthScreenColors.surfaceBorderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _ProfileTileDivider extends StatelessWidget {
  const _ProfileTileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: AuthScreenColors.surfaceBorderOf(context),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;
  final Color? titleColor;
  final bool showChevron;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.color,
    this.titleColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _TintIconTile(
                icon: icon,
                color: color ?? _accentIndigo(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                    color:
                        titleColor ?? AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 4),
              ],
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AuthScreenColors.textMutedOf(context),
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row with an icon tile, title + hint, and a trailing switch.
class _ProfileSwitchRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ProfileSwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _TintIconTile(icon: icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                        color: AuthScreenColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AuthScreenColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ProfileGradientSwitch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBiometricTile extends StatelessWidget {
  final bool useFaceIcon;
  final bool enabled;
  final bool deviceSupported;
  final bool switchEnabled;
  final bool hasCredentials;
  final ValueChanged<bool> onChanged;

  const _ProfileBiometricTile({
    required this.useFaceIcon,
    required this.enabled,
    required this.deviceSupported,
    required this.switchEnabled,
    required this.hasCredentials,
    required this.onChanged,
  });

  String _subtitle(AppLocalizations l10n) {
    if (!deviceSupported) return l10n.biometricNotAvailable;
    if (enabled) return l10n.settingsBiometricSubtitleEnabled;
    if (hasCredentials) return l10n.settingsBiometricSubtitleOffReady;
    return l10n.settingsBiometricSubtitleSignInOnce;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _ProfileSwitchRow(
      icon: useFaceIcon ? Icons.face_rounded : Icons.fingerprint_rounded,
      color: _accentIndigo(context),
      title: l10n.settingsBiometricLogin,
      subtitle: _subtitle(l10n),
      value: enabled,
      onChanged: switchEnabled ? onChanged : null,
    );
  }
}

class _ProfileEasyModeTile extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ProfileEasyModeTile({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _ProfileSwitchRow(
      icon: Icons.accessibility_new_rounded,
      color: AppColors.successColor,
      title: l10n.easyMode,
      subtitle: l10n.easyModeSubtitle,
      value: enabled,
      onChanged: onChanged,
    );
  }
}

class _ProfileMarketingConsentTile extends StatelessWidget {
  final bool enabled;
  final bool switchEnabled;
  final ValueChanged<bool> onChanged;

  const _ProfileMarketingConsentTile({
    required this.enabled,
    required this.switchEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _ProfileSwitchRow(
      icon: Icons.campaign_rounded,
      color: AuthScreenColors.orange,
      title: l10n.settingsMarketingOffers,
      subtitle: l10n.settingsMarketingOffersSubtitle,
      value: enabled,
      onChanged: switchEnabled ? onChanged : null,
    );
  }
}

/// Large, high-contrast on/off switch (indigo when on).
class _ProfileGradientSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ProfileGradientSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Semantics(
      toggled: value,
      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => onChanged!(!value),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Opacity(
              opacity: disabled ? 0.5 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 54,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: value
                      ? _accentIndigo(context)
                      : AuthScreenColors.surfaceBorderOf(context),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x29000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ProfileStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: AuthScreenColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark
              ? BorderSide(color: AuthScreenColors.surfaceBorderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TintIconTile(icon: icon, color: iconColor),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: AuthScreenColors.textMutedOf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AuthScreenColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      color: AuthScreenColors.textPrimaryOf(context),
                    ),
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

class _ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String phone;
  final UserModel? user;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({
    required this.displayName,
    required this.phone,
    required this.user,
    required this.onEdit,
  });

  String get _initial {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final avatarUrl = getDisplayAvatarUrl(user);
    final dark = AuthScreenColors.isDark(context);
    const radius = BorderRadius.all(Radius.circular(24));

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandHeroGradient,
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.brandIndigo.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Soft decorative rings give the hero card depth.
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -70,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _ProfileAvatar(imageUrl: avatarUrl, initial: _initial),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            height: 1.15,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onEdit,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.profileEdit,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initial;

  const _ProfileAvatar({
    required this.imageUrl,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.white.withValues(alpha: 0.16),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
    return Container(
      width: 78,
      height: 78,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 2.5,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? UserAvatar(
                radius: 34,
                imageUrl: imageUrl,
                name: initial,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              )
            : placeholder,
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  final PackageInfo? packageInfo;
  final AppLocalizations l10n;

  const _LegalFooter({
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
    final linkColor = AuthScreenColors.textSecondaryOf(context);
    final muted = AuthScreenColors.textMutedOf(context);

    Widget link(String label) => TextButton(
          style: TextButton.styleFrom(
            foregroundColor: linkColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(48, 44),
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
            label,
            style: TextStyle(
              color: linkColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: link(l10n.profileTermsOfUse)),
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: muted,
                shape: BoxShape.circle,
              ),
            ),
            Flexible(child: link(l10n.profilePrivacyPolicy)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.profileCopyright(year),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          versionLine,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _AccountSettingsHubPage extends StatelessWidget {
  final String themeModeLabel;

  // ignore: unused_element
  const _AccountSettingsHubPage({required this.themeModeLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Theme(
      data: AuthScreenColors.themeFor(context),
      child: Scaffold(
        backgroundColor: AuthScreenColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AuthScreenColors.backgroundOf(context),
          foregroundColor: AuthScreenColors.textPrimaryOf(context),
          title: Text(l10n.profileMenuAccountSettings),
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _ProfileGroupCard(
              children: [
                _ProfileMenuTile(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsAppearance,
                  trailing: Text(
                    themeModeLabel,
                    style: TextStyle(
                      color: AuthScreenColors.textSecondaryOf(context),
                      fontSize: 12,
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
                const _ProfileTileDivider(),
                _ProfileMenuTile(
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
                        AuthSnackBar.success(context, result);
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _DeliveryPreferencesPage extends StatefulWidget {
  final bool smsEnabled;
  final ValueChanged<bool> onSmsChanged;

  // ignore: unused_element
  const _DeliveryPreferencesPage({
    required this.smsEnabled,
    required this.onSmsChanged,
  });

  @override
  State<_DeliveryPreferencesPage> createState() =>
      _DeliveryPreferencesPageState();
}

// ignore: unused_element
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

    return Theme(
      data: AuthScreenColors.themeFor(context),
      child: Scaffold(
        backgroundColor: AuthScreenColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AuthScreenColors.backgroundOf(context),
          foregroundColor: AuthScreenColors.textPrimaryOf(context),
          title: Text(l10n.settingsDeliveryPreferences),
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _ProfileGroupCard(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              AuthScreenColors.orange.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.sms_outlined,
                          color: AuthScreenColors.orange,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.settingsSmsNotifications,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: AuthScreenColors.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      _ProfileGradientSwitch(
                        value: _sms,
                        onChanged: (v) {
                          setState(() => _sms = v);
                          widget.onSmsChanged(v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
