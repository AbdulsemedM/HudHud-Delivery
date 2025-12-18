import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'finding_courier_screen.dart';

class ConfirmDetailsScreen extends StatelessWidget {
  final String pickupLocation;
  final String deliveryLocation;
  final LatLng? pickupPosition;
  final LatLng? deliveryPosition;
  final String selectedVehicle;
  final String itemType;
  final String quantity;
  final String whoPays;
  final String paymentType;
  final String recipientName;
  final String recipientPhone;
  final String? packageImagePath;

  const ConfirmDetailsScreen({
    super.key,
    required this.pickupLocation,
    required this.deliveryLocation,
    this.pickupPosition,
    this.deliveryPosition,
    required this.selectedVehicle,
    required this.itemType,
    required this.quantity,
    required this.whoPays,
    required this.paymentType,
    required this.recipientName,
    required this.recipientPhone,
    this.packageImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final MapController mapController = MapController();
    
    // Calculate center point for map
    LatLng mapCenter = const LatLng(37.7749, -122.4194); // Default
    if (pickupPosition != null && deliveryPosition != null) {
      mapCenter = LatLng(
        (pickupPosition!.latitude + deliveryPosition!.latitude) / 2,
        (pickupPosition!.longitude + deliveryPosition!.longitude) / 2,
      );
    } else if (pickupPosition != null) {
      mapCenter = pickupPosition!;
    } else if (deliveryPosition != null) {
      mapCenter = deliveryPosition!;
    }

    // Calculate bounds if both positions exist
    void fitBounds() {
      if (pickupPosition != null && deliveryPosition != null) {
        final bounds = LatLngBounds(pickupPosition!, deliveryPosition!);
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    }

    // Wait for map to be ready, then fit bounds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pickupPosition != null && deliveryPosition != null) {
        fitBounds();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hudhuddelivery.app',
                maxZoom: 18,
              ),
              // Polyline between pickup and delivery
              if (pickupPosition != null && deliveryPosition != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [pickupPosition!, deliveryPosition!],
                      strokeWidth: 3.0,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Pickup marker (red)
                  if (pickupPosition != null)
                    Marker(
                      point: pickupPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  // Delivery marker (green)
                  if (deliveryPosition != null)
                    Marker(
                      point: deliveryPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Motorcycle icon
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.two_wheeler,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
          ),
          // Bottom Sheet Modal
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Confirm Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Location Details
                            _DetailRow(
                              icon: Icons.location_on,
                              iconColor: Colors.red,
                              label: 'Pickup Location',
                              value: pickupLocation,
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.location_on,
                              iconColor: Colors.green,
                              label: 'Delivery Location',
                              value: deliveryLocation,
                            ),
                            const SizedBox(height: 24),
                            // Package and Recipient Details
                            _DetailRow(
                              label: 'What you are sending',
                              value: itemType,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Recipient',
                              value: recipientName,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Recipient contact number',
                              value: recipientPhone,
                            ),
                            const SizedBox(height: 24),
                            // Payment and Fee
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailRow(
                                    label: 'Payment',
                                    value: paymentType,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Estimated fee',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ETB 150',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Edit Details button
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Edit Details',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Look for Courier button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FindingCourierScreen(
                                        pickupLocation: pickupLocation,
                                        deliveryLocation: deliveryLocation,
                                        pickupPosition: pickupPosition,
                                        deliveryPosition: deliveryPosition,
                                        selectedVehicle: selectedVehicle,
                                        itemType: itemType,
                                        quantity: quantity,
                                        whoPays: whoPays,
                                        paymentType: paymentType,
                                        recipientName: recipientName,
                                        recipientPhone: recipientPhone,
                                        packageImagePath: packageImagePath,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Look for Courier',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _DetailRow({
    this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

