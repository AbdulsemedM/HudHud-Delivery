import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:latlong2/latlong.dart';
import 'confirm_details_screen.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String pickupLocation;
  final String deliveryLocation;
  final LatLng? pickupPosition;
  final LatLng? deliveryPosition;
  final String selectedVehicle;
  final bool isInstantDelivery;
  final DateTime? scheduledPickup;
  final DateTime? scheduledDelivery;

  const PackageDetailsScreen({
    super.key,
    required this.pickupLocation,
    required this.deliveryLocation,
    this.pickupPosition,
    this.deliveryPosition,
    required this.selectedVehicle,
    required this.isInstantDelivery,
    this.scheduledPickup,
    this.scheduledDelivery,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final TextEditingController _itemTypeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _packageWeightController =
      TextEditingController();
  final TextEditingController _packageDescriptionController =
      TextEditingController();
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _recipientPhoneController =
      TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();

  String _whoPays = 'me'; // 'me' or 'recipient'
  String? _paymentType; // API id (e.g. 'wallet', 'waafi')
  String? _packageImagePath;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;

  List<Map<String, dynamic>> _paymentMethods =
      List.from(kDefaultAllowedPaymentMethods);
  bool _isLoadingPaymentMethods = true;
  String? _paymentMethodsError;

  final List<String> _itemTypes = [
    'Electronics/Gadgets',
    'Documents',
    'Food',
    'Clothing',
    'Books',
    'Other'
  ];

  late final PaymentRepository _paymentRepository;

  @override
  void initState() {
    super.initState();
    _paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _fetchPaymentMethods();
    _prefillSenderPhone();
  }

  Future<void> _prefillSenderPhone() async {
    final user = await AuthService().getStoredUser();
    final phone = user?.phone?.trim() ?? '';
    if (phone.isEmpty || !mounted) return;
    final parts = splitPhoneForDisplay(phone);
    final display = parts.nationalNumber.isEmpty
        ? phone
        : '0${parts.nationalNumber}';
    setState(() {
      _senderPhoneController.text = display;
    });
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final methods = await _paymentRepository.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods.isNotEmpty
              ? methods
              : List.from(kDefaultAllowedPaymentMethods);
          _isLoadingPaymentMethods = false;
          _paymentMethodsError = null;
          if (_paymentType != null &&
              !_paymentMethods.any((m) => m['id'] == _paymentType)) {
            _paymentType = null;
            _paymentDetails = {};
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentMethods = List.from(kDefaultAllowedPaymentMethods);
          _isLoadingPaymentMethods = false;
          _paymentMethodsError = 'Failed to load payment methods';
        });
      }
    }
  }

  String? _getSelectedPaymentName() {
    if (_paymentType == null) return null;
    for (final method in _paymentMethods) {
      if (method['id'] == _paymentType) {
        return method['name'] as String?;
      }
    }
    return _paymentType;
  }

  @override
  void dispose() {
    _itemTypeController.dispose();
    _quantityController.dispose();
    _packageWeightController.dispose();
    _packageDescriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _senderPhoneController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    // TODO: Implement image picker
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image picker will be implemented'),
      ),
    );
  }

  void _navigateToConfirm() {
    if (_itemTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select item type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weight = double.tryParse(_packageWeightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid package weight (kg)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paymentType == null || _paymentType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select payment type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (paymentMethodNeedsDetailsForm(_paymentType)) {
      final phoneError = validatePaymentPhone(
        _paymentDetails['phone']?.toString(),
        _paymentType!,
      );
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(phoneError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final senderPhone = normalizePhoneToBackend(_senderPhoneController.text);
    if (!RegExp(r'^2519\d{8}$').hasMatch(senderPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid sender phone (09xxxxxxxx)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_recipientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_recipientPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmDetailsScreen(
          pickupLocation: widget.pickupLocation,
          deliveryLocation: widget.deliveryLocation,
          pickupPosition: widget.pickupPosition,
          deliveryPosition: widget.deliveryPosition,
          selectedVehicle: widget.selectedVehicle,
          itemType: _itemTypeController.text,
          quantity: _quantityController.text,
          packageWeight: weight,
          packageDescription: _packageDescriptionController.text.trim(),
          isInstantDelivery: widget.isInstantDelivery,
          scheduledPickup: widget.scheduledPickup,
          scheduledDelivery: widget.scheduledDelivery,
          whoPays: _whoPays,
          paymentType: _paymentType!,
          senderPhone: senderPhone,
          recipientName: _recipientNameController.text,
          recipientPhone: _recipientPhoneController.text,
          packageImagePath: _packageImagePath,
          paymentDetails: Map<String, dynamic>.from(_paymentDetails),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          const borderColor = HomeColors.border;
          const outline = HomeColors.border;
          const fieldFill = HomeColors.surfaceElevated;
          return Scaffold(
            backgroundColor: HomeColors.background,
            appBar: AppBar(
              backgroundColor: HomeColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: HomeColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'What are you sending',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textPrimary,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // What are you sending section
                          const Text(
                            'What are you sending',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Item Type
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: HomeColors.surface,
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _itemTypes.map((type) {
                                      return ListTile(
                                        title: Text(
                                          type,
                                          style: const TextStyle(
                                            color: HomeColors.textPrimary,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _itemTypeController.text = type;
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: fieldFill,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(color: outline),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _itemTypeController.text.isEmpty
                                          ? 'Select type of item (e.g. gadget, document)'
                                          : _itemTypeController.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _itemTypeController.text.isEmpty
                                            ? HomeColors.textMuted
                                            : HomeColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down,
                                      color: HomeColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Quantity
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                color: HomeColors.textPrimary,
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide:
                                    const BorderSide(color: HomeColors.violet),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Package Weight (kg)
                          TextFormField(
                            controller: _packageWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Package Weight (kg)',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                color: HomeColors.textPrimary,
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide:
                                    const BorderSide(color: HomeColors.violet),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Package Description (optional)
                          TextFormField(
                            controller: _packageDescriptionController,
                            maxLines: 2,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Package Description (optional)',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                color: HomeColors.textPrimary,
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide:
                                    const BorderSide(color: HomeColors.violet),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Select who pays
                          const Text(
                            'Select who pays',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _RadioOption(
                                  label: 'Me',
                                  isSelected: _whoPays == 'me',
                                  onTap: () {
                                    setState(() {
                                      _whoPays = 'me';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RadioOption(
                                  label: 'Recipient',
                                  isSelected: _whoPays == 'recipient',
                                  onTap: () {
                                    setState(() {
                                      _whoPays = 'recipient';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Payment type
                          const Text(
                            'Payment type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _isLoadingPaymentMethods
                                ? null
                                : () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: HomeColors.surface,
                                      builder: (context) => Container(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              _paymentMethods.map((method) {
                                            final id = method['id'] as String?;
                                            final name = method['name']
                                                    as String? ??
                                                id ??
                                                '';
                                            return ListTile(
                                              title: Text(
                                                name,
                                                style: const TextStyle(
                                                  color: HomeColors.textPrimary,
                                                ),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  _paymentType = id;
                                                  _paymentDetails = {};
                                                  _useHpp = false;
                                                  _ebirrProvider = 'kaafi';
                                                });
                                                Navigator.pop(context);
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: fieldFill,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(color: outline),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _isLoadingPaymentMethods
                                        ? const _PaymentMethodShimmer(
                                            borderColor: borderColor)
                                        : Text(
                                            _paymentMethodsError ??
                                                _getSelectedPaymentName() ??
                                                'Select payment type',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _paymentType == null
                                                  ? HomeColors.textMuted
                                                  : HomeColors.textPrimary,
                                            ),
                                          ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down,
                                      color: HomeColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          if (_paymentType != null &&
                              paymentMethodNeedsDetailsForm(_paymentType)) ...[
                            const SizedBox(height: 12),
                            PaymentDetailsForm(
                              paymentMethodCode: _paymentType!,
                              ebirrProvider: _ebirrProvider,
                              useHpp: _useHpp,
                              onChanged: (details) {
                                setState(() {
                                  _paymentDetails = details;
                                });
                              },
                              onEbirrProviderChanged: (provider) {
                                setState(() {
                                  _ebirrProvider = provider;
                                });
                              },
                              onUseHppChanged: (value) {
                                setState(() {
                                  _useHpp = value;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Text(
                            'Sender Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _senderPhoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Sender phone (09xxxxxxxx)',
                              hintText: '0912345678',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                color: HomeColors.textPrimary,
                              ),
                              hintStyle: const TextStyle(
                                color: HomeColors.textMuted,
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide:
                                    const BorderSide(color: HomeColors.violet),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Recipient Information
                          const Text(
                            'Recipient Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Recipient Name
                          TextFormField(
                            controller: _recipientNameController,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Recipient Names',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                color: HomeColors.textPrimary,
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide:
                                    const BorderSide(color: HomeColors.violet),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Recipient Phone
                          TextFormField(
                            controller: _recipientPhoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Recipient contact number',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                color: HomeColors.textPrimary,
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide: const BorderSide(color: outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                borderSide:
                                    const BorderSide(color: HomeColors.violet),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Take a picture of the package
                          GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: fieldFill,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(
                                  color: outline,
                                  style: BorderStyle.solid,
                                  width: 2,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: HomeColors.textMuted,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Take a picture of the package',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: HomeColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 100), // Space for bottom button
                        ],
                      ),
                    ),
                  ),
                  // Continue Button
                  Container(
                    padding: const EdgeInsets.all(AppColors.spaceMD),
                    decoration: const BoxDecoration(
                      color: HomeColors.surface,
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _navigateToConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeColors.violet,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(
                              double.infinity, AppColors.buttonHeightMD),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusLG),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? HomeColors.violet.withValues(alpha: 0.1)
              : HomeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(
            color: isSelected ? HomeColors.violet : HomeColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? HomeColors.violet : HomeColors.textMuted,
                  width: 2,
                ),
                color: isSelected ? HomeColors.violet : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? HomeColors.violet
                    : HomeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodShimmer extends StatelessWidget {
  final Color borderColor;

  const _PaymentMethodShimmer({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    const baseColor = HomeColors.surfaceElevated;
    final highlightColor = HomeColors.surfaceElevated.withValues(alpha: 0.6);
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
