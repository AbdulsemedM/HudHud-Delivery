import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/nominatim_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/location_search_field.dart';

class LocationSearchScreen extends StatefulWidget {
  final String? currentLocation;

  const LocationSearchScreen({Key? key, this.currentLocation}) : super(key: key);

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {};

  LatLng _currentPosition = const LatLng(9.0222, 38.7468); // Default to Addis Ababa
  bool _isLoadingCurrentLocation = false;
  PlaceResult? _selectedPlace;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      final position = await CustomLocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _updateMarker(_currentPosition, isCurrentLocation: true);
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(_currentPosition), 15.0),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  void _updateMarker(LatLng position,
      {bool isCurrentLocation = false, PlaceResult? place}) {
    setState(() {
      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pin'),
          position: _toG(position),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            isCurrentLocation
                ? gmaps.BitmapDescriptor.hueAzure
                : gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      };
    });
  }

  void _handleMapTap(gmaps.LatLng point) async {
    setState(() {
      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pin'),
          position: point,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      };
    });

    try {
      final places = await NominatimService.reverseGeocode(
        point.latitude,
        point.longitude,
      );

      if (places.isNotEmpty) {
        setState(() {
          _selectedPlace = places.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location details')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LocationSearchField(
              onLocationSelected: (place) {
                setState(() {
                  _selectedPlace = place;
                  _currentPosition = LatLng(
                    place.coordinates.latitude,
                    place.coordinates.longitude,
                  );
                  _updateMarker(_currentPosition, place: place);
                  _mapController?.moveCamera(
                    gmaps.CameraUpdate.newLatLngZoom(
                        _toG(_currentPosition), 15.0),
                  );
                });
              },
              initialLocation: widget.currentLocation,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target: _toG(_currentPosition),
                    zoom: 13.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _handleMapTap,
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'current_location',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _getCurrentLocation,
                        child: Icon(
                          Icons.my_location,
                          color: _isLoadingCurrentLocation
                              ? Colors.grey
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedPlace != null) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location:',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPlace!.shortAddress,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPlace!.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coordinates: ${_selectedPlace!.coordinates.latitude}, ${_selectedPlace!.coordinates.longitude}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context, {
                          'address': _selectedPlace!.shortAddress,
                          'coordinates': _selectedPlace!.coordinates,
                        });
                      },
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
