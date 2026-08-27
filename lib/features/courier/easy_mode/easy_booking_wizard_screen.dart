import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/core/easy_mode/voice_hint_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/call_support_button.dart';
import 'package:hudhud_delivery/core/widgets/centered_pin_map.dart';
import 'package:hudhud_delivery/core/widgets/speak_button.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/package_item_catalog.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/confirm_details_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

/// Pictorial Instant Courier wizard for Easy Mode.
class EasyBookingWizardScreen extends StatefulWidget {
  const EasyBookingWizardScreen({super.key});

  @override
  State<EasyBookingWizardScreen> createState() =>
      _EasyBookingWizardScreenState();
}

class _EasyBookingWizardScreenState extends State<EasyBookingWizardScreen> {
  static const _totalSteps = 5;

  int _step = 0;

  LatLng _pickupPosition = const LatLng(9.0222, 38.7468);
  LatLng _dropoffPosition = const LatLng(9.0222, 38.7468);
  String _pickupAddress = '';
  String _dropoffAddress = '';

  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  String? _senderPhone;

  String? _itemType;
  String _sizeId = 'small';
  String? _packageImagePath;
  String? _voiceNotePath;

  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await VoiceHintService.instance.init();
    final user = await AuthService().getStoredUser();
    _senderPhone = user?.phone;
    final position = await CustomLocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _pickupPosition = LatLng(position.latitude, position.longitude);
        _dropoffPosition = LatLng(position.latitude, position.longitude);
      });
      await _reverseGeocodePickup();
    }
    if (mounted) _speakCurrentStep();
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _audioRecorder.dispose();
    VoiceHintService.instance.stop();
    super.dispose();
  }

  void _speakCurrentStep() {
    final l10n = context.l10n;
    final text = switch (_step) {
      0 => '${l10n.easyPickupTitle}. ${l10n.easyPickupHint}',
      1 => '${l10n.easyDropTitle}. ${l10n.easyDropHint}',
      2 => l10n.easyWhoReceives,
      3 => '${l10n.easyWhatIsIt}. ${l10n.easyPackageSize}',
      4 => l10n.easyConfirmTitle,
      _ => '',
    };
    VoiceHintService.instance.speak(text);
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final places = await GooglePlacesService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      final best = HumanReadableAddress.pickBestPlace(places);
      if (best != null) {
        return best.shortAddress;
      }
    } catch (_) {}
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }

  Future<void> _reverseGeocodePickup() async {
    final address = await _reverseGeocode(_pickupPosition);
    if (mounted) setState(() => _pickupAddress = address);
  }

  Future<void> _reverseGeocodeDropoff() async {
    final address = await _reverseGeocode(_dropoffPosition);
    if (mounted) setState(() => _dropoffAddress = address);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _goNext() async {
    final l10n = context.l10n;
    if (_step == 0) {
      if (_pickupAddress.trim().isEmpty) {
        await _reverseGeocodePickup();
      }
      if (_pickupAddress.trim().isEmpty) {
        _snack(l10n.pleaseSelectLocation);
        return;
      }
      setState(() {
        _step = 1;
      });
      _speakCurrentStep();
      return;
    }
    if (_step == 1) {
      if (_dropoffAddress.trim().isEmpty) {
        await _reverseGeocodeDropoff();
      }
      if (_dropoffAddress.trim().isEmpty) {
        _snack(l10n.pleaseSelectLocation);
        return;
      }
      setState(() {
        _step = 2;
      });
      _speakCurrentStep();
      return;
    }
    if (_step == 2) {
      if (_recipientNameController.text.trim().isEmpty) {
        _snack(l10n.pleaseEnterRecipientName);
        return;
      }
      final phone =
          normalizePhoneToBackend(_recipientPhoneController.text);
      if (!RegExp(r'^2519\d{8}$').hasMatch(phone)) {
        _snack(l10n.pleaseEnterValidRecipientPhone);
        return;
      }
      setState(() => _step = 3);
      _speakCurrentStep();
      return;
    }
    if (_step == 3) {
      if (_itemType == null) {
        _snack(l10n.pleaseSelectItemType);
        return;
      }
      if (_packageImagePath == null) {
        _snack(l10n.pleaseAddPackagePhoto);
        return;
      }
      setState(() => _step = 4);
      _speakCurrentStep();
      return;
    }
    if (_step == 4) {
      await _finish();
    }
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step -= 1);
    _speakCurrentStep();
  }

  Future<void> _finish() async {
    final l10n = context.l10n;
    var senderPhone = _senderPhone ?? '';
    senderPhone = normalizePhoneToBackend(senderPhone);
    if (!RegExp(r'^2519\d{8}$').hasMatch(senderPhone)) {
      final parts = splitPhoneForDisplay(_senderPhone);
      senderPhone = normalizePhoneToBackend('0${parts.nationalNumber}');
    }
    if (!RegExp(r'^2519\d{8}$').hasMatch(senderPhone)) {
      _snack(l10n.pleaseEnterValidSenderPhone);
      return;
    }

    final recipientPhone =
        normalizePhoneToBackend(_recipientPhoneController.text);
    final weight = PackageItemCatalog.weightForSize(_sizeId);
    final descParts = <String>[];
    if (_voiceNotePath != null) {
      descParts.add('Voice note: $_voiceNotePath');
    }
    final description = descParts.join('\n');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmDetailsScreen(
          pickupLocation: _pickupAddress,
          deliveryLocation: _dropoffAddress,
          pickupPosition: _pickupPosition,
          deliveryPosition: _dropoffPosition,
          selectedVehicle: 'motorcycle',
          itemType: _itemType!,
          quantity: '1',
          packageWeight: weight,
          packageDescription: description,
          isInstantDelivery: true,
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

  Future<void> _pickContact() async {
    final l10n = context.l10n;
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) _snack(l10n.contactsPermissionRequired);
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null || !mounted) return;
      final full = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
        withPhoto: false,
      );
      final name = full?.displayName ?? contact.displayName;
      final phone = full?.phones.isNotEmpty == true
          ? full!.phones.first.number
          : (contact.phones.isNotEmpty ? contact.phones.first.number : '');
      setState(() {
        _recipientNameController.text = name;
        if (phone.isNotEmpty) {
          final parts = splitPhoneForDisplay(phone);
          _recipientPhoneController.text = parts.nationalNumber.isEmpty
              ? phone.replaceAll(RegExp(r'\D'), '')
              : '0${parts.nationalNumber}';
        }
      });
    } catch (_) {
      if (mounted) _snack(l10n.couldNotOpenContacts);
    }
  }

  Future<void> _takePhoto() async {
    final l10n = context.l10n;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _packageImagePath = picked.path);
    } on PlatformException catch (e) {
      if (!mounted) return;
      _snack(l10n.couldNotOpenPhotoPicker(e.message ?? e.code));
    } catch (e) {
      if (!mounted) return;
      _snack(l10n.couldNotOpenPhotoPicker('$e'));
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) return;
      final path = p.join(
        Directory.systemTemp.path,
        'easy_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (mounted) setState(() => _isRecording = true);
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          if (path != null) _voiceNotePath = path;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  String _summary(AppLocalizations l10n) {
    return l10n.easyConfirmSummary(
      _pickupAddress,
      _dropoffAddress,
      _itemType == null
          ? ''
          : PackageItemCatalog.labelFor(_itemType!, l10n),
      _recipientNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: HomeColors.surfaceOf(context),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: HomeColors.textPrimaryOf(context)),
            onPressed: _goBack,
          ),
          title: Text(
            l10n.easyStepOf(_step + 1, _totalSteps),
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            SpeakButton(
              text: switch (_step) {
                0 => '${l10n.easyPickupTitle}. ${l10n.easyPickupHint}',
                1 => '${l10n.easyDropTitle}. ${l10n.easyDropHint}',
                2 => l10n.easyWhoReceives,
                3 => '${l10n.easyWhatIsIt}. ${l10n.easyPackageSize}',
                4 => _summary(l10n),
                _ => '',
              },
            ),
            const CallSupportButton(compact: true),
          ],
        ),
        floatingActionButton: const CallSupportFab(
          heroTag: 'easy_booking_call_support',
          extended: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_step + 1) / _totalSteps,
                backgroundColor: HomeColors.borderOf(context),
                color: HomeColors.violet,
                minHeight: 6,
              ),
              Expanded(child: _buildStep(l10n)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthScreenColors.orange,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _step == 4 ? l10n.actionContinue : l10n.actionNext,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return _MapStep(
          title: l10n.easyPickupTitle,
          hint: l10n.easyPickupHint,
          iAmHereLabel: l10n.easyIAmHere,
          address: _pickupAddress,
          position: _pickupPosition,
          onPositionChanged: (pos) {
            setState(() {
              _pickupPosition = LatLng(pos.latitude, pos.longitude);
            });
            unawaited(_reverseGeocodePickup());
          },
          onIAmHere: () async {
            final position =
                await CustomLocationService.getCurrentPosition();
            if (position == null || !mounted) return;
            setState(() {
              _pickupPosition =
                  LatLng(position.latitude, position.longitude);
            });
            await _reverseGeocodePickup();
          },
        );
      case 1:
        return _MapStep(
          title: l10n.easyDropTitle,
          hint: l10n.easyDropHint,
          iAmHereLabel: l10n.easyIAmHere,
          address: _dropoffAddress,
          position: _dropoffPosition,
          onPositionChanged: (pos) {
            setState(() {
              _dropoffPosition = LatLng(pos.latitude, pos.longitude);
            });
            unawaited(_reverseGeocodeDropoff());
          },
          onIAmHere: () async {
            final position =
                await CustomLocationService.getCurrentPosition();
            if (position == null || !mounted) return;
            setState(() {
              _dropoffPosition =
                  LatLng(position.latitude, position.longitude);
            });
            await _reverseGeocodeDropoff();
          },
        );
      case 2:
        return _RecipientStep(
          nameController: _recipientNameController,
          phoneController: _recipientPhoneController,
          onPickContact: _pickContact,
        );
      case 3:
        return _PackageStep(
          itemType: _itemType,
          sizeId: _sizeId,
          imagePath: _packageImagePath,
          voiceNotePath: _voiceNotePath,
          isRecording: _isRecording,
          onSelectItem: (id) => setState(() => _itemType = id),
          onSelectSize: (id) => setState(() => _sizeId = id),
          onTakePhoto: _takePhoto,
          onRecordStart: _startRecording,
          onRecordEnd: _stopRecording,
          onClearVoice: () => setState(() => _voiceNotePath = null),
        );
      default:
        return _ConfirmStep(
          summary: _summary(l10n),
          pickup: _pickupAddress,
          dropoff: _dropoffAddress,
          itemLabel: _itemType == null
              ? ''
              : PackageItemCatalog.labelFor(_itemType!, l10n),
          recipient: _recipientNameController.text.trim(),
          imagePath: _packageImagePath,
          onPlay: () => VoiceHintService.instance.speak(_summary(l10n)),
        );
    }
  }
}

class _MapStep extends StatelessWidget {
  const _MapStep({
    required this.title,
    required this.hint,
    required this.iAmHereLabel,
    required this.address,
    required this.position,
    required this.onPositionChanged,
    required this.onIAmHere,
  });

  final String title;
  final String hint;
  final String iAmHereLabel;
  final String address;
  final LatLng position;
  final ValueChanged<gmaps.LatLng> onPositionChanged;
  final VoidCallback onIAmHere;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 15,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              CenteredPinMap(
                initialCameraPosition: gmaps.CameraPosition(
                  target: gmaps.LatLng(position.latitude, position.longitude),
                  zoom: 15,
                ),
                onMapCreated: (_) {},
                onCenterLatLngChanged: onPositionChanged,
                myLocationButtonEnabled: false,
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  children: [
                    if (address.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: HomeColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HomeColors.textPrimaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: onIAmHere,
                        icon: const Icon(Icons.my_location_rounded),
                        label: Text(iAmHereLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeColors.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
    );
  }
}

class _RecipientStep extends StatelessWidget {
  const _RecipientStep({
    required this.nameController,
    required this.phoneController,
    required this.onPickContact,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onPickContact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fill = HomeColors.surfaceElevatedOf(context);
    final outline = HomeColors.borderOf(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.easyWhoReceives,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 64,
          child: ElevatedButton.icon(
            onPressed: onPickContact,
            icon: const Icon(Icons.contacts_rounded, size: 28),
            label: Text(
              l10n.easyPickContact,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeColors.violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.easyOrTypePhone,
          style: TextStyle(
            fontSize: 15,
            color: HomeColors.textMutedOf(context),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          style: TextStyle(color: HomeColors.textPrimaryOf(context)),
          decoration: InputDecoration(
            labelText: l10n.recipientNames,
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: outline),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: HomeColors.textPrimaryOf(context)),
          decoration: InputDecoration(
            labelText: l10n.recipientContactNumber,
            hintText: l10n.senderPhoneExample,
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: outline),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageStep extends StatelessWidget {
  const _PackageStep({
    required this.itemType,
    required this.sizeId,
    required this.imagePath,
    required this.voiceNotePath,
    required this.isRecording,
    required this.onSelectItem,
    required this.onSelectSize,
    required this.onTakePhoto,
    required this.onRecordStart,
    required this.onRecordEnd,
    required this.onClearVoice,
  });

  final String? itemType;
  final String sizeId;
  final String? imagePath;
  final String? voiceNotePath;
  final bool isRecording;
  final ValueChanged<String> onSelectItem;
  final ValueChanged<String> onSelectSize;
  final VoidCallback onTakePhoto;
  final Future<void> Function() onRecordStart;
  final Future<void> Function() onRecordEnd;
  final VoidCallback onClearVoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.easyWhatIsIt,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: [
            for (final id in PackageItemCatalog.easyModeIds)
              _BigChoice(
                selected: itemType == id,
                icon: PackageItemCatalog.iconFor(id),
                label: PackageItemCatalog.labelFor(id, l10n),
                onTap: () => onSelectItem(id),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.easyPackageSize,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final entry in [
              ('small', l10n.easySizeSmall, Icons.crop_square),
              ('medium', l10n.easySizeMedium, Icons.crop_5_4),
              ('large', l10n.easySizeLarge, Icons.crop_landscape),
            ]) ...[
              Expanded(
                child: _BigChoice(
                  selected: sizeId == entry.$1,
                  icon: entry.$3,
                  label: entry.$2,
                  onTap: () => onSelectSize(entry.$1),
                ),
              ),
              if (entry.$1 != 'large') const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onTakePhoto,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: HomeColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HomeColors.borderOf(context), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: imagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 48),
                      const SizedBox(height: 8),
                      Text(l10n.takePackagePhoto),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath!), fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            l10n.changePackagePhoto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.voiceNoteOptional,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.voiceNoteRecordHint,
          style: TextStyle(color: HomeColors.textMutedOf(context)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onLongPressStart: (_) => onRecordStart(),
          onLongPressEnd: (_) => onRecordEnd(),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isRecording
                  ? Colors.red.withValues(alpha: 0.15)
                  : HomeColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRecording ? Colors.red : HomeColors.borderOf(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: isRecording ? Colors.red : HomeColors.violet,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  voiceNotePath != null
                      ? l10n.voiceNoteAttached
                      : l10n.voiceNoteRecordHint,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (voiceNotePath != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClearVoice,
            child: Text(l10n.voiceNoteClear),
          ),
        ],
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.summary,
    required this.pickup,
    required this.dropoff,
    required this.itemLabel,
    required this.recipient,
    required this.imagePath,
    required this.onPlay,
  });

  final String summary;
  final String pickup;
  final String dropoff;
  final String itemLabel;
  final String recipient;
  final String? imagePath;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.easyConfirmTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 16),
        if (imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(imagePath!),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 16),
        _InfoRow(icon: Icons.trip_origin, label: pickup),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.flag_rounded, label: dropoff),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.inventory_2_rounded, label: itemLabel),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.person_rounded, label: recipient),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.volume_up_rounded),
            label: Text(
              l10n.easyConfirmPlay,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeColors.violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          summary,
          style: TextStyle(
            fontSize: 14,
            color: HomeColors.textMutedOf(context),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HomeColors.violet),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _BigChoice extends StatelessWidget {
  const _BigChoice({
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
          ? HomeColors.violet.withValues(alpha: 0.18)
          : HomeColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? HomeColors.violet : HomeColors.borderOf(context),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
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
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
