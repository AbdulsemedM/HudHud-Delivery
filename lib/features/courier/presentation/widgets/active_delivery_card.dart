import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

/// Human-readable status line for the active-delivery home card.
String activeDeliveryStatusMessage(
  AppLocalizations l10n,
  String? rawStatus,
) {
  final status = (rawStatus ?? '')
      .toLowerCase()
      .trim()
      .replaceAll(' ', '_');

  switch (status) {
    case 'pending_payment':
    case 'pending':
      return l10n.orderStatusPending;
    case 'confirmed':
    case 'accepted':
      return l10n.orderStatusConfirmed;
    case 'searching':
    case 'finding_courier':
    case 'looking_for_courier':
      return l10n.courierDeliveryStatusInProgress;
    case 'assigned':
    case 'courier_assigned':
    case 'driver_assigned':
    case 'on_the_way_to_pickup':
      return 'Courier on the way to pickup';
    case 'arrived_at_pickup':
    case 'at_pickup':
      return 'Courier at pickup';
    case 'picked_up':
    case 'package_picked_up':
      return l10n.orderStatusTextPickedUp;
    case 'in_transit':
    case 'on_the_way':
    case 'out_for_delivery':
      return l10n.orderStatusOutForDelivery;
    case 'arrived_at_dropoff':
    case 'at_dropoff':
      return 'Courier at dropoff';
    case 'delivered':
    case 'completed':
      return l10n.orderStatusDelivered;
    case 'cancelled':
    case 'canceled':
      return l10n.orderStatusCancelled;
    default:
      if (status.isEmpty) return l10n.courierDeliveryStatusInProgress;
      return status.replaceAll('_', ' ');
  }
}

gmaps.LatLng? parseDeliveryGLatLng(dynamic lat, dynamic lng) {
  final latVal =
      lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '');
  final lngVal =
      lng is num ? lng.toDouble() : double.tryParse(lng?.toString() ?? '');
  if (latVal == null || lngVal == null) return null;
  return gmaps.LatLng(latVal, lngVal);
}

LatLng? parseDeliveryLatLng(dynamic lat, dynamic lng) {
  final g = parseDeliveryGLatLng(lat, lng);
  if (g == null) return null;
  return LatLng(g.latitude, g.longitude);
}

String _truncateAddress(String value, {int max = 48}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '—';
  if (trimmed.length <= max) return trimmed;
  return '${trimmed.substring(0, max - 1)}…';
}

/// Clear active-delivery card with mini map + status + Track CTA.
class ActiveDeliveryCard extends StatefulWidget {
  const ActiveDeliveryCard({
    super.key,
    required this.delivery,
    required this.onTrack,
  });

  final Map<String, dynamic> delivery;
  final VoidCallback onTrack;

  @override
  State<ActiveDeliveryCard> createState() => _ActiveDeliveryCardState();
}

class _ActiveDeliveryCardState extends State<ActiveDeliveryCard> {
  gmaps.GoogleMapController? _mapController;

  gmaps.LatLng? get _pickup => parseDeliveryGLatLng(
        widget.delivery['pickup_latitude'],
        widget.delivery['pickup_longitude'],
      );

  gmaps.LatLng? get _dropoff => parseDeliveryGLatLng(
        widget.delivery['dropoff_latitude'],
        widget.delivery['dropoff_longitude'],
      );

  bool get _hasMapCoords => _pickup != null && _dropoff != null;

  Future<void> _fitBounds() async {
    final pickup = _pickup;
    final dropoff = _dropoff;
    final controller = _mapController;
    if (pickup == null || dropoff == null || controller == null) return;

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        pickup.latitude < dropoff.latitude ? pickup.latitude : dropoff.latitude,
        pickup.longitude < dropoff.longitude
            ? pickup.longitude
            : dropoff.longitude,
      ),
      northeast: gmaps.LatLng(
        pickup.latitude > dropoff.latitude ? pickup.latitude : dropoff.latitude,
        pickup.longitude > dropoff.longitude
            ? pickup.longitude
            : dropoff.longitude,
      ),
    );

    try {
      await controller.moveCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 48),
      );
    } catch (_) {
      await controller.moveCamera(
        gmaps.CameraUpdate.newLatLngZoom(pickup, 13),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final delivery = widget.delivery;
    final id = delivery['id'];
    final orderId = id != null ? 'DEL-$id' : '—';
    final rawStatus =
        (delivery['current_status'] ?? delivery['status'])?.toString();
    final statusMessage = activeDeliveryStatusMessage(l10n, rawStatus);
    final pickupAddress =
        delivery['pickup_location']?.toString() ?? '';
    final dropoffAddress =
        delivery['dropoff_location']?.toString() ?? '';

    return Material(
      color: HomeColors.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusLG),
      child: InkWell(
        onTap: widget.onTrack,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(color: HomeColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: _hasMapCoords
                    ? _MiniMap(
                        pickup: _pickup!,
                        dropoff: _dropoff!,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _fitBounds();
                          });
                        },
                        onTap: widget.onTrack,
                      )
                    : _MapPlaceholder(onTap: widget.onTrack),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            statusMessage,
                            style: const TextStyle(
                              color: HomeColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (rawStatus != null && rawStatus.isNotEmpty)
                          StatusChip(status: rawStatus),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      orderId,
                      style: const TextStyle(
                        color: HomeColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AddressLine(
                      label: l10n.pickupLocationLabel,
                      value: _truncateAddress(pickupAddress),
                      icon: Icons.trip_origin_rounded,
                      iconColor: HomeColors.orange,
                    ),
                    const SizedBox(height: 8),
                    _AddressLine(
                      label: l10n.deliveryDetailsDropoff,
                      value: _truncateAddress(dropoffAddress),
                      icon: Icons.location_on_rounded,
                      iconColor: HomeColors.violet,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: widget.onTrack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeColors.violet,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.courierTrackDeliveryCta,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({
    required this.pickup,
    required this.dropoff,
    required this.onMapCreated,
    required this.onTap,
  });

  final gmaps.LatLng pickup;
  final gmaps.LatLng dropoff;
  final void Function(gmaps.GoogleMapController) onMapCreated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: pickup,
            zoom: 12,
          ),
          markers: {
            gmaps.Marker(
              markerId: const gmaps.MarkerId('pickup'),
              position: pickup,
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueOrange,
              ),
            ),
            gmaps.Marker(
              markerId: const gmaps.MarkerId('dropoff'),
              position: dropoff,
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueViolet,
              ),
            ),
          },
          onMapCreated: onMapCreated,
          liteModeEnabled: true,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeColors.surfaceElevated,
      child: InkWell(
        onTap: onTap,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                color: HomeColors.violet,
                size: 40,
              ),
              SizedBox(height: 8),
              Text(
                'Open map to track',
                style: TextStyle(
                  color: HomeColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: HomeColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: HomeColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
