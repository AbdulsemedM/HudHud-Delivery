import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/call_support_button.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/package_item_catalog.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

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
    final l10n = context.l10n;
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: Text(l10n.takePackagePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.changePackagePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null || !mounted) return;
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        requestFullMetadata: source != ImageSource.gallery,
      );
      if (picked == null || !mounted) return;
      setState(() => _packageImagePath = picked.path);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotOpenPhotoPicker(e.message ?? e.code)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenPhotoPicker('$e'))),
      );
    }
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
      labelStyle: TextStyle(
        fontSize: 14,
        color: HomeColors.textPrimaryOf(context),
      ),
      hintStyle: hintText != null
          ? TextStyle(color: HomeColors.textMutedOf(context))
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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateToConfirm() {
    final l10n = context.l10n;
    if (_itemType == null || _itemType!.isEmpty) {
      _snack(l10n.pleaseSelectItemType);
      return;
    }

    if (_quantityController.text.trim().isEmpty) {
      _snack(l10n.pleaseEnterQuantity);
      return;
    }

    final weight = double.tryParse(_packageWeightController.text);
    if (weight == null || weight <= 0) {
      _snack(l10n.pleaseEnterValidWeight);
      return;
    }

    final senderPhone = normalizePhoneToBackend(_senderPhoneController.text);
    if (!RegExp(r'^2519\d{8}$').hasMatch(senderPhone)) {
      _snack(l10n.pleaseEnterValidSenderPhone);
      return;
    }

    if (_recipientNameController.text.trim().isEmpty) {
      _snack(l10n.pleaseEnterRecipientName);
      return;
    }

    final recipientPhone =
        normalizePhoneToBackend(_recipientPhoneController.text);
    if (!RegExp(r'^2519\d{8}$').hasMatch(recipientPhone)) {
      _snack(l10n.pleaseEnterValidRecipientPhone);
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
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: recipientPhone,
          packageImagePath: _packageImagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final borderColor = HomeColors.borderOf(context);
          final outline = HomeColors.borderOf(context);
          final fieldFill = HomeColors.surfaceElevatedOf(context);
          return Scaffold(
            backgroundColor: HomeColors.backgroundOf(context),
            appBar: AppBar(
              backgroundColor: HomeColors.surfaceOf(context),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: HomeColors.textPrimaryOf(context)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                l10n.whatAreYouSending,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
              centerTitle: true,
              actions: const [CallSupportButton(compact: true)],
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
                          Text(
                            l10n.whatAreYouSending,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final id in PackageItemCatalog.allIds)
                                _ItemTypeChip(
                                  selected: _itemType == id,
                                  icon: PackageItemCatalog.iconFor(id),
                                  label: PackageItemCatalog.labelFor(id, l10n),
                                  onTap: () =>
                                      setState(() => _itemType = id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      color:
                                          HomeColors.textPrimaryOf(context)),
                                  decoration: _fieldDecoration(
                                    labelText: l10n.quantity,
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
                                  style: TextStyle(
                                      color:
                                          HomeColors.textPrimaryOf(context)),
                                  decoration: _fieldDecoration(
                                    labelText: l10n.packageWeightKg,
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
                            style: TextStyle(
                                color: HomeColors.textPrimaryOf(context)),
                            decoration: _fieldDecoration(
                              labelText: l10n.packageDescriptionOptional,
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.senderInformation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _senderPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                                color: HomeColors.textPrimaryOf(context)),
                            decoration: _fieldDecoration(
                              labelText: l10n.senderPhoneLabel,
                              hintText: l10n.senderPhoneExample,
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.recipientInformation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _recipientNameController,
                            style: TextStyle(
                                color: HomeColors.textPrimaryOf(context)),
                            decoration: _fieldDecoration(
                              labelText: l10n.recipientNames,
                              fieldFill: fieldFill,
                              outline: outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _recipientPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                                color: HomeColors.textPrimaryOf(context)),
                            decoration: _fieldDecoration(
                              labelText: l10n.recipientContactNumber,
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
                                  width: 2,
                                ),
                              ),
                              child: _packageImagePath == null
                                  ? Column(
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          size: 48,
                                          color:
                                              HomeColors.textMutedOf(context),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.takePackagePhoto,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: HomeColors.textMutedOf(
                                                context),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            File(_packageImagePath!),
                                            height: 160,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.packagePhotoAdded,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: HomeColors.textPrimaryOf(
                                                context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          l10n.changePackagePhoto,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: HomeColors.violet,
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
                    decoration: BoxDecoration(
                      color: HomeColors.surfaceOf(context),
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _navigateToConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeColors.violet,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSecondary,
                          minimumSize: const Size(
                              double.infinity, AppColors.buttonHeightMD),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusLG),
                          ),
                        ),
                        child: Text(
                          l10n.actionContinue,
                          style: const TextStyle(
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

class _ItemTypeChip extends StatelessWidget {
  const _ItemTypeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? HomeColors.violet.withValues(alpha: 0.15)
          : HomeColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 104,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? HomeColors.violet
                  : HomeColors.borderOf(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: selected
                    ? HomeColors.violet
                    : HomeColors.textPrimaryOf(context),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
