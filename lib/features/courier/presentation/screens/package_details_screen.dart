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
    IconData? icon,
  }) {
    final radius = BorderRadius.circular(16);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 22, color: HomeColors.violetOf(context)),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: HomeColors.textMutedOf(context),
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: HomeColors.violetOf(context),
      ),
      hintStyle: hintText != null
          ? TextStyle(
              fontWeight: FontWeight.w500,
              color: HomeColors.textMutedOf(context),
            )
          : null,
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: HomeColors.violetOf(context), width: 2),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorColor),
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
          final outline = HomeColors.borderOf(context);
          final fieldFill = HomeColors.surfaceElevatedOf(context);
          final fieldText = TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: HomeColors.textPrimaryOf(context),
          );
          return Scaffold(
            backgroundColor: HomeColors.backgroundOf(context),
            appBar: AppBar(
              backgroundColor: HomeColors.backgroundOf(context),
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 26,
                  color: HomeColors.textPrimaryOf(context),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                l10n.whatAreYouSending,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
              centerTitle: true,
              actions: const [CallSupportButton(compact: true)],
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.inventory_2_rounded,
                          title: l10n.whatAreYouSending,
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 12.0;
                            final tileWidth =
                                (constraints.maxWidth - gap * 2) / 3;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                for (final id in PackageItemCatalog.allIds)
                                  SizedBox(
                                    width: tileWidth,
                                    child: _ItemTypeChip(
                                      selected: _itemType == id,
                                      icon: PackageItemCatalog.iconFor(id),
                                      label:
                                          PackageItemCatalog.labelFor(id, l10n),
                                      onTap: () =>
                                          setState(() => _itemType = id),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _FormCard(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    style: fieldText,
                                    decoration: _fieldDecoration(
                                      labelText: l10n.quantity,
                                      fieldFill: fieldFill,
                                      outline: outline,
                                      icon: Icons.tag_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _packageWeightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    style: fieldText,
                                    decoration: _fieldDecoration(
                                      labelText: l10n.packageWeightKg,
                                      fieldFill: fieldFill,
                                      outline: outline,
                                      icon: Icons.scale_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _packageDescriptionController,
                              maxLines: 2,
                              style: fieldText.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _fieldDecoration(
                                labelText: l10n.packageDescriptionOptional,
                                fieldFill: fieldFill,
                                outline: outline,
                                icon: Icons.notes_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _SectionHeader(
                          icon: Icons.upload_rounded,
                          title: l10n.senderInformation,
                          accent: HomeColors.orange,
                        ),
                        const SizedBox(height: 12),
                        _FormCard(
                          children: [
                            TextFormField(
                              controller: _senderPhoneController,
                              keyboardType: TextInputType.phone,
                              style: fieldText,
                              decoration: _fieldDecoration(
                                labelText: l10n.senderPhoneLabel,
                                hintText: l10n.senderPhoneExample,
                                fieldFill: fieldFill,
                                outline: outline,
                                icon: Icons.phone_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _SectionHeader(
                          icon: Icons.download_rounded,
                          title: l10n.recipientInformation,
                        ),
                        const SizedBox(height: 12),
                        _FormCard(
                          children: [
                            TextFormField(
                              controller: _recipientNameController,
                              style: fieldText,
                              decoration: _fieldDecoration(
                                labelText: l10n.recipientNames,
                                fieldFill: fieldFill,
                                outline: outline,
                                icon: Icons.person_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _recipientPhoneController,
                              keyboardType: TextInputType.phone,
                              style: fieldText,
                              decoration: _fieldDecoration(
                                labelText: l10n.recipientContactNumber,
                                fieldFill: fieldFill,
                                outline: outline,
                                icon: Icons.phone_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _PhotoCard(
                          imagePath: _packageImagePath,
                          emptyLabel: l10n.takePackagePhoto,
                          addedLabel: l10n.packagePhotoAdded,
                          changeLabel: l10n.changePackagePhoto,
                          onTap: _takePicture,
                        ),
                      ],
                    ),
                  ),
                ),
                _BottomActionBar(
                  label: l10n.actionContinue,
                  onPressed: _navigateToConfirm,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Section heading: tinted icon tile + bold title.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.accent,
  });

  final IconData icon;
  final String title;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? HomeColors.violetOf(context);
    final isOrange = color == HomeColors.orange;
    final tint = isOrange
        ? (HomeColors.isDark(context)
            ? AppColors.orangeTintDark
            : AppColors.orangeTint)
        : HomeColors.violetTintOf(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// White card that groups form fields.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(22),
        border: HomeColors.isDark(context)
            ? Border.all(color: HomeColors.borderOf(context))
            : null,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Package photo picker card.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.imagePath,
    required this.emptyLabel,
    required this.addedLabel,
    required this.changeLabel,
    required this.onTap,
  });

  final String? imagePath;
  final String emptyLabel;
  final String addedLabel;
  final String changeLabel;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(22));

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    final hasImage = imagePath != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(
            color: hasImage
                ? HomeColors.borderOf(context)
                : accent.withValues(alpha: 0.35),
            width: hasImage ? 1 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: hasImage
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(imagePath!),
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 22,
                            color: AppColors.successColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              addedLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: HomeColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.photo_camera_rounded,
                            size: 18,
                            color: accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            changeLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: HomeColors.violetTintOf(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          size: 30,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        emptyLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HomeColors.textPrimaryOf(context),
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

/// Sticky bottom bar with one full-width orange primary button.
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        border: Border(top: BorderSide(color: HomeColors.borderOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picture-first item type tile. Selected = indigo border + tint + check.
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

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    final tint = HomeColors.violetTintOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: selected ? const [] : AppColors.softShadow(context),
        ),
        child: Material(
          color: selected ? tint : HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(
              color: selected ? accent : HomeColors.borderOf(context),
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              selected ? HomeColors.surfaceOf(context) : tint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, size: 28, color: accent),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 34,
                        child: Center(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: HomeColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
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
