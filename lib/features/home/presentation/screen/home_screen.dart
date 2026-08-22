import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/notifications_screen.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
// import 'package:hudhud_delivery/features/delivery/presentation/screens/all_categories_screen.dart';
// import 'package:hudhud_delivery/features/handyman/presentation/screens/handyman_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/courier_screen.dart';
// import 'package:hudhud_delivery/features/taxi/presentation/screens/taxi_screen.dart';
import '../widgets/home_service_tab_bar.dart';
import '../widgets/service_coming_soon_screen.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/geocoding_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/saved_location_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/controllers/service_accent_controller.dart';
import 'package:hudhud_delivery/core/utils/snackbar_util.dart';
import '../../bloc/home_bloc.dart';
import '../widgets/home_widget.dart';
import '../../data/repository/home_repository.dart';
import '../../data/data_provider/home_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_repository.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
import 'package:hudhud_delivery/core/widgets/verify_phone_dialog.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_navigation.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/addresses/presentation/widgets/delivery_address_selector.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_controller.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_keys.dart';

class HomeScreen extends StatefulWidget {
  /// Incremented whenever the user selects the Home tab (including first open).
  final ValueNotifier<int> homeTabActivation;

  const HomeScreen({super.key, required this.homeTabActivation});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class HomeScreenWrapper extends StatelessWidget {
  final ValueNotifier<int> homeTabActivation;

  const HomeScreenWrapper({super.key, required this.homeTabActivation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        homeRepository: HomeRepository(
          homeDataProvider: HomeDataProvider(
            apiService: ApiService.instance,
          ),
        ),
      )..add(GetCategoriesEvent()),
      child: HomeScreen(homeTabActivation: homeTabActivation),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  bool _syncedServiceAccent = false;

  UserModel? _currentUser;
  String _currentLocation = '';
  bool _isLoadingLocation = true;

  HomeServiceMode _serviceMode = HomeServiceMode.courier;

  bool _verificationPromptOpen = false;
  bool _verifyBannerDismissed = false;

  final OnboardingTourKeys _tourKeys = OnboardingTourKeys();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.homeTabActivation.addListener(_onHomeTabActivation);
    OnboardingTourController.replaySignal.addListener(_onReplayTourRequested);
    _loadUserData();
    _requestLocationAndUpdate(resumeRefresh: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartOnboardingTour());
  }

  void _maybeStartOnboardingTour() {
    if (!mounted) return;
    OnboardingTourController.maybeStart(
      context: context,
      keys: _tourKeys,
    );
  }

  void _onReplayTourRequested() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartOnboardingTour());
  }

  void _onHomeTabActivation() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_syncedServiceAccent) {
      _syncedServiceAccent = true;
      context.read<ServiceAccentController>().updateHomeServiceMode(_serviceMode);
    }
  }

  @override
  void dispose() {
    widget.homeTabActivation.removeListener(_onHomeTabActivation);
    OnboardingTourController.replaySignal.removeListener(_onReplayTourRequested);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestLocationAndUpdate(resumeRefresh: true);
    }
  }

  Future<void> _loadUserData() async {
    if (GuestBrowseService().isGuestBrowseMode) {
      if (mounted) setState(() => _currentUser = null);
      return;
    }
    // Always hit the API after login / tab return so verification + name stay current.
    final user = await _authService.getUserProfile(forceRefresh: true) ??
        await _authService.getStoredUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryShowVerificationPrompt();
      });
    }
  }

  /// Shows when Home tab is selected and email or phone still needs verification.
  Future<void> _tryShowVerificationPrompt() async {
    if (!mounted) return;
    if (!context.read<ServiceAccentController>().isOnHomeTab) return;
    final u = _currentUser;
    if (u == null) return;
    if (u.isEmailVerified && u.isPhoneVerified) return;
    if (_verificationPromptOpen) return;

    _verificationPromptOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AccountVerificationPromptDialog(
          user: u,
          onDismiss: () => Navigator.of(ctx).pop(),
          onVerifyEmail: () {
            Navigator.of(ctx).pop();
            _openVerifyEmailFlow();
          },
          onVerifyPhone: () {
            Navigator.of(ctx).pop();
            _openVerifyPhoneFlow();
          },
        ),
      );
    } finally {
      if (mounted) {
        _verificationPromptOpen = false;
      }
    }
  }

  /// Shows live GPS as the home header. Splash runs [StartupLocationService.fetchFreshOnAppLaunch]
  /// on each app open; [resumeRefresh] forces a new read when returning from background.
  Future<void> _requestLocationAndUpdate({required bool resumeRefresh}) async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      if (_authService.isLoggedIn) {
        try {
          final repo = AddressesRepository(
            addressesDataProvider: AddressesDataProvider(
              apiService: ApiService.instance,
            ),
          );
          final def = await repo.getDefaultAddress();
          if (def != null && mounted) {
            setState(() {
              _currentLocation = def.displayText;
              _isLoadingLocation = false;
            });
            return;
          }
        } catch (_) {}
      }

      // On resume: check if user just granted permission in Settings, then re-fetch.
      if (resumeRefresh) {
        StartupLocationService.isPermanentlyDenied = false;
        final granted = await CustomLocationService.requestLocationPermission();
        if (granted) {
          final fix = await LocationService.getCurrentPosition();
          if (fix != null) {
            StartupLocationService.updateCache(fix);
            await _applyFix(fix);
            return;
          }
        }
      }

      // Use startup fix from splash, or fall back to a one-shot GPS read.
      final LocationData? fix =
          StartupLocationService.cached ?? await LocationService.getCurrentPosition();

      if (fix != null) {
        StartupLocationService.updateCache(fix);
        await _applyFix(fix);
        return;
      }

      // No GPS fix — check if permanently denied and prompt.
      if (StartupLocationService.isPermanentlyDenied ||
          await CustomLocationService.isLocationPermissionPermanentlyDenied()) {
        if (mounted) {
          final l10n = context.l10n;
          setState(() {
            _currentLocation = l10n.locationAccessDenied;
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationDisabledSnackbar),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: l10n.actionOpenSettings,
                onPressed: CustomLocationService.openLocationAppSettings,
              ),
            ),
          );
        }
        return;
      }

      // No GPS for another reason (services off, etc.): fall back to saved address.
      final saved = await SavedLocationService.getSavedLocationData();
      final savedAddress = saved?['address'] as String?;
      if (savedAddress != null && savedAddress.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentLocation = savedAddress;
            _isLoadingLocation = false;
          });
        }
        return;
      }

      if (mounted) {
        final l10n = context.l10n;
        setState(() {
          _currentLocation = l10n.locationUnable;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        setState(() {
          _currentLocation = l10n.locationUnable;
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _applyFix(LocationData fix) async {
    final address = await GeocodingService.getAddressFromLatLng(
      fix.latitude,
      fix.longitude,
    );
    if (mounted) {
      setState(() {
        _currentLocation = address;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _openVerifyEmailFlow() async {
    final user = _currentUser;
    if (user?.email == null || user!.email!.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerifyEmailDialog(
        email: user.email!,
        authService: _authService,
      ),
    );
      if (result == true && mounted) {
      await _loadUserData();
      if (mounted) {
        SnackbarUtil.showSuccess(context, context.l10n.emailVerifiedSuccess);
      }
    }
  }

  void _openNotifications() async {
    if (GuestBrowseService().isGuestBrowseMode) {
      final l10n = AppLocalizations.of(context)!;
      final authed = await showGuestSignInRequiredDialog(
        context,
        message: l10n.guestSignInRequiredMessage,
      );
      if (!authed) return;
      if (!context.mounted) return;
      await _loadUserData();
      if (!context.mounted) return;
    }
    if (!context.mounted) return;
    _pushNotificationsScreen();
  }

  void _pushNotificationsScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (_) => createNotificationsBloc(),
          child: const NotificationsScreen(),
        ),
      ),
    );
  }

  void _openLocationSearch() {
    showDeliveryAddressPicker(
      context: context,
      currentAddress: _currentLocation,
      onAddressChanged: ({
        required String address,
        double? latitude,
        double? longitude,
      }) {
        setState(() => _currentLocation = address);
      },
    );
  }

  Future<void> _openVerifyPhoneFlow() async {
    final user = _currentUser;
    if (user?.phone == null || user!.phone!.isEmpty) {
      final enrolled = await openPhoneEnrollmentGate(context);
      if (enrolled && mounted) {
        await _loadUserData();
        if (mounted) {
          SnackbarUtil.showSuccess(
            context,
            context.l10n.phoneVerifiedSuccess,
          );
        }
      }
      return;
    }

    final result = await showVerifyPhoneDialog(
      context,
      phone: user.phone!,
      authService: _authService,
    );
    if (result == true && mounted) {
      await _loadUserData();
      if (mounted) {
        SnackbarUtil.showSuccess(
            context, context.l10n.phoneVerifiedSuccess);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isGuest = GuestBrowseService().isGuestBrowseMode;
    final showVerify = _currentUser != null &&
        !_verifyBannerDismissed &&
        (!_currentUser!.isEmailVerified || !_currentUser!.isPhoneVerified);

    return Theme(
      data: HomeColors.darkTheme(Theme.of(context)),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: HomeColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: UserProfileHeader(
                    name: _currentUser?.name ?? l10n.userDefault,
                    location: _currentLocation,
                    isLoadingLocation: _isLoadingLocation,
                    user: _currentUser,
                    isGuest: isGuest,
                    locationKey: _tourKeys.locationKey,
                    notificationsKey: _tourKeys.notificationsKey,
                    onGuestSignIn: () async {
                      final authed =
                          await showGuestSignInRequiredDialog(context);
                      if (authed && mounted) await _loadUserData();
                    },
                    onLocationTap: _openLocationSearch,
                    onNotificationsTap: _openNotifications,
                  ),
                ),
                if (showVerify) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: VerificationStatusCard(
                      user: _currentUser!,
                      onVerifyEmail: _openVerifyEmailFlow,
                      onVerifyPhone: _openVerifyPhoneFlow,
                      onDismiss: () =>
                          setState(() => _verifyBannerDismissed = true),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                HomeServiceTabBar(
                  selected: _serviceMode,
                  tourKeys: _tourKeys,
                  onSelected: (mode) {
                    setState(() => _serviceMode = mode);
                    context
                        .read<ServiceAccentController>()
                        .updateHomeServiceMode(mode);
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _serviceMode.index,
                    children: const [
                      CourierScreen(),
                      // AllCategoriesScreen(embedded: true), // TODO: restore when Food & Groceries launches
                      ServiceComingSoonScreen(mode: HomeServiceMode.foodGroceries),
                      // TaxiScreen(), // TODO: restore when Taxi launches
                      ServiceComingSoonScreen(mode: HomeServiceMode.taxi),
                      // HandymanScreen(embedded: true), // TODO: restore when Handyman launches
                      ServiceComingSoonScreen(mode: HomeServiceMode.handyman),
                    ],
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

class _VerifyEmailDialog extends StatefulWidget {
  final String email;
  final AuthService authService;

  const _VerifyEmailDialog({
    required this.email,
    required this.authService,
  });

  @override
  State<_VerifyEmailDialog> createState() => _VerifyEmailDialogState();
}

class _VerifyEmailDialogState extends State<_VerifyEmailDialog> {
  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    final result = await widget.authService.sendEmailVerification();
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result['success'] == true) {
      SnackbarUtil.showSuccess(
          context, result['message'] ?? 'Code sent to your email.');
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter the verification code');
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    final result = await widget.authService.verifyEmail(
      email: widget.email,
      code: code,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.verifyEmailDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.verifyEmailBody(widget.email),
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: context.l10n.verificationCodeLabel,
                hintText: context.l10n.verificationCodeHintExample,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSending ? null : _sendCode,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.email_outlined, size: 18),
              label: Text(_isSending
                  ? context.l10n.actionSending
                  : context.l10n.forgotPasswordResend),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.actionVerify),
        ),
      ],
    );
  }
}
