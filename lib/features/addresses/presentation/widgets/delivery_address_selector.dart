import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/saved_location_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_repository.dart';
import 'package:hudhud_delivery/features/addresses/model/address_model.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/address_map_picker_screen.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/addresses_list_screen.dart';
import 'package:hudhud_delivery/features/home/presentation/screen/location_search_screen.dart';
import 'package:latlong2/latlong.dart';

typedef DeliveryAddressCallback = void Function({
  required String address,
  double? latitude,
  double? longitude,
});

/// Opens bottom sheet to pick delivery address (saved, map, search, add new).
Future<void> showDeliveryAddressPicker({
  required BuildContext context,
  required String currentAddress,
  required DeliveryAddressCallback onAddressChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _DeliveryAddressPickerSheet(
      currentAddress: currentAddress,
      onAddressChanged: onAddressChanged,
    ),
  );
}

class _DeliveryAddressPickerSheet extends StatefulWidget {
  final String currentAddress;
  final DeliveryAddressCallback onAddressChanged;

  const _DeliveryAddressPickerSheet({
    required this.currentAddress,
    required this.onAddressChanged,
  });

  @override
  State<_DeliveryAddressPickerSheet> createState() =>
      _DeliveryAddressPickerSheetState();
}

class _DeliveryAddressPickerSheetState extends State<_DeliveryAddressPickerSheet> {
  late final AddressesRepository _repository;
  List<AddressModel> _saved = [];
  bool _loadingSaved = false;

  @override
  void initState() {
    super.initState();
    _repository = AddressesRepository(
      addressesDataProvider: AddressesDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() => _loadingSaved = true);
    try {
      final result = await _repository.getAddresses(page: 1);
      if (mounted) {
        setState(() {
          _saved = result.addresses;
          _loadingSaved = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _apply({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    if (latitude != null && longitude != null) {
      await SavedLocationService.saveLocationData(
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
    } else {
      await SavedLocationService.saveAddress(address);
    }
    widget.onAddressChanged(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.deliveryAddressSelectPrompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (_loadingSaved)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ..._saved.map(
                      (a) => ListTile(
                        leading: Icon(
                          a.isDefault ? Icons.star : Icons.location_on_outlined,
                          color:
                              a.isDefault ? AppColors.primaryColor : null,
                        ),
                        title: Text(a.title),
                        subtitle: Text(
                          a.displayText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await _apply(
                            address: a.displayText,
                            latitude: a.latitude,
                            longitude: a.longitude,
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: Text(l10n.deliveryAddressPickMap),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressMapPickerScreen(),
                        ),
                      );
                      if (result == null) return;
                      final addr = [
                        result['address_line_1'],
                        result['city'],
                        result['country'],
                      ]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(', ');
                      await _apply(
                        address: addr.isNotEmpty ? addr : widget.currentAddress,
                        latitude: (result['latitude'] as num?)?.toDouble(),
                        longitude: (result['longitude'] as num?)?.toDouble(),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(l10n.locationSearchScreenTitle),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationSearchScreen(
                            currentLocation: widget.currentAddress,
                          ),
                        ),
                      );
                      if (result == null) return;
                      final coords = result['coordinates'] as LatLng?;
                      await _apply(
                        address:
                            result['address'] as String? ?? widget.currentAddress,
                        latitude: coords?.latitude,
                        longitude: coords?.longitude,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_location_alt_outlined),
                    title: Text(l10n.deliveryAddressAddNew),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressesListScreen(),
                        ),
                      );
                      try {
                        final def = await _repository.getDefaultAddress();
                        if (def != null && context.mounted) {
                          await _apply(
                            address: def.displayText,
                            latitude: def.latitude,
                            longitude: def.longitude,
                          );
                        }
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tap-to-change delivery address with saved addresses, map, and add-new flows.
class DeliveryAddressSelector extends StatelessWidget {
  final String address;
  final double? latitude;
  final double? longitude;
  final DeliveryAddressCallback onAddressChanged;
  final bool compact;

  const DeliveryAddressSelector({
    super.key,
    required this.address,
    this.latitude,
    this.longitude,
    required this.onAddressChanged,
    this.compact = false,
  });

  void _openSheet(BuildContext context) {
    showDeliveryAddressPicker(
      context: context,
      currentAddress: address,
      onAddressChanged: onAddressChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (compact) {
      return InkWell(
        onTap: () => _openSheet(context),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              l10n.deliveryAddressChange,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.deliveryAddressTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openSheet(context),
                  child: Text(l10n.deliveryAddressChange),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              address,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
