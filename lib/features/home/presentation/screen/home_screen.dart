import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/all_categories_screen.dart';
import 'package:hudhud_delivery/features/service_types/presentation/screens/services_screen.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/saved_location_service.dart';
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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

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
      child: const HomeScreen(),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String _currentLocation = 'Getting location...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _requestLocationAndUpdate();
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

  Future<void> _requestLocationAndUpdate() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      // Prefer saved address, then current GPS
      final saved = await SavedLocationService.getSavedAddress();
      if (saved != null && saved.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentLocation = saved;
            _isLoadingLocation = false;
          });
        }
        return;
      }

      final location = await LocationService.getCurrentLocationAddress();
      if (mounted) {
        setState(() {
          _currentLocation = location;
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                    await SavedLocationService.saveAddress(address);
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
              // Order Tracking Card
              OrderTrackingCard(
                riderName: _currentUser?.name ?? 'Tafari',
                message:
                    'Your courier rider Dickson is getting ready to collect your courier request this may take 5-8mins we will notify you once he collects the package.',
                onViewMap: () {
                  // Handle view map
                },
              ),
              const SizedBox(height: 24),
              // What would you like to do section
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50), // Dark grey
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
                    title: 'Delivery',
                    subtitle: 'Order groceries from your favourite vendors.',
                    icon: Icons.shopping_bag,
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
                    icon: Icons.local_shipping,
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to courier screen
                    },
                  ),
                  ServiceCard(
                    title: 'Taxi',
                    subtitle: 'Request taxi at affordable rates from anywhere.',
                    icon: Icons.local_taxi,
                    color: Colors.yellow[700]!,
                    onTap: () {
                      // Navigate to taxi screen
                    },
                  ),
                  ServiceCard(
                    title: 'Services',
                    subtitle: 'Request handy men for casual services at home.',
                    icon: Icons.handyman,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServicesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Deals Section
              DealsSection(
                onClaim: () {
                  // Handle claim deal
                },
              ),
              const SizedBox(height: 24),
              // History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle view all
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
              // History Items
              HistoryItem(
                orderId: 'ORDB1234',
                recipient: 'Paul Pogba',
                location: 'Maryland bustop, Anthony Ikeja',
                dateTime: '12 January 2020, 2:43pm',
                status: 'Completed',
              ),
              HistoryItem(
                orderId: 'ORDB1234',
                recipient: 'Paul Pogba',
                location: 'Maryland bustop, Anthony Ikeja',
                dateTime: '12 January 2020, 2:43pm',
                status: 'Completed',
              ),
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
