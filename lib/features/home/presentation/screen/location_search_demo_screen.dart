import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';

class LocationSearchDemoScreen extends StatefulWidget {
  const LocationSearchDemoScreen({Key? key}) : super(key: key);

  @override
  State<LocationSearchDemoScreen> createState() => _LocationSearchDemoScreenState();
}

class _LocationSearchDemoScreenState extends State<LocationSearchDemoScreen> {
  final TextEditingController _locationController = TextEditingController();
  PlaceResult? _selectedLocation;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Search Demo'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a location:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LocationSearchField(
              controller: _locationController,
              hintText: 'Search for a location...',
              autofocus: true,
              onLocationSelected: (place) {
                setState(() {
                  _selectedLocation = place;
                });
              },
            ),
            const SizedBox(height: 32),
            if (_selectedLocation != null) ...[              
              const Text(
                'Selected Location:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLocation!.shortAddress,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedLocation!.displayName,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Coordinates: ${_selectedLocation!.coordinates.latitude.toStringAsFixed(6)}, ${_selectedLocation!.coordinates.longitude.toStringAsFixed(6)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Return the selected location to the previous screen
                  Navigator.pop(context, _selectedLocation!.shortAddress);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Use This Location',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}