import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

/// Human-readable status line for the active-delivery home card.
String activeDeliveryStatusMessage(
  AppLocalizations l10n,
  String? rawStatus,
) {
  final status = (rawStatus ?? '').toLowerCase().trim().replaceAll(' ', '_');

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
    case 'pickup_assigned':
    case 'on_the_way_to_pickup':
    case 'en_route_pickup':
      return 'Courier on the way to pickup';
    case 'arrived_at_pickup':
    case 'at_pickup':
      return 'Courier at pickup';
    case 'picked_up':
    case 'package_picked_up':
    case 'en_route_dropoff':
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
    final rawStatus = resolveDeliveryStatus(delivery);
    final statusMessage = activeDeliveryStatusMessage(l10n, rawStatus);
    final pickupAddress = delivery['pickup_location']?.toString() ?? '';
    final dropoffAddress = delivery['dropoff_location']?.toString() ?? '';

    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(24);
    final statusColor = StatusChip.colorForStatus(rawStatus ?? '');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
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
        child: InkWell(
          onTap: widget.onTrack,
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                              alpha: dark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.delivery_dining_rounded,
                            size: 28,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: HomeColors.textPrimaryOf(context),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (rawStatus != null &&
                                      rawStatus.isNotEmpty) ...[
                                    StatusChip(status: rawStatus),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      orderId,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: HomeColors.textMutedOf(context),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AddressLine(
                      label: l10n.pickupLocationLabel,
                      value: _truncateAddress(pickupAddress),
                      icon: Icons.trip_origin_rounded,
                      iconColor: HomeColors.orange,
                      showConnector: true,
                    ),
                    _AddressLine(
                      label: l10n.deliveryDetailsDropoff,
                      value: _truncateAddress(dropoffAddress),
                      icon: Icons.location_on_rounded,
                      iconColor: HomeColors.violetOf(context),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: widget.onTrack,
                        style: FilledButton.styleFrom(
                          backgroundColor: HomeColors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.near_me_rounded, size: 24),
                        label: Text(
                          l10n.courierTrackDeliveryCta,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
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
                22.0,
              ),
            ),
            gmaps.Marker(
              markerId: const gmaps.MarkerId('dropoff'),
              position: dropoff,
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                266.0,
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
      color: HomeColors.violetTintOf(context),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: HomeColors.surfaceOf(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_rounded,
                  color: HomeColors.violetOf(context),
                  size: 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Open map to track',
                style: TextStyle(
                  color: HomeColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
    this.showConnector = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: dark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: HomeColors.borderOf(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: showConnector ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: HomeColors.textMutedOf(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: HomeColors.textPrimaryOf(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
