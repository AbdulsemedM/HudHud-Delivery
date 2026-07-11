import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/centered_pin_map.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';
import 'package:hudhud_delivery/features/addresses/utils/address_fields_mapper.dart';
import 'package:latlong2/latlong.dart';

class AddressMapPickerScreen extends StatefulWidget {
  const AddressMapPickerScreen({super.key});

  @override
  State<AddressMapPickerScreen> createState() => _AddressMapPickerScreenState();
}

class _AddressMapPickerScreenState extends State<AddressMapPickerScreen> {
  gmaps.GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(9.0222, 38.7468);
  bool _isLoadingCurrentLocation = false;
  PlaceResult? _selectedPlace;
  bool _skipNextIdleGeocode = false;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _reverseGeocodeCenter(gmaps.LatLng point) async {
    try {
      final places = await GooglePlacesService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      final best = HumanReadableAddress.pickBestPlace(places);
      if (best != null) {
        setState(() => _selectedPlace = best);
      }
    } catch (_) {}
  }

  void _onCenterLatLngChanged(gmaps.LatLng point) {
    if (_skipNextIdleGeocode) {
      _skipNextIdleGeocode = false;
      return;
    }
    unawaited(_reverseGeocodeCenter(point));
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);
    try {
      final position = await CustomLocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _skipNextIdleGeocode = true;
        await _mapController?.moveCamera(
          gmaps.CameraUpdate.newLatLngZoom(_toG(_currentPosition), 15.0),
        );
        await _reverseGeocodeCenter(_toG(_currentPosition));
      }
    } finally {
      if (mounted) setState(() => _isLoadingCurrentLocation = false);
    }
  }

  void _onPlaceSelected(PlaceResult place) {
    setState(() {
      _selectedPlace = place;
      _currentPosition = place.coordinates;
    });
    _skipNextIdleGeocode = true;
    _mapController?.moveCamera(
      gmaps.CameraUpdate.newLatLngZoom(_toG(place.coordinates), 15.0),
    );
  }

  void _confirm() {
    if (_selectedPlace == null) return;
    final mapped = AddressFieldsMapper.fromPlaceResult(_selectedPlace!);
    Navigator.pop(context, {
      ...mapped,
      'place': _selectedPlace,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addressMapPickerTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: LocationSearchField(
              onLocationSelected: _onPlaceSelected,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                CenteredPinMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target: _toG(_currentPosition),
                    zoom: 15,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onCenterLatLngChanged: _onCenterLatLngChanged,
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    onPressed:
                        _isLoadingCurrentLocation ? null : _getCurrentLocation,
                    child: Icon(
                      Icons.my_location,
                      color: _isLoadingCurrentLocation
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedPlace != null)
            Material(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selectedPlace!.shortAddress,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                        ),
                        onPressed: _confirm,
                        child: Text(l10n.addressMapUseLocation),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
