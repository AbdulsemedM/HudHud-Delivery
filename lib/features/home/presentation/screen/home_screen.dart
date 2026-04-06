import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/all_categories_screen.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_model.dart';
import 'package:hudhud_delivery/features/orders/bloc/orders_bloc.dart';
import 'package:hudhud_delivery/features/orders/data/repositories/orders_repository.dart';
import 'package:hudhud_delivery/features/orders/presentation/screen/order_details_screen.dart';
import 'package:hudhud_delivery/features/orders/presentation/screen/orders_screen.dart';
import 'package:hudhud_delivery/features/handyman/presentation/screens/handyman_screen.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/geocoding_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/saved_location_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/snackbar_util.dart';
import '../../bloc/home_bloc.dart';
import '../widgets/home_widget.dart';
import '../../data/repository/home_repository.dart';
import '../../data/data_provider/home_data_provider.dart';
import 'location_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onSwitchToTab,
  });

  final void Function(int index)? onSwitchToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({
    super.key,
    this.onSwitchToTab,
  });

  final void Function(int index)? onSwitchToTab;

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
      child: HomeScreen(onSwitchToTab: onSwitchToTab),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String _currentLocation = 'Getting location...';
  bool _isLoadingLocation = true;

  List<OrderModel> _availableOrders = [];
  bool _ordersLoading = true;
  String? _ordersError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _requestLocationAndUpdate(resumeRefresh: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailableOrders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestLocationAndUpdate(resumeRefresh: true);
    }
  }

  Future<void> _loadAvailableOrders() async {
    final repo = context.read<OrdersRepository>();
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
    });
    try {
      final orders = await repo.fetchAvailableOrders();
      if (mounted) {
        setState(() {
          _availableOrders = orders;
          _ordersLoading = false;
          _ordersError = null;
        });
        _showDealsModalIfEmpty();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableOrders = [];
          _ordersLoading = false;
          _ordersError = e.toString();
        });
      }
    }
  }

  void _showDealsModalIfEmpty() {
    if (!_ordersLoading && _availableOrders.isEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDealsModal(context);
      });
    }
  }

  void _showDealsModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DealsModal(
        onClaim: () {
          Navigator.of(context).pop();
          // Handle claim deal
        },
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _loadUserData() async {
    // Fetch fresh profile from API to get updated verification status; fallback to stored user
    final user = await _authService.getUserProfile() ??
        await _authService.getStoredUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  /// Shows live GPS as the home header. Splash runs [StartupLocationService.fetchFreshOnAppLaunch]
  /// on each app open; [resumeRefresh] forces a new read when returning from background.
  Future<void> _requestLocationAndUpdate({required bool resumeRefresh}) async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

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
          setState(() {
            _currentLocation = 'Location access denied';
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location access is disabled. Enable it in Settings to see your position.',
              ),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Open Settings',
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
        setState(() {
          _currentLocation = 'Unable to get location';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Unable to get location';
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
      if (mounted)
        SnackbarUtil.showSuccess(context, 'Email verified successfully!');
    }
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
      if (mounted)
        SnackbarUtil.showSuccess(
            context, 'Phone number verified successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserProfileHeader(
                name: _currentUser?.name ?? 'User',
                location: _currentLocation,
                isLoadingLocation: _isLoadingLocation,
                user: _currentUser,
                onLocationTap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSearchScreen(
                        currentLocation: _currentLocation,
                      ),
                    ),
                  );

                  if (result != null && result['address'] != null) {
                    final address = result['address'] as String;
                    final latitude = (result['latitude'] as num?)?.toDouble();
                    final longitude = (result['longitude'] as num?)?.toDouble();
                    if (latitude != null && longitude != null) {
                      await SavedLocationService.saveLocationData(
                        address: address,
                        latitude: latitude,
                        longitude: longitude,
                      );
                    } else {
                      await SavedLocationService.saveAddress(address);
                    }
                    if (mounted) {
                      setState(() {
                        _currentLocation = address;
                      });
                    }
                  }
                },
              ),
              if (_currentUser != null) ...[
                const SizedBox(height: 12),
                VerificationStatusCard(
                  user: _currentUser!,
                  onVerifyEmail: _openVerifyEmailFlow,
                  onVerifyPhone: _openVerifyPhoneFlow,
                ),
              ],
              const SizedBox(height: 16),
              // What would you like to do section
              Text(
                'What would you like to do?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Service Cards Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  ServiceCard(
                    title: 'Food',
                    subtitle: 'Order groceries from your favourite vendors.',
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllCategoriesScreen(),
                        ),
                      );
                    },
                  ),
                  ServiceCard(
                    title: 'Courier',
                    subtitle: 'Order courier services for pickup and drop off.',
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.primaryColor,
                    onTap: () {
                      widget.onSwitchToTab?.call(1);
                    },
                  ),
                  ServiceCard(
                    title: 'Taxi',
                    subtitle: 'Request taxi at affordable rates from anywhere.',
                    icon: Icons.local_taxi_rounded,
                    color: AppColors.primaryColor,
                    onTap: () {
                      widget.onSwitchToTab?.call(3);
                    },
                  ),
                  ServiceCard(
                    title: 'Handyman',
                    subtitle: 'Request handy men for casual services at home.',
                    icon: Icons.handyman_rounded,
                    color: AppColors.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HandymanScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AppFeaturesCard(),
              const SizedBox(height: 24),
              // History Section (Available Orders)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // History Items from API
              if (_ordersLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_ordersError != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Failed to load orders: $_ordersError',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    ),
                  ),
                )
              else if (_availableOrders.isEmpty)
                OrderHistoryEmptyState(
                  onBrowseTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllCategoriesScreen(),
                      ),
                    );
                  },
                )
              else
                ..._availableOrders.map((order) {
                  final dateStr =
                      DateFormat('d MMMM yyyy, h:mma').format(order.createdAt);
                  return HistoryItem(
                    orderId: order.orderNumber,
                    recipient: order.customer?.name ?? order.vendor.name,
                    location: order.deliveryAddress,
                    dateTime: dateStr,
                    status: order.statusDisplayName,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => OrdersBloc(
                              ordersRepository:
                                  context.read<OrdersRepository>(),
                            ),
                            child: OrderDetailsScreen(orderId: order.id),
                          ),
                        ),
                      );
                    },
                  );
                }),
            ],
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
