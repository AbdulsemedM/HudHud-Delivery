import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/core/easy_mode/voice_hint_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/support_launcher.dart';
import 'package:hudhud_delivery/core/widgets/centered_pin_map.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';
import 'package:hudhud_delivery/core/widgets/speak_button.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/package_item_catalog.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/nearby_driver_markers.dart';
import 'package:hudhud_delivery/features/courier/utils/nearby_drivers_poller.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/confirm_details_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
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
  PlaceResult? _pickupPlace;
  PlaceResult? _dropoffPlace;

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

  late final NearbyDriversPoller _nearbyPoller;
  Map<String, gmaps.BitmapDescriptor> _nearbyIconsByAsset = {};

  @override
  void initState() {
    super.initState();
    _nearbyPoller = NearbyDriversPoller(
      repository: CourierRepository(
        courierDataProvider:
            CourierDataProvider(apiService: ApiService.instance),
      ),
      onUpdate: () => unawaited(_onNearbyDriversUpdated()),
    );
    unawaited(preloadCommonCourierVehicleMapIcons());
    _bootstrap();
  }

  Future<void> _onNearbyDriversUpdated() async {
    await preloadCourierVehicleMapIcons(
      _nearbyPoller.result.drivers.map((d) => d.vehicleType),
    );
    if (mounted) {
      setState(() {
        _nearbyIconsByAsset = CourierVehicleMapIconCache.snapshot();
      });
    }
  }

  Future<void> _bootstrap() async {
    await VoiceHintService.instance.init();
    final user = await AuthService().getStoredUser();
    _senderPhone = user?.phone;
    if (mounted) _speakCurrentStep();
  }

  void _syncNearbyDrivers() {
    final pickup = _pickupPosition;
    _nearbyPoller.setTarget(
      latitude: pickup.latitude,
      longitude: pickup.longitude,
      vehicleType: 'motorbike',
      radius: 5,
    );
  }

  @override
  void dispose() {
    _nearbyPoller.dispose();
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

  Future<PlaceResult?> _reverseGeocodePlace(LatLng point) async {
    try {
      final places = await GooglePlacesService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      return HumanReadableAddress.pickBestPlace(places);
    } catch (_) {}
    return null;
  }

  bool _isLocationSpecificEnough(PlaceResult? place, String address) {
    if (place != null) return !place.isCityLevelOnly;
    final segments = address
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !HumanReadableAddress.isPlusCode(s))
        .toList();
    return segments.length > 1;
  }

  Future<void> _reverseGeocodePickup() async {
    final place = await _reverseGeocodePlace(_pickupPosition);
    if (!mounted) return;
    if (place != null) {
      setState(() {
        _pickupPlace = place;
        _pickupAddress = place.formattedAddress;
      });
    } else {
      setState(() {
        _pickupPlace = null;
        _pickupAddress =
            '${_pickupPosition.latitude.toStringAsFixed(5)}, ${_pickupPosition.longitude.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _reverseGeocodeDropoff() async {
    final place = await _reverseGeocodePlace(_dropoffPosition);
    if (!mounted) return;
    if (place != null) {
      setState(() {
        _dropoffPlace = place;
        _dropoffAddress = place.formattedAddress;
      });
    } else {
      setState(() {
        _dropoffPlace = null;
        _dropoffAddress =
            '${_dropoffPosition.latitude.toStringAsFixed(5)}, ${_dropoffPosition.longitude.toStringAsFixed(5)}';
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  Future<void> _goNext() async {
    final l10n = context.l10n;
    if (_step == 0) {
      if (_pickupAddress.trim().isEmpty) {
        await _reverseGeocodePickup();
      }
      if (_pickupAddress.trim().isEmpty ||
          !_isLocationSpecificEnough(_pickupPlace, _pickupAddress)) {
        _snack(l10n.pleaseSelectLocation);
        return;
      }
      setState(() => _step = 1);
      _speakCurrentStep();
      return;
    }
    if (_step == 1) {
      if (_dropoffAddress.trim().isEmpty) {
        await _reverseGeocodeDropoff();
      }
      if (_dropoffAddress.trim().isEmpty ||
          !_isLocationSpecificEnough(_dropoffPlace, _dropoffAddress)) {
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
      final phone = normalizePhoneToBackend(_recipientPhoneController.text);
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
      // showPicker needs no permission on iOS; Android needs READ_CONTACTS when
      // requesting properties.
      final status =
          await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted) {
        if (mounted) _snack(l10n.contactsPermissionRequired);
        return;
      }
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone, ContactProperty.name},
      );
      if (contact == null || !mounted) return;
      final name = contact.displayName ?? '';
      final phone =
          contact.phones.isNotEmpty ? contact.phones.first.number : '';
      setState(() {
        if (name.isNotEmpty) {
          _recipientNameController.text = name;
        }
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
      _itemType == null ? '' : PackageItemCatalog.labelFor(_itemType!, l10n),
      _recipientNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, hint) = switch (_step) {
      0 => (l10n.easyPickupTitle, l10n.easyPickupHint),
      1 => (l10n.easyDropTitle, l10n.easyDropHint),
      2 => (l10n.easyWhoReceives, null),
      3 => (l10n.easyWhatIsIt, null),
      _ => (l10n.easyConfirmTitle, null),
    };
    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.backgroundOf(context),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WizardHeader(
                step: _step,
                totalSteps: _totalSteps,
                stepLabel: l10n.easyStepOf(_step + 1, _totalSteps),
                title: title,
                hint: hint,
                onBack: _goBack,
                speakText: switch (_step) {
                  0 => '${l10n.easyPickupTitle}. ${l10n.easyPickupHint}',
                  1 => '${l10n.easyDropTitle}. ${l10n.easyDropHint}',
                  2 => l10n.easyWhoReceives,
                  3 => '${l10n.easyWhatIsIt}. ${l10n.easyPackageSize}',
                  4 => _summary(l10n),
                  _ => '',
                },
              ),
              Expanded(child: _buildStep(l10n)),
              _WizardBottomBar(
                label: _step == 4 ? l10n.actionContinue : l10n.actionNext,
                isLast: _step == 4,
                onPressed: _goNext,
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
          key: const ValueKey('easy_map_pickup'),
          title: l10n.easyPickupTitle,
          hint: l10n.easyPickupHint,
          iAmHereLabel: l10n.easyIAmHere,
          address: _pickupAddress,
          position: _pickupPosition,
          snapToGpsOnStart: true,
          markers: nearbyDriverMapMarkers(
            _nearbyPoller.result.drivers,
            iconsByAsset: _nearbyIconsByAsset,
          ),
          privacyMessage: _nearbyPoller.result.privacyMessage,
          onPositionChanged: (pos) {
            setState(() {
              _pickupPosition = LatLng(pos.latitude, pos.longitude);
            });
            _syncNearbyDrivers();
            unawaited(_reverseGeocodePickup());
          },
          onPlaceSelected: (place) {
            setState(() {
              _pickupPosition = place.coordinates;
              _pickupAddress = place.formattedAddress;
              _pickupPlace = place;
            });
            _syncNearbyDrivers();
            unawaited(_goNext());
          },
        );
      case 1:
        return _MapStep(
          key: const ValueKey('easy_map_dropoff'),
          title: l10n.easyDropTitle,
          hint: l10n.easyDropHint,
          iAmHereLabel: l10n.easyIAmHere,
          address: _dropoffAddress,
          position: _dropoffPosition,
          searchFirst: true,
          requireTapToPin: false,
          showIAmHereButton: false,
          isDropoff: true,
          onPositionChanged: (pos) {
            setState(() {
              _dropoffPosition = LatLng(pos.latitude, pos.longitude);
            });
            unawaited(_reverseGeocodeDropoff());
          },
          onPlaceSelected: (place) {
            setState(() {
              _dropoffPosition = place.coordinates;
              _dropoffAddress = place.formattedAddress;
              _dropoffPlace = place;
            });
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

class _MapStep extends StatefulWidget {
  const _MapStep({
    super.key,
    required this.title,
    required this.hint,
    required this.iAmHereLabel,
    required this.address,
    required this.position,
    this.snapToGpsOnStart = false,
    this.searchFirst = false,
    this.requireTapToPin = false,
    this.showIAmHereButton = true,
    this.isDropoff = false,
    this.markers = const {},
    this.privacyMessage,
    required this.onPositionChanged,
    required this.onPlaceSelected,
  });

  final String title;
  final String hint;
  final String iAmHereLabel;
  final String address;
  final LatLng position;

  /// When true, centers the map on GPS when the step opens.
  final bool snapToGpsOnStart;

  /// When true, opens on the search panel (map hidden until a place is chosen).
  final bool searchFirst;

  /// When true, hides the pin until the user taps the map or picks a search result.
  final bool requireTapToPin;
  final bool showIAmHereButton;
  final bool isDropoff;
  final Set<gmaps.Marker> markers;
  final String? privacyMessage;
  final ValueChanged<gmaps.LatLng> onPositionChanged;
  final ValueChanged<PlaceResult> onPlaceSelected;

  @override
  State<_MapStep> createState() => _MapStepState();
}

class _MapStepState extends State<_MapStep> {
  static const LatLng _fallbackPosition = LatLng(9.0222, 38.7468);

  gmaps.GoogleMapController? _mapController;
  LatLng _mapCenter = _fallbackPosition;
  bool _hasUserLocation = false;
  int _mapGeneration = 0;
  bool _skipNextIdleGeocode = false;
  bool _awaitingInitialGps = false;
  bool _userChoseLocation = false;
  int _gpsRequestId = 0;
  bool _isLoadingGps = false;
  bool _pinPlaced = false;
  bool _searchActive = false;
  List<PlaceResult> _searchSuggestions = [];
  bool _searchLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  bool get _showMap {
    if (widget.searchFirst && !_pinPlaced) return false;
    return !_searchActive;
  }

  bool get _showSearchPanel {
    if (widget.searchFirst && !_pinPlaced) return true;
    return _searchActive;
  }

  @override
  void initState() {
    super.initState();
    _mapCenter = widget.position;
    if (widget.snapToGpsOnStart && !widget.searchFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_getCurrentLocation());
      });
    }
  }

  Future<LocationFetchResult> _resolveGpsFix({bool forceFresh = false}) {
    return StartupLocationService.resolveFix(forceFresh: forceFresh);
  }

  void _showLocationFailureSnackBar(LocationFetchFailure? failure) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final showSettings = failure == LocationFetchFailure.permissionDenied ||
        failure == LocationFetchFailure.locationDisabled;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.locationCurrentPositionFailed),
        backgroundColor: colorScheme.error,
        action: showSettings
            ? SnackBarAction(
                label: l10n.actionOpenSettings,
                onPressed: CustomLocationService.openLocationAppSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _centerCameraOn(
    LatLng position, {
    bool remountMap = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _mapCenter = position;
      _hasUserLocation = true;
      if (remountMap) {
        _mapGeneration++;
        _mapController = null;
      }
    });

    if (remountMap) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    await _animateCameraIfReady(position);
  }

  Future<void> _movePinTo(
    LatLng position, {
    bool remountMap = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _mapCenter = position;
      _hasUserLocation = true;
      if (widget.requireTapToPin) {
        _pinPlaced = true;
      }
      if (remountMap) {
        _mapGeneration++;
        _mapController = null;
      }
    });

    widget.onPositionChanged(_toG(position));

    if (remountMap) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    await _animateCameraIfReady(position);
  }

  Future<void> _animateCameraIfReady(LatLng position) async {
    if (!mounted || _searchActive) return;

    final controller = _mapController;
    if (controller == null) return;

    _skipNextIdleGeocode = true;
    try {
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(_toG(position), 16.0),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EasyBookingWizard: animateCamera failed: $e');
      }
    }
  }

  void _onCenterLatLngChanged(gmaps.LatLng point) {
    if (_skipNextIdleGeocode) {
      _skipNextIdleGeocode = false;
      return;
    }
    if (_awaitingInitialGps && !_userChoseLocation) return;
    if (widget.requireTapToPin && !_pinPlaced) return;

    _userChoseLocation = true;
    _gpsRequestId++;
    final pin = LatLng(point.latitude, point.longitude);
    setState(() {
      _mapCenter = pin;
      _awaitingInitialGps = false;
      _isLoadingGps = false;
    });
    widget.onPositionChanged(point);
  }

  Future<void> _getCurrentLocation({bool fromUserButton = false}) async {
    if (!mounted) return;

    if (fromUserButton) {
      _userChoseLocation = false;
    }

    final requestId = ++_gpsRequestId;

    setState(() {
      _isLoadingGps = true;
      if (!fromUserButton) {
        _awaitingInitialGps = true;
      }
    });

    try {
      final gpsResult = await _resolveGpsFix(forceFresh: fromUserButton);
      if (!mounted || requestId != _gpsRequestId) return;

      if (!fromUserButton && _userChoseLocation) {
        return;
      }

      final position = gpsResult.data;
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);
        if (widget.requireTapToPin && !fromUserButton) {
          await _centerCameraOn(latLng, remountMap: true);
        } else {
          await _movePinTo(latLng, remountMap: true);
        }
      } else {
        _showLocationFailureSnackBar(gpsResult.failure);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EasyBookingWizard: GPS error: $e');
      }
      if (mounted) {
        _showLocationFailureSnackBar(LocationFetchFailure.unknown);
      }
    } finally {
      if (mounted && requestId == _gpsRequestId) {
        setState(() {
          _isLoadingGps = false;
          _awaitingInitialGps = false;
        });
      }
    }
  }

  Future<void> _revealMapAt(LatLng position) async {
    if (!mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _skipNextIdleGeocode = true;

    setState(() {
      _mapCenter = position;
      _hasUserLocation = true;
      _searchActive = false;
      _pinPlaced = true;
      _searchSuggestions = [];
      _searchLoading = false;
      _searchQuery = '';
      _mapGeneration++;
      _mapController = null;
    });

    widget.onPositionChanged(_toG(position));

    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _animateCameraIfReady(position);
  }

  Future<void> _onSearchPlaceSelected(PlaceResult place) async {
    _gpsRequestId++;
    _userChoseLocation = true;
    _awaitingInitialGps = false;
    widget.onPlaceSelected(place);

    if (widget.searchFirst) {
      await _revealMapAt(place.coordinates);
      return;
    }

    _skipNextIdleGeocode = true;

    if (_searchActive) {
      setState(() {
        _mapCenter = place.coordinates;
        _hasUserLocation = true;
        _searchActive = false;
        if (widget.requireTapToPin) {
          _pinPlaced = true;
        }
        _mapGeneration++;
        _mapController = null;
      });
      widget.onPositionChanged(_toG(place.coordinates));
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _animateCameraIfReady(place.coordinates);
      return;
    }

    await _movePinTo(place.coordinates);
  }

  Future<void> _handleMapTap(gmaps.LatLng point) async {
    if (!widget.requireTapToPin) return;

    _userChoseLocation = true;
    _awaitingInitialGps = false;
    _gpsRequestId++;
    _skipNextIdleGeocode = true;
    final pin = LatLng(point.latitude, point.longitude);
    setState(() {
      _pinPlaced = true;
      _mapCenter = pin;
      _hasUserLocation = true;
    });
    widget.onPositionChanged(point);
    await _animateCameraIfReady(pin);
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;
    if (_hasUserLocation && !_searchActive) {
      unawaited(_animateCameraIfReady(_mapCenter));
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// "Change" on the address card: clear the search box and open the keyboard.
  void _startChangingAddress() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final privacy = widget.privacyMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow(context),
            ),
            child: LocationSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: widget.searchFirst,
              initialLocation:
                  widget.address.isNotEmpty ? widget.address : null,
              expandSuggestions: true,
              onSearchActiveChanged: (active) {
                if (_searchActive != active) {
                  setState(() {
                    _searchActive = active;
                    if (active) {
                      _mapController = null;
                    }
                  });
                }
              },
              onSuggestionsStateChanged: ({
                required suggestions,
                required isLoading,
                required show,
                required query,
              }) {
                if (!mounted) return;
                setState(() {
                  _searchSuggestions = suggestions;
                  _searchLoading = isLoading;
                  _searchQuery = query;
                });
              },
              onLocationSelected: _onSearchPlaceSelected,
            ),
          ),
        ),
        if (_showSearchPanel)
          Expanded(
            child: _searchSuggestions.isEmpty &&
                    !_searchLoading &&
                    _searchQuery.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Material(
                      color: HomeColors.surfaceOf(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: dark
                            ? BorderSide(color: HomeColors.borderOf(context))
                            : BorderSide.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LocationSearchField.buildExpandedSuggestionsList(
                        suggestions: _searchSuggestions,
                        isLoading: _searchLoading,
                        query: _searchQuery,
                        useFormattedAddress: true,
                        onLocationSelected: _onSearchPlaceSelected,
                        l10n: context.l10n,
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
          )
        else if (_showMap)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    CenteredPinMap(
                      key: ValueKey('easy_map_$_mapGeneration'),
                      initialCameraPosition: gmaps.CameraPosition(
                        target: _toG(_mapCenter),
                        zoom: _hasUserLocation ? 16.0 : 13.0,
                      ),
                      idleDebounce: const Duration(milliseconds: 400),
                      onMapCreated: _onMapCreated,
                      onCenterLatLngChanged: _onCenterLatLngChanged,
                      onTap: widget.requireTapToPin ? _handleMapTap : null,
                      centerIndicator: widget.requireTapToPin && !_pinPlaced
                          ? const SizedBox.shrink()
                          : null,
                      markers: widget.markers,
                      myLocationButtonEnabled: false,
                      // Pinch to zoom still works; the +/- buttons collided
                      // with our own overlay controls.
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.showIAmHereButton) ...[
                            _IAmHerePill(
                              label: widget.iAmHereLabel,
                              loading: _isLoadingGps,
                              onTap: () =>
                                  _getCurrentLocation(fromUserButton: true),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (privacy != null && privacy.isNotEmpty) ...[
                            const _NearbyInfoBanner(
                              text:
                                  'Nearby motorbikes are shown approximately. Driver details appear after acceptance.',
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (widget.address.isNotEmpty)
                            _AddressCard(
                              address: widget.address,
                              isDropoff: widget.isDropoff,
                              changeLabel: context.l10n.actionChange,
                              onChange: _startChangingAddress,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wizard chrome
// ---------------------------------------------------------------------------

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.step,
    required this.totalSteps,
    required this.stepLabel,
    required this.title,
    required this.hint,
    required this.onBack,
    required this.speakText,
  });

  final int step;
  final int totalSteps;
  final String stepLabel;
  final String title;
  final String? hint;
  final VoidCallback onBack;
  final String speakText;

  @override
  Widget build(BuildContext context) {
    final muted = HomeColors.textMutedOf(context);
    final hintText = hint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _HeaderCircleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: onBack,
              ),
              Expanded(
                child: Text(
                  stepLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: muted,
                  ),
                ),
              ),
              SpeakButton(text: speakText),
              const _CallSupportCircle(),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _StepSegments(step: step, total: totalSteps),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              layoutBuilder: (current, previous) => Stack(
                alignment: AlignmentDirectional.topStart,
                children: [...previous, if (current != null) current],
              ),
              child: Column(
                key: ValueKey(step),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
                  if (hintText != null && hintText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      hintText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Five rounded segments; done + current are filled brand orange.
class _StepSegments extends StatelessWidget {
  const _StepSegments({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final empty = HomeColors.isDark(context)
        ? HomeColors.surfaceElevatedOf(context)
        : HomeColors.borderOf(context);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.brandOrange : empty,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i != total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppColors.softShadow(context),
          ),
          child: Material(
            color: HomeColors.surfaceOf(context),
            shape: CircleBorder(
              side: dark
                  ? BorderSide(color: HomeColors.borderOf(context))
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  size: 26,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single call-for-help affordance for the wizard (green = phone call).
class _CallSupportCircle extends StatelessWidget {
  const _CallSupportCircle();

  Future<void> _call(BuildContext context) async {
    final ok = await launchSupportPhone();
    if (!context.mounted) return;
    if (!ok) {
      AuthSnackBar.error(context, context.l10n.actionTryAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final label = context.l10n.callSupport;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: AppColors.successColor.withValues(alpha: dark ? 0.22 : 0.12),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _call(context),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.call_rounded,
                  size: 24,
                  color: AppColors.successColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WizardBottomBar extends StatelessWidget {
  const _WizardBottomBar({
    required this.label,
    required this.isLast,
    required this.onPressed,
  });

  final String label;
  final bool isLast;
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
                backgroundColor: AppColors.brandOrange,
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
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    size: 24,
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

// ---------------------------------------------------------------------------
// Map overlays
// ---------------------------------------------------------------------------

/// Compact white pill: "use my location".
class _IAmHerePill extends StatelessWidget {
  const _IAmHerePill({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    final radius = BorderRadius.circular(AppColors.radiusFull);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x261B1530),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: loading
                      ? Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: accent,
                          ),
                        )
                      : Icon(Icons.my_location_rounded,
                          color: accent, size: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent,
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

class _NearbyInfoBanner extends StatelessWidget {
  const _NearbyInfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: HomeColors.violetTintOf(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.two_wheeler_rounded,
              size: 18,
              color: HomeColors.violetOf(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDropoff,
    required this.changeLabel,
    required this.onChange,
  });

  final String address;
  final bool isDropoff;
  final String changeLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final accent =
        isDropoff ? HomeColors.violetOf(context) : AppColors.brandOrange;
    final tint = isDropoff
        ? HomeColors.violetTintOf(context)
        : (dark ? AppColors.orangeTintDark : AppColors.orangeTint);
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x261B1530),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark
              ? BorderSide(color: HomeColors.borderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              _IconTile(
                icon:
                    isDropoff ? Icons.flag_rounded : Icons.location_on_rounded,
                color: accent,
                background: tint,
                size: 48,
                iconSize: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onChange,
                icon: const Icon(Icons.edit_location_alt_rounded, size: 20),
                label: Text(changeLabel),
                style: TextButton.styleFrom(
                  foregroundColor: HomeColors.violetOf(context),
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared step pieces
// ---------------------------------------------------------------------------

/// Surface card with the app's soft shadow (light) / hairline (dark).
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: dark
              ? BorderSide(color: HomeColors.borderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: HomeColors.textPrimaryOf(context),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 52,
    this.iconSize = 26,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

InputDecoration _easyInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? hint,
}) {
  final radius = BorderRadius.circular(16);
  final border = HomeColors.borderOf(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: HomeColors.surfaceOf(context),
    labelStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: HomeColors.textMutedOf(context),
    ),
    floatingLabelStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: HomeColors.violetOf(context),
    ),
    hintStyle: TextStyle(color: HomeColors.textMutedOf(context)),
    prefixIcon: Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 10),
      child: Icon(icon, color: HomeColors.violetOf(context), size: 24),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: HomeColors.violetOf(context), width: 1.8),
    ),
  );
}

// ---------------------------------------------------------------------------
// Step 3 — recipient
// ---------------------------------------------------------------------------

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
    final muted = HomeColors.textMutedOf(context);
    final fieldStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: HomeColors.textPrimaryOf(context),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _SurfaceCard(
          onTap: onPickContact,
          padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
          child: Row(
            children: [
              _IconTile(
                icon: Icons.contacts_rounded,
                color: HomeColors.violetOf(context),
                background: HomeColors.violetTintOf(context),
                size: 60,
                iconSize: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.easyPickContact,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 28, color: muted),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: HomeColors.borderOf(context))),
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.easyOrTypePhone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ),
            ),
            Expanded(child: Divider(color: HomeColors.borderOf(context))),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          style: fieldStyle,
          decoration: _easyInputDecoration(
            context,
            label: l10n.recipientNames,
            icon: Icons.person_rounded,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: fieldStyle,
          decoration: _easyInputDecoration(
            context,
            label: l10n.recipientContactNumber,
            hint: l10n.senderPhoneExample,
            icon: Icons.phone_rounded,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — package
// ---------------------------------------------------------------------------

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
    final dark = HomeColors.isDark(context);
    final orangeTint = dark ? AppColors.orangeTintDark : AppColors.orangeTint;
    const recordColor = AppColors.errorColor;
    final hasVoice = voiceNotePath != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.88,
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
        const SizedBox(height: 28),
        _SectionTitle(l10n.easyPackageSize),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final entry in [
              ('small', l10n.easySizeSmall, 20.0),
              ('medium', l10n.easySizeMedium, 28.0),
              ('large', l10n.easySizeLarge, 36.0),
            ]) ...[
              Expanded(
                child: SizedBox(
                  height: 128,
                  child: _BigChoice(
                    selected: sizeId == entry.$1,
                    icon: Icons.inventory_2_rounded,
                    iconSize: entry.$3,
                    label: entry.$2,
                    onTap: () => onSelectSize(entry.$1),
                  ),
                ),
              ),
              if (entry.$1 != 'large') const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 28),
        _SurfaceCard(
          onTap: onTakePhoto,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 168,
            child: imagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: orangeTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          size: 34,
                          color: AppColors.brandOrange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.takePackagePhoto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath!), fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x8C000000)],
                            stops: [0.45, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_camera_rounded,
                                size: 18,
                                color: AppColors.brandInk,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.changePackagePhoto,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 28),
        _SectionTitle(l10n.voiceNoteOptional),
        const SizedBox(height: 12),
        GestureDetector(
          onLongPressStart: (_) => onRecordStart(),
          onLongPressEnd: (_) => onRecordEnd(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            decoration: BoxDecoration(
              color: isRecording
                  ? recordColor.withValues(alpha: dark ? 0.2 : 0.1)
                  : HomeColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isRecording
                    ? recordColor
                    : (dark
                        ? HomeColors.borderOf(context)
                        : Colors.transparent),
                width: isRecording ? 2 : 1,
              ),
              boxShadow: isRecording ? null : AppColors.softShadow(context),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording
                        ? recordColor
                        : HomeColors.violetTintOf(context),
                  ),
                  child: Icon(
                    isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: isRecording
                        ? Colors.white
                        : HomeColors.violetOf(context),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    hasVoice
                        ? l10n.voiceNoteAttached
                        : l10n.voiceNoteRecordHint,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                if (hasVoice && !isRecording)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.successColor,
                    size: 26,
                  ),
              ],
            ),
          ),
        ),
        if (hasVoice) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onClearVoice,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: Text(l10n.voiceNoteClear),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorColor,
                minimumSize: const Size(48, 48),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5 — review
// ---------------------------------------------------------------------------

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
    final dark = HomeColors.isDark(context);
    final orangeTint = dark ? AppColors.orangeTintDark : AppColors.orangeTint;
    final accent = HomeColors.violetOf(context);
    final indigoTint = HomeColors.violetTintOf(context);
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: 80,
      endIndent: 16,
      color: HomeColors.borderOf(context),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _SurfaceCard(
          padding: EdgeInsets.zero,
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imagePath != null)
                Image.file(
                  File(imagePath!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.trip_origin_rounded,
                color: AppColors.brandOrange,
                background: orangeTint,
                caption: l10n.pickupLocationLabel,
                label: pickup,
              ),
              divider,
              _InfoRow(
                icon: Icons.flag_rounded,
                color: accent,
                background: indigoTint,
                caption: l10n.deliveryLocationLabel,
                label: dropoff,
              ),
              divider,
              _InfoRow(
                icon: Icons.inventory_2_rounded,
                color: accent,
                background: indigoTint,
                caption: l10n.whatAreYouSending,
                label: itemLabel,
              ),
              divider,
              _InfoRow(
                icon: Icons.person_rounded,
                color: accent,
                background: indigoTint,
                caption: l10n.recipient,
                label: recipient,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: Material(
            color: indigoTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPlay,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up_rounded, color: accent, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    l10n.easyConfirmPlay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            summary,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: HomeColors.textMutedOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.background,
    required this.caption,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String caption;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _IconTile(
            icon: icon,
            color: color,
            background: background,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Big picture-first choice tile. Selected = indigo border + tint + check.
class _BigChoice extends StatelessWidget {
  const _BigChoice({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 30,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final accent = HomeColors.violetOf(context);
    final tint = HomeColors.violetTintOf(context);
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: selected ? null : AppColors.softShadow(context),
        ),
        child: Material(
          color: selected ? tint : HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: selected
                ? BorderSide(color: accent, width: 2)
                : (dark
                    ? BorderSide(color: HomeColors.borderOf(context))
                    : BorderSide.none),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color:
                                selected ? HomeColors.surfaceOf(context) : tint,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(icon, size: iconSize, color: accent),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w700,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selected)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
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
