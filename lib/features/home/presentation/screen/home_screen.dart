import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/notifications_screen.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/all_categories_screen.dart';
import 'package:hudhud_delivery/features/handyman/presentation/screens/handyman_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/courier_screen.dart';
import 'package:hudhud_delivery/features/taxi/presentation/screens/taxi_screen.dart';
import '../widgets/home_service_tab_bar.dart';
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
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/addresses/presentation/widgets/delivery_address_selector.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

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

  HomeServiceMode _serviceMode = HomeServiceMode.foodGroceries;

  bool _verificationPromptOpen = false;
  bool _verifyBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.homeTabActivation.addListener(_onHomeTabActivation);
    _loadUserData();
    _requestLocationAndUpdate(resumeRefresh: false);
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
    // Fetch fresh profile from API to get updated verification status; fallback to stored user
    final user = await _authService.getUserProfile() ??
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
    if (user?.phone == null || user!.phone!.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerifyPhoneDialog(
        phone: user.phone!,
        authService: _authService,
      ),
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
                      AllCategoriesScreen(embedded: true),
                      CourierScreen(),
                      TaxiScreen(),
                      HandymanScreen(embedded: true),
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
      title: const Text('Verify Email'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We sent a verification code to ${widget.email}. Enter it below.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                hintText: 'e.g. 111248',
                border: OutlineInputBorder(),
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
              label: Text(_isSending ? 'Sending...' : 'Resend code'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}

class _VerifyPhoneDialog extends StatefulWidget {
  final String phone;
  final AuthService authService;

  const _VerifyPhoneDialog({
    required this.phone,
    required this.authService,
  });

  @override
  State<_VerifyPhoneDialog> createState() => _VerifyPhoneDialogState();
}

class _VerifyPhoneDialogState extends State<_VerifyPhoneDialog> {
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
    final result =
        await widget.authService.sendPhoneVerificationCode(widget.phone);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result['success'] == true) {
      SnackbarUtil.showSuccess(
          context, result['message'] ?? 'Code sent to your phone.');
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
    final result = await widget.authService.verifyPhone(
      phone: widget.phone,
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
      title: const Text('Verify Phone'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We sent a verification code to ${widget.phone}. Enter it below.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                hintText: 'e.g. 056869',
                border: OutlineInputBorder(),
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
                  : const Icon(Icons.sms_outlined, size: 18),
              label: Text(_isSending ? 'Sending...' : 'Resend code'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
