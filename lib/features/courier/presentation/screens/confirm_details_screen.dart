import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'finding_courier_screen.dart';

class ConfirmDetailsScreen extends StatefulWidget {
  final String pickupLocation;
  final String deliveryLocation;
  final LatLng? pickupPosition;
  final LatLng? deliveryPosition;
  final String selectedVehicle;
  final String itemType;
  final String quantity;
  final double packageWeight;
  final String packageDescription;
  final bool isInstantDelivery;
  final DateTime? scheduledPickup;
  final DateTime? scheduledDelivery;
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
    required this.packageWeight,
    required this.packageDescription,
    required this.isInstantDelivery,
    this.scheduledPickup,
    this.scheduledDelivery,
    required this.whoPays,
    required this.paymentType,
    required this.recipientName,
    required this.recipientPhone,
    this.packageImagePath,
  });

  @override
  State<ConfirmDetailsScreen> createState() => _ConfirmDetailsScreenState();
}

class _ConfirmDetailsScreenState extends State<ConfirmDetailsScreen> {
  late final CourierRepository _courierRepository;
  late final MapController _mapController;

  bool _isLoadingEstimate = true;
  bool _isLoadingRequest = false;
  double? _estimatedCost;
  double? _estimatedDistance;
  int? _estimatedDuration;
  String _estimatedCurrency = 'ETB';
  String? _estimateError;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _fetchEstimate();
  }

  String _mapPackageType(String itemType) {
    const mapping = {
      'Documents': 'document',
      'Electronics/Gadgets': 'electronics',
      'Food': 'food',
      'Clothing': 'clothing',
      'Books': 'books',
      'Other': 'other',
    };
    return mapping[itemType] ?? 'other';
  }

  String _mapVehicleType(String vehicle) {
    const mapping = {
      'motorcycle': 'motorbike',
      'car': 'car',
      'van': 'van',
    };
    return mapping[vehicle] ?? vehicle;
  }

  String _mapPaymentMethod(String paymentType) {
    // paymentType is already the API id from fetched payment methods
    if (paymentType.isNotEmpty) return paymentType;
    return 'cash';
  }

  /// Formats DateTime for API as "yyyy-MM-ddTHH:mm:ss" (e.g. "2024-01-15T14:30:00")
  String? _formatScheduledDateTime(DateTime? dt) {
    if (dt == null) return null;
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchEstimate() async {
    if (widget.pickupPosition == null || widget.deliveryPosition == null) {
      setState(() {
        _isLoadingEstimate = false;
        _estimateError = 'Location coordinates required for estimate';
      });
      return;
    }

    final result = await _courierRepository.estimateDelivery(
      packageType: _mapPackageType(widget.itemType),
      packageWeight: widget.packageWeight,
      pickupLatitude: widget.pickupPosition!.latitude,
      pickupLongitude: widget.pickupPosition!.longitude,
      dropoffLatitude: widget.deliveryPosition!.latitude,
      dropoffLongitude: widget.deliveryPosition!.longitude,
      vehicleType: _mapVehicleType(widget.selectedVehicle),
      serviceType: widget.isInstantDelivery ? 'express' : 'standard',
    );

    if (mounted) {
      setState(() {
        _isLoadingEstimate = false;
        if (result['success'] == true) {
          _estimatedCost = result['estimatedCost'] as double?;
          _estimatedDistance = result['estimatedDistance'] as double?;
          _estimatedDuration = result['estimatedDuration'] as int?;
          _estimatedCurrency = result['currency'] as String? ?? 'ETB';
          _estimateError = null;
        } else {
          _estimateError = result['message'] as String?;
        }
      });
    }
  }

  Future<void> _createDeliveryRequest() async {
    final user = await AuthService().getStoredUser();

    final requestData = <String, dynamic>{
      'package_type': _mapPackageType(widget.itemType),
      'package_description': widget.packageDescription.isNotEmpty
          ? widget.packageDescription
          : widget.itemType,
      'package_weight': widget.packageWeight,
      'package_dimensions': '30x20x5 cm',
      'estimated_value': 0,
      'pickup_location': widget.pickupLocation,
      'pickup_latitude': widget.pickupPosition?.latitude ?? 0,
      'pickup_longitude': widget.pickupPosition?.longitude ?? 0,
      'dropoff_location': widget.deliveryLocation,
      'dropoff_latitude': widget.deliveryPosition?.latitude ?? 0,
      'dropoff_longitude': widget.deliveryPosition?.longitude ?? 0,
      'vehicle_type': _mapVehicleType(widget.selectedVehicle),
      'service_type': widget.isInstantDelivery ? 'express' : 'standard',
      'scheduled_pickup': _formatScheduledDateTime(widget.scheduledPickup),
      'scheduled_delivery': _formatScheduledDateTime(widget.scheduledDelivery),
      'estimated_distance': _estimatedDistance ?? 0,
      'estimated_duration': _estimatedDuration ?? 0,
      'estimated_cost': _estimatedCost ?? 0,
      'payment_method': _mapPaymentMethod(widget.paymentType),
      'requires_signature': false,
      'insurance_required': false,
      'special_instructions': '',
      'sender_name': user?.name ?? '',
      'sender_phone': user?.phone ?? '',
      'receiver_name': widget.recipientName,
      'receiver_phone': widget.recipientPhone,
    };

    setState(() => _isLoadingRequest = true);

    final result = await _courierRepository.createDeliveryRequest(
      requestData: requestData,
    );

    if (!mounted) return;

    setState(() => _isLoadingRequest = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindingCourierScreen(
            pickupLocation: widget.pickupLocation,
            deliveryLocation: widget.deliveryLocation,
            pickupPosition: widget.pickupPosition,
            deliveryPosition: widget.deliveryPosition,
            selectedVehicle: widget.selectedVehicle,
            itemType: widget.itemType,
            quantity: widget.quantity,
            whoPays: widget.whoPays,
            paymentType: widget.paymentType,
            recipientName: widget.recipientName,
            recipientPhone: widget.recipientPhone,
            packageImagePath: widget.packageImagePath,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ??
              'Failed to create delivery request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng mapCenter = const LatLng(37.7749, -122.4194);
    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      mapCenter = LatLng(
        (widget.pickupPosition!.latitude + widget.deliveryPosition!.latitude) /
            2,
        (widget.pickupPosition!.longitude +
                widget.deliveryPosition!.longitude) /
            2,
      );
    } else if (widget.pickupPosition != null) {
      mapCenter = widget.pickupPosition!;
    } else if (widget.deliveryPosition != null) {
      mapCenter = widget.deliveryPosition!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pickupPosition != null && widget.deliveryPosition != null) {
        final bounds =
            LatLngBounds(widget.pickupPosition!, widget.deliveryPosition!);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });

    String estimatedFeeText = 'ETB 150';
    if (_isLoadingEstimate) {
      estimatedFeeText = 'Loading...';
    } else if (_estimateError != null) {
      estimatedFeeText = 'N/A';
    } else if (_estimatedCost != null) {
      estimatedFeeText =
          '$_estimatedCurrency ${_estimatedCost!.toStringAsFixed(2)}';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hudhuddelivery.app',
                maxZoom: 18,
              ),
              if (widget.pickupPosition != null &&
                  widget.deliveryPosition != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        widget.pickupPosition!,
                        widget.deliveryPosition!
                      ],
                      strokeWidth: 3.0,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (widget.pickupPosition != null)
                    Marker(
                      point: widget.pickupPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  if (widget.deliveryPosition != null)
                    Marker(
                      point: widget.deliveryPosition!,
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
                            _DetailRow(
                              icon: Icons.location_on,
                              iconColor: Colors.red,
                              label: 'Pickup Location',
                              value: widget.pickupLocation,
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.location_on,
                              iconColor: Colors.green,
                              label: 'Delivery Location',
                              value: widget.deliveryLocation,
                            ),
                            const SizedBox(height: 24),
                            _DetailRow(
                              label: 'What you are sending',
                              value: widget.itemType,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Recipient',
                              value: widget.recipientName,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Recipient contact number',
                              value: widget.recipientPhone,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailRow(
                                    label: 'Payment',
                                    value: widget.paymentType,
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
                                      estimatedFeeText,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    if (_estimateError != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _estimateError!,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
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
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoadingRequest
                                    ? null
                                    : _createDeliveryRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoadingRequest
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
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
