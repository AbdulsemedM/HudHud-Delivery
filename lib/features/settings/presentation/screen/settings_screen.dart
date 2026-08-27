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
                    if (v.length < 6) {
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
        ? ''
        : '${l10n.currencyEtb} ${_walletTotal!.toStringAsFixed(2)}';

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
                padding: EdgeInsets.fromLTRB(16, 8, 16, 28),
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
                  SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileStatCard(
                          icon: Icons.local_activity_outlined,
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
                      SizedBox(width: 12),
                      Expanded(
                        child: _ProfileStatCard(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AuthScreenColors.lavender,
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
                  SizedBox(height: 22),
                  _ProfileSectionLabel(title: l10n.settingsAccount),
                  _ProfileGroupCard(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.person_outline,
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
                        icon: Icons.location_on_outlined,
                        title: l10n.profileMenuAddresses,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddressesListScreen(),
                            ),
                          );
                        },
                      ),
                      const _ProfileTileDivider(),
                      _ProfileMenuTile(
                        icon: Icons.shield_outlined,
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
                        icon: Icons.chat_bubble_outline,
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
                    ],
                  ),
                  SizedBox(height: 14),
                  _ProfileGroupCard(
                    children: [
                      if (!kIsWeb) ...[
                        _ProfileBiometricTile(
                          useFaceIcon: _useFaceBiometricIcon,
                          enabled: _biometricEnabled,
                          deviceSupported: _biometricAvailable,
                          switchEnabled: _biometricAvailable && !_biometricBusy,
                          hasCredentials: _biometricHasCredentials,
                          onChanged: _onBiometricLoginChanged,
                        ),
                        // const _ProfileTileDivider(),
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
                  SizedBox(height: 20),
                  _ProfileSectionLabel(title: l10n.settingsPreferences),
                  _ProfileGroupCard(
                    children: [
                      _ProfileMenuTile(
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
                  SizedBox(height: 20),
                  _ProfileSectionLabel(title: l10n.settingsAppSettings),
                  _ProfileGroupCard(
                    children: [
                      _ProfileMenuTile(
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
                      const _ProfileTileDivider(),
                      _ProfileMarketingConsentTile(
                        enabled: _user?.marketingConsent ?? false,
                        switchEnabled: !_marketingConsentBusy,
                        onChanged: _onMarketingConsentChanged,
                      ),
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
                      const _ProfileTileDivider(),
                      _ProfileMenuTile(
                        icon: Icons.headset_mic_outlined,
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
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuthScreenColors.orange,
                        side: BorderSide(
                          color: AuthScreenColors.orange,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: AuthScreenColors.surfaceOf(context),
                      ),
                      onPressed: () => _handleLogout(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AuthScreenColors.orange,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            l10n.actionLogOut,
                            style: TextStyle(
                              color: AuthScreenColors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
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

class _ProfileSectionLabel extends StatelessWidget {
  final String title;

  const _ProfileSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
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
    return Container(
      decoration: BoxDecoration(
        color: AuthScreenColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
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
      indent: 60,
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

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
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
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AuthScreenColors.orange.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: AuthScreenColors.orange, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: AuthScreenColors.textSecondaryOf(context),
                size: 22,
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AuthScreenColors.orange.withValues(alpha: 0.12),
            ),
            child: Icon(
              useFaceIcon ? Icons.face_outlined : Icons.fingerprint_outlined,
              color: AuthScreenColors.orange,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsBiometricLogin,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _subtitle(l10n),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AuthScreenColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          _ProfileGradientSwitch(
            value: enabled,
            onChanged: switchEnabled ? onChanged : null,
          ),
        ],
      ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AuthScreenColors.orange.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: AuthScreenColors.orange,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.easyMode,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  l10n.easyModeSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AuthScreenColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          _ProfileGradientSwitch(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AuthScreenColors.orange.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: AuthScreenColors.orange,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsMarketingOffers,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  l10n.settingsMarketingOffersSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AuthScreenColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          _ProfileGradientSwitch(
            value: enabled,
            onChanged: switchEnabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _ProfileGradientSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ProfileGradientSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 30,
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value
              ? const LinearGradient(
                  colors: AuthScreenColors.signInGradient,
                )
              : null,
          color: value ? null : AuthScreenColors.surfaceBorderOf(context),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: AuthScreenColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: iconColor.withValues(alpha: 0.15),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AuthScreenColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AuthScreenColors.textSecondaryOf(context),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AuthScreenColors.textPrimaryOf(context),
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
  final VoidCallback onEdit;

  const _ProfileHeaderCard({
    required this.displayName,
    required this.phone,
    required this.user,
    required this.onEdit,
  });

  String get _initial {
    final name = displayName.trim();
    if (name.isEmpty || name == '') return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final avatarUrl = getDisplayAvatarUrl(user);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthScreenColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(imageUrl: avatarUrl, initial: _initial),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: AuthScreenColors.textSecondaryOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_outlined, size: 14),
                      label: Text(l10n.profileEdit),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuthScreenColors.orange,
                        side: BorderSide(color: AuthScreenColors.orange),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: const StadiumBorder(),
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 6),
          const _LoyaltyRibbon(),
        ],
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
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AuthScreenColors.lavender.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? UserAvatar(
                radius: 30,
                imageUrl: imageUrl,
                backgroundColor: AuthScreenColors.surfaceBorderOf(context),
              )
            : Container(
                color: AuthScreenColors.surfaceBorderOf(context),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Decorative loyalty-style badge (not tied to a backend tier).
class _LoyaltyRibbon extends StatelessWidget {
  const _LoyaltyRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuthScreenColors.orange,
            Color(0xFFFFC107),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AuthScreenColors.orange.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.workspace_premium_rounded,
        color: Theme.of(context).colorScheme.onPrimary,
        size: 24,
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

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AuthScreenColors.orange,
                padding: EdgeInsets.symmetric(horizontal: 4),
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
                style: TextStyle(
                  color: AuthScreenColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'â¢',
              style: TextStyle(
                color: AuthScreenColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AuthScreenColors.orange,
                padding: EdgeInsets.symmetric(horizontal: 4),
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
                style: TextStyle(
                  color: AuthScreenColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          l10n.profileCopyright(year),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthScreenColors.textSecondaryOf(context).withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
        SizedBox(height: 6),
        Text(
          versionLine,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthScreenColors.textSecondaryOf(context).withValues(alpha: 0.75),
            fontSize: 11,
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AuthScreenColors.orange.withValues(alpha: 0.12),
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

