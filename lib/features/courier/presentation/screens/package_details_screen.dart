import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
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
  String? _itemType;
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

  String? _packageImagePath;
  bool _senderManuallyCleared = false;
  String _lastSenderText = '';

  final List<String> _itemTypes = [
    'Electronics/Gadgets',
    'Documents',
    'Food',
    'Clothing',
    'Books',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _packageWeightController.text = '1';
    _senderPhoneController.addListener(_onSenderPhoneChanged);
    _prefillSenderPhone();
  }

  String _localPhoneDisplay(String? phone) {
    final parts = splitPhoneForDisplay(phone);
    if (parts.nationalNumber.isEmpty) {
      return (phone ?? '').replaceAll(RegExp(r'\D'), '');
    }
    return '0${parts.nationalNumber}';
  }

  void _onSenderPhoneChanged() {
    final current = _senderPhoneController.text.trim();
    if (_lastSenderText.isNotEmpty && current.isEmpty) {
      _senderManuallyCleared = true;
    }
    _lastSenderText = current;
  }

  Future<void> _prefillSenderPhone() async {
    final user = await AuthService().getStoredUser();
    final phone = user?.phone?.trim() ?? '';
    if (phone.isEmpty || !mounted) return;
    final display = _localPhoneDisplay(phone);
    if (display.isEmpty) return;
    setState(() {
      if (_senderPhoneController.text.trim().isEmpty &&
          !_senderManuallyCleared) {
        _senderPhoneController.text = display;
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _packageWeightController.dispose();
    _packageDescriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _senderPhoneController.removeListener(_onSenderPhoneChanged);
    _senderPhoneController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    // TODO: Implement image picker
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.imagePickerTodo),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    required Color fieldFill,
    required Color outline,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: HomeColors.textPrimary,
      ),
      hintStyle: hintText != null
          ? const TextStyle(color: HomeColors.textMuted)
          : null,
      filled: true,
      fillColor: fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: const BorderSide(color: HomeColors.violet),
      ),
    );
  }

  void _navigateToConfirm() {
    if (_itemType == null || _itemType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectItemType),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterQuantity),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weight = double.tryParse(_packageWeightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterValidWeight),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final senderPhone = normalizePhoneToBackend(_senderPhoneController.text);
    if (!RegExp(r'^2519\d{8}$').hasMatch(senderPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterValidSenderPhone),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_recipientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterRecipientName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_recipientPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterRecipientPhone),
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
          itemType: _itemType!,
          quantity: _quantityController.text,
          packageWeight: weight,
          packageDescription: _packageDescriptionController.text.trim(),
          isInstantDelivery: widget.isInstantDelivery,
          scheduledPickup: widget.scheduledPickup,
          scheduledDelivery: widget.scheduledDelivery,
          whoPays: 'recipient',
          paymentType: 'cash_on_delivery',
          senderPhone: senderPhone,
          recipientName: _recipientNameController.text,
          recipientPhone: _recipientPhoneController.text,
          packageImagePath: _packageImagePath,
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
                          const Text(
                            'What are you sending',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _itemType,
                            isExpanded: true,
                            dropdownColor: HomeColors.surface,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: HomeColors.textMuted,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: HomeColors.textPrimary,
                            ),
                            decoration: _fieldDecoration(
                              labelText: 'What are you sending',
                              hintText:
                                  'Select type of item (e.g. gadget, document)',
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                            hint: const Text(
                              'Select type of item (e.g. gadget, document)',
                              style: TextStyle(
                                fontSize: 14,
                                color: HomeColors.textMuted,
                              ),
                            ),
                            items: _itemTypes
                                .map(
                                  (type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _itemType = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      color: HomeColors.textPrimary),
                                  decoration: _fieldDecoration(
                                    labelText: 'Quantity',
                                    fieldFill: fieldFill,
                                    outline: outline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _packageWeightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(
                                      color: HomeColors.textPrimary),
                                  decoration: _fieldDecoration(
                                    labelText: 'Weight (kg)',
                                    fieldFill: fieldFill,
                                    outline: outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _packageDescriptionController,
                            maxLines: 2,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: 'Package Description (optional)',
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                          ),
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
                            decoration: _fieldDecoration(
                              labelText: 'Sender phone (09xxxxxxxx)',
                              hintText: '0912345678',
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Recipient Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _recipientNameController,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: 'Recipient Names',
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _recipientPhoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: HomeColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: 'Recipient contact number',
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
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
