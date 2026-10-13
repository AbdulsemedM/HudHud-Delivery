import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/call_support_button.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/models/create_delivery_result.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/package_item_catalog.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_vehicle_display.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_payment_helper.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_balance_model.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'package:hudhud_delivery/features/wallet/presentation/screens/add_funds_screen.dart';
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
  final String senderPhone;
  final String recipientName;
  final String recipientPhone;
  final String? packageImagePath;
  final Map<String, dynamic>? paymentDetails;

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
    required this.senderPhone,
    required this.recipientName,
    required this.recipientPhone,
    this.packageImagePath,
    this.paymentDetails,
  });

  @override
  State<ConfirmDetailsScreen> createState() => _ConfirmDetailsScreenState();
}

class _ConfirmDetailsScreenState extends State<ConfirmDetailsScreen> {
  late final CourierRepository _courierRepository;
  late final PaymentRepository _paymentRepository;
  late final WalletRepository _walletRepository;
  late String _selectedVehicle;
  List<String> _supportedVehicleTypes = const [];
  gmaps.GoogleMapController? _mapController;

  bool _isLoadingEstimate = true;
  bool _isLoadingRequest = false;
  WalletBalance? _walletBalance;
  double? _estimatedCost;
  String _estimatedCurrency = 'ETB';
  String? _estimateError;

  /// Exact `scheduled_pickup` string used for the last successful quote.
  String? _quotedScheduledPickup;
  List<LatLng>? _routePolylinePoints;
  bool? _hasGoogleMapsApiKey;

  static const _initialSheetSize = 0.38;
  static const _minSheetSize = 0.28;
  double _sheetExtent = _initialSheetSize;

  /// Fixed footer: estimated fee + Look for Courier (always visible above home indicator).
  static const double _footerContentHeight = 12 + 36 + 12 + 56 + 12;

  /// After create succeeds, keep delivery so pay can retry without re-creating.
  CreateDeliveryResult? _pendingCreatedDelivery;

  /// Reused only for safe retries of the same logical payment attempt.
  String? _paymentIdempotencyKey;

  late String _paymentType;
  Map<String, dynamic> _paymentDetails = {};

  @override
  void initState() {
    super.initState();
    _selectedVehicle = mapCourierVehicleType(widget.selectedVehicle);
    _paymentType = isOfflineDeliveryPayment(widget.paymentType) ||
            widget.paymentType.isEmpty
        ? 'cash_on_delivery'
        : widget.paymentType;
    _paymentDetails = Map<String, dynamic>.from(widget.paymentDetails ?? {});
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _walletRepository = WalletRepository(
      walletDataProvider: WalletDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _fetchEstimate();
    _loadMapsAvailability();
    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      _fetchRouteDirections();
    }
  }

  Future<void> _loadMapsAvailability() async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (!mounted) return;
    setState(() {
      _hasGoogleMapsApiKey = key.trim().isNotEmpty;
    });
  }

  Future<void> _fetchRouteDirections() async {
    if (widget.pickupPosition == null || widget.deliveryPosition == null) {
      return;
    }
    final result = await GoogleDirectionsService.getDirections(
      originLat: widget.pickupPosition!.latitude,
      originLng: widget.pickupPosition!.longitude,
      destLat: widget.deliveryPosition!.latitude,
      destLng: widget.deliveryPosition!.longitude,
    );
    if (!mounted) return;
    setState(() {
      _routePolylinePoints = result?.polylinePoints;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitBounds();
    });
  }

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  void _fitBounds() {
    if (widget.pickupPosition == null || widget.deliveryPosition == null) {
      return;
    }
    final pickup = widget.pickupPosition!;
    final delivery = widget.deliveryPosition!;

    // Identical points crash LatLngBounds — zoom to a single point instead.
    if ((pickup.latitude - delivery.latitude).abs() < 1e-6 &&
        (pickup.longitude - delivery.longitude).abs() < 1e-6) {
      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(_toG(pickup), 15),
      );
      return;
    }

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        pickup.latitude < delivery.latitude
            ? pickup.latitude
            : delivery.latitude,
        pickup.longitude < delivery.longitude
            ? pickup.longitude
            : delivery.longitude,
      ),
      northeast: gmaps.LatLng(
        pickup.latitude > delivery.latitude
            ? pickup.latitude
            : delivery.latitude,
        pickup.longitude > delivery.longitude
            ? pickup.longitude
            : delivery.longitude,
      ),
    );
    // Extra padding so both pins stay above the bottom sheet.
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 72),
    );
  }

  bool get _hasServerEstimate =>
      !_isLoadingEstimate &&
      _estimateError == null &&
      _estimatedCost != null &&
      (widget.scheduledPickup == null || _quotedScheduledPickup != null);

  bool get _isWalletPayment => _paymentType == 'wallet';

  Future<void> _fetchWalletBalance() async {
    try {
      final balance = await _walletRepository.getBalance();
      if (!mounted) return;
      setState(() {
        _walletBalance = balance;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletBalance = null;
      });
    }
  }

  double _topUpAmountForError(ApiErrorResult error) {
    if (error.deficit != null && error.deficit! > 0) return error.deficit!;
    final required = error.requiredAmount ?? 0;
    final balance = error.balance ?? 0;
    final computed = required - balance;
    return computed > 0 ? computed : required;
  }

  Future<void> _showInsufficientBalanceDialog(ApiErrorResult error) async {
    final topUpAmount = _topUpAmountForError(error);
    final currency = _walletBalance?.currency ?? _estimatedCurrency;
    final formattedTopUp = topUpAmount == topUpAmount.roundToDouble()
        ? topUpAmount.toStringAsFixed(0)
        : topUpAmount.toStringAsFixed(2);

    final shouldTopUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.insufficientWalletBalance),
          content: Text(error.displayMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.topUpAmount(currency, formattedTopUp)),
            ),
          ],
        );
      },
    );

    if (shouldTopUp != true || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFundsScreen(initialAmount: topUpAmount),
      ),
    );
    if (mounted && _isWalletPayment) {
      await _fetchWalletBalance();
    }
  }

  Widget _buildFindingCourierScreen(CreateDeliveryResult created) {
    return FindingCourierScreen(
      deliveryId: created.deliveryId,
      pickupLocation: widget.pickupLocation,
      deliveryLocation: widget.deliveryLocation,
      pickupPosition: widget.pickupPosition,
      deliveryPosition: widget.deliveryPosition,
      selectedVehicle: _selectedVehicle,
      itemType: widget.itemType,
      quantity: widget.quantity,
      whoPays: widget.whoPays,
      paymentType: _paymentType,
      recipientName: widget.recipientName,
      recipientPhone: widget.recipientPhone,
      packageImagePath: widget.packageImagePath,
      routePolylinePoints: _routePolylinePoints,
    );
  }

  void _navigateToFindingCourier(CreateDeliveryResult created) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _buildFindingCourierScreen(created)),
      (route) => route.isFirst,
    );
  }

  String _mapPackageType(String itemType) {
    const mapping = {
      'Documents': 'document',
      'Electronics/Gadgets': 'electronics',
      'Food': 'food',
      'Clothing': 'clothing',
      'Books': 'books',
      'Fragile': 'fragile',
      'Other': 'other',
    };
    return mapping[itemType] ?? 'other';
  }

  String _mapPaymentMethod(String paymentType) {
    if (paymentType.isEmpty) return 'cash_on_delivery';
    return paymentType;
  }

  /// Formats DateTime for API as Africa/Addis_Ababa with fixed +03:00.
  String? _formatScheduledDateTime(DateTime? dt) {
    if (dt == null) return null;
    return formatDeliveryScheduledPickup(dt);
  }

  Future<void> _fetchEstimate() async {
    if (widget.pickupPosition == null || widget.deliveryPosition == null) {
      setState(() {
        _isLoadingEstimate = false;
        _estimateError = 'Location coordinates required for estimate';
        _quotedScheduledPickup = null;
      });
      return;
    }

    setState(() {
      _isLoadingEstimate = true;
      _estimateError = null;
    });

    final scheduledPickup = _formatScheduledDateTime(widget.scheduledPickup);

    final result = await _courierRepository.estimateDelivery(
      packageType: _mapPackageType(widget.itemType),
      packageWeight: widget.packageWeight,
      pickupLatitude: widget.pickupPosition!.latitude,
      pickupLongitude: widget.pickupPosition!.longitude,
      dropoffLatitude: widget.deliveryPosition!.latitude,
      dropoffLongitude: widget.deliveryPosition!.longitude,
      vehicleType: mapCourierVehicleType(_selectedVehicle),
      serviceType:
          deliveryServiceType(isInstantDelivery: widget.isInstantDelivery),
      pickupLocation: widget.pickupLocation,
      scheduledPickup: scheduledPickup,
    );

    if (mounted) {
      setState(() {
        _isLoadingEstimate = false;
        if (result['success'] == true) {
          _estimatedCost = result['estimatedCost'] as double?;
          _estimatedCurrency = result['currency'] as String? ?? 'ETB';
          _quotedScheduledPickup = scheduledPickup != null
              ? (result['scheduledPickup'] as String? ?? scheduledPickup)
              : null;
          _estimateError =
              _estimatedCost == null ? 'Estimate did not include a cost' : null;
          if (_estimateError != null) {
            _quotedScheduledPickup = null;
          }
        } else {
          final error = result['error'] as ApiErrorResult?;
          if (error?.hasScheduledPickupValidation == true) {
            _estimateError = context.l10n.chooseValidFuturePickup;
          } else if (error?.isPickupServiceAreaUnavailable == true) {
            _estimateError = context.l10n.pickupOutsideDeliveryServiceArea;
          } else if (error?.isCityVehicleNotSupported == true) {
            _estimateError = result['message'] as String?;
          } else if (error?.isRouteDistanceError == true) {
            _estimateError = context.l10n.refreshQuoteRouteDistance;
          } else {
            _estimateError = result['message'] as String?;
          }
          _estimatedCost = null;
          _quotedScheduledPickup = null;
        }
      });
      if ((result['error'] as ApiErrorResult?)
              ?.isPickupServiceAreaUnavailable ==
          true) {
        await _handlePickupServiceAreaUnavailable();
      } else if ((result['error'] as ApiErrorResult?)
              ?.isCityVehicleNotSupported ==
          true) {
        await _handleCityVehicleNotSupported();
      }
    }
  }

  Future<void> _handlePickupServiceAreaUnavailable() async {
    if (!mounted) return;
    setState(() {
      _supportedVehicleTypes = const [];
      _estimateError = context.l10n.pickupOutsideDeliveryServiceArea;
      _estimatedCost = null;
      _quotedScheduledPickup = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.pickupOutsideDeliveryServiceArea),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  Future<void> _handleCityVehicleNotSupported() async {
    final result = await _courierRepository.getDeliveryServiceAreas(
      pickupLocation: widget.pickupLocation,
    );
    if (!mounted) return;

    final rawTypes = result['success'] == true
        ? List<String>.from(
            result['supportedVehicleTypes'] as List? ?? const [])
        : const <String>[];
    final applied = applyCourierSupportedVehicleTypes(
      supportedVehicleTypes: rawTypes,
      selectedVehicleType: _selectedVehicle,
    );
    setState(() {
      _supportedVehicleTypes = applied.types;
      if (applied.selected != null) {
        _selectedVehicle = applied.selected!;
      }
    });

    if (applied.types.isEmpty) {
      setState(() {
        _estimateError = context.l10n.pickupOutsideDeliveryServiceArea;
        _estimatedCost = null;
        _quotedScheduledPickup = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pickupOutsideDeliveryServiceArea),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
      return;
    }

    await _promptSupportedVehicleSelection();
    if (mounted) await _fetchEstimate();
  }

  Future<void> _promptSupportedVehicleSelection() async {
    if (_supportedVehicleTypes.isEmpty) return;
    final l10n = context.l10n;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.selectAvailableVehicleType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final type in _supportedVehicleTypes)
                ListTile(
                  leading: Icon(courierVehicleIcon(type)),
                  title: Text(courierVehicleLabel(type, l10n)),
                  selected: type == _selectedVehicle,
                  onTap: () => Navigator.pop(sheetContext, type),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() {
        _selectedVehicle = chosen;
      });
    }
  }

  Future<void> _createDeliveryRequest() async {
    if (!_hasServerEstimate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.waitForPriceEstimate),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoadingRequest = true);

    try {
      var created = _pendingCreatedDelivery;
      if (created == null) {
        final user = await AuthService().getStoredUser();

        final senderPhone = normalizePhoneToBackend(widget.senderPhone);
        if (!RegExp(r'^2519\d{8}$').hasMatch(senderPhone)) {
          if (!mounted) return;
          setState(() => _isLoadingRequest = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.pleaseEnterValidSenderPhone),
              backgroundColor: AppColors.errorColor,
            ),
          );
          return;
        }

        final scheduledPickup = _quotedScheduledPickup ??
            _formatScheduledDateTime(widget.scheduledPickup);
        final scheduledDelivery = widget.scheduledDelivery != null
            ? (scheduledPickup ??
                _formatScheduledDateTime(widget.scheduledDelivery))
            : null;

        final requestData = <String, dynamic>{
          'package_type': _mapPackageType(widget.itemType),
          'package_description': widget.packageDescription.isNotEmpty
              ? widget.packageDescription
              : widget.itemType,
          'package_weight': widget.packageWeight,
          'pickup_location': widget.pickupLocation,
          'pickup_latitude': widget.pickupPosition?.latitude ?? 0,
          'pickup_longitude': widget.pickupPosition?.longitude ?? 0,
          'dropoff_location': widget.deliveryLocation,
          'dropoff_latitude': widget.deliveryPosition?.latitude ?? 0,
          'dropoff_longitude': widget.deliveryPosition?.longitude ?? 0,
          'vehicle_type': mapCourierVehicleType(_selectedVehicle),
          'service_type':
              deliveryServiceType(isInstantDelivery: widget.isInstantDelivery),
          'scheduled_pickup': scheduledPickup,
          'scheduled_delivery': scheduledDelivery,
          'payment_method': _mapPaymentMethod(_paymentType),
          'requires_signature': false,
          'insurance_required': false,
          'special_instructions': '',
          'sender_name': user?.name ?? '',
          'sender_phone': senderPhone,
          'receiver_name': widget.recipientName,
          'receiver_phone': normalizePhoneToBackend(widget.recipientPhone),
          'package_details': {
            'name': widget.itemType,
            'weight': widget.packageWeight,
            'description': widget.packageDescription.isNotEmpty
                ? widget.packageDescription
                : widget.itemType,
          },
          'pickup_address': {
            'latitude': widget.pickupPosition?.latitude ?? 0,
            'longitude': widget.pickupPosition?.longitude ?? 0,
            'address': widget.pickupLocation,
          },
          'delivery_address': {
            'latitude': widget.deliveryPosition?.latitude ?? 0,
            'longitude': widget.deliveryPosition?.longitude ?? 0,
            'address': widget.deliveryLocation,
          },
        };

        final paymentPhone = normalizePaymentPhone(
          _paymentDetails['phone']?.toString(),
          _paymentType,
        );
        if (paymentPhone.isNotEmpty) {
          requestData['payment_phone'] = paymentPhone;
        }

        final result = await _courierRepository.createDeliveryRequest(
          requestData: requestData,
        );

        if (!mounted) return;

        if (result['success'] != true) {
          setState(() => _isLoadingRequest = false);
          final error = result['error'] as ApiErrorResult?;
          if (error?.isInsufficientBalance == true) {
            await _fetchWalletBalance();
            await _showInsufficientBalanceDialog(error!);
            return;
          }
          if (error?.isCityVehicleNotSupported == true) {
            await _handleCityVehicleNotSupported();
            return;
          }
          if (error?.isPickupServiceAreaUnavailable == true) {
            await _handlePickupServiceAreaUnavailable();
            return;
          }
          if (error?.hasScheduledPickupValidation == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.chooseValidFuturePickup),
                backgroundColor: AppColors.errorColor,
              ),
            );
            return;
          }
          if (error?.isRouteDistanceError == true) {
            setState(() {
              _estimatedCost = null;
              _quotedScheduledPickup = null;
              _estimateError = context.l10n.refreshQuoteRouteDistance;
              _pendingCreatedDelivery = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.refreshQuoteRouteDistance),
                backgroundColor: AppColors.errorColor,
              ),
            );
            await _fetchEstimate();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ??
                  'Failed to create delivery request'),
              backgroundColor: AppColors.errorColor,
            ),
          );
          return;
        }

        created = result['created'] as CreateDeliveryResult? ??
            parseCreateDeliveryResponse(result['data']);

        if (!created.isValid) {
          setState(() => _isLoadingRequest = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.invalidDeliveryId),
              backgroundColor: AppColors.errorColor,
            ),
          );
          return;
        }

        _pendingCreatedDelivery = created;
        CourierHomeRefresh.instance.notifyRefresh();
      }

      final delivery = created;
      final amount = resolveServerDeliveryPaymentAmount(delivery);
      if (amount == null) {
        if (!mounted) return;
        setState(() => _isLoadingRequest = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Server did not return a payment total. Refresh and try again.',
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      // Keep summary UI aligned with the persisted server total.
      if (_estimatedCost != amount) {
        setState(() {
          _estimatedCost = amount;
          if (delivery.currency != null && delivery.currency!.isNotEmpty) {
            _estimatedCurrency = delivery.currency!;
          }
        });
      }

      final currency = delivery.currency ?? _estimatedCurrency;

      if (_isWalletPayment) {
        if (!mounted) return;
        setState(() => _isLoadingRequest = false);
        try {
          final balance = await _walletRepository.getBalance();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.deliveryBookedWalletBalance(
                    balance.currency,
                    balance.balance.toStringAsFixed(2),
                  ),
                ),
              ),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.deliveryBookedWallet),
              ),
            );
          }
        }
        if (!mounted) return;
        _pendingCreatedDelivery = null;
        _paymentIdempotencyKey = null;
        _navigateToFindingCourier(delivery);
        return;
      }

      if (isOfflineDeliveryPayment(_paymentType)) {
        if (!mounted) return;
        setState(() => _isLoadingRequest = false);
        _pendingCreatedDelivery = null;
        _paymentIdempotencyKey = null;
        _navigateToFindingCourier(delivery);
        return;
      }

      _paymentIdempotencyKey ??= createPaymentIdempotencyKey(
        type: 'delivery',
        entityId: delivery.deliveryId,
      );

      final paymentResult = await initiateDeliveryPayment(
        repo: _paymentRepository,
        packageDeliveryId: delivery.deliveryId,
        paymentMethodCode: _paymentType,
        amount: amount,
        currency: currency,
        paymentDetails: _paymentDetails,
        idempotencyKey: _paymentIdempotencyKey,
      );

      if (!mounted) return;
      setState(() => _isLoadingRequest = false);

      // Clear attempt state only after a successful initiate (incl. replay).
      _paymentIdempotencyKey = null;
      _pendingCreatedDelivery = null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentInitiateResultScreen(
            result: paymentResult,
            orderId: delivery.deliveryId.toString(),
            trackingNumber: delivery.trackingNumber ?? '',
            successActionLabel: 'Find courier',
            onTerminalSuccess: (resultContext) {
              Navigator.of(resultContext).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => _buildFindingCourierScreen(delivery),
                ),
                (route) => route.isFirst,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRequest = false);
      await _handlePaymentInitiateFailure(e);
    }
  }

  Future<void> _handlePaymentInitiateFailure(Object error) async {
    final parsed = error is ApiException
        ? parseApiErrorResult(
            error.data,
            statusCode: error.statusCode,
            fallback: error.message,
          )
        : null;

    if (parsed?.isAmountMismatch == true) {
      // New attempt after amount change — do not reuse the old key.
      _paymentIdempotencyKey = null;
      await _refreshDeliveryAmountAfterMismatch(
        expectedAmount: parsed!.expectedAmount,
        currency: _pendingCreatedDelivery?.currency ?? _estimatedCurrency,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parsed.displayMessage.isNotEmpty
                ? parsed.displayMessage
                : 'Payment amount changed. Review the updated total and try again.',
          ),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    if (isTransientPaymentNetworkError(error)) {
      // Keep `_paymentIdempotencyKey` so a safe retry reuses the same key.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${userFacingApiError(error)} Tap pay again to retry safely.',
          ),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    // Definitive failure — next press starts a new payment attempt.
    _paymentIdempotencyKey = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userFacingApiError(error)),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  Future<void> _refreshDeliveryAmountAfterMismatch({
    double? expectedAmount,
    required String currency,
  }) async {
    final pending = _pendingCreatedDelivery;
    if (pending == null) {
      if (expectedAmount != null && expectedAmount > 0) {
        setState(() {
          _estimatedCost = expectedAmount;
          _estimatedCurrency = currency;
        });
      }
      return;
    }

    double? refreshedAmount = expectedAmount;
    String refreshedCurrency = currency;

    final details = await _courierRepository.getUserDeliveryDetails(
      pending.deliveryId,
    );
    if (details['success'] == true && details['data'] is Map) {
      final data = Map<String, dynamic>.from(details['data'] as Map);
      final fromDetails = _firstPositiveDouble([
        data['total_amount'],
        data['estimated_cost'],
        data['amount'],
        data['total'],
      ]);
      if (fromDetails != null) refreshedAmount = fromDetails;
      final c = data['currency']?.toString();
      if (c != null && c.isNotEmpty) refreshedCurrency = c;
    }

    if (refreshedAmount == null || refreshedAmount <= 0) return;

    if (!mounted) return;
    setState(() {
      _estimatedCost = refreshedAmount;
      _estimatedCurrency = refreshedCurrency;
      _pendingCreatedDelivery = CreateDeliveryResult(
        deliveryId: pending.deliveryId,
        totalAmount: refreshedAmount,
        currency: refreshedCurrency,
        trackingNumber: pending.trackingNumber,
        status: pending.status,
        dispatch: pending.dispatch,
        raw: pending.raw,
      );
    });
  }

  double? _firstPositiveDouble(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c == null) continue;
      final value = c is num ? c.toDouble() : double.tryParse(c.toString());
      if (value != null && value > 0) return value;
    }
    return null;
  }

  bool _onSheetNotification(DraggableScrollableNotification notification) {
    final extent = notification.extent;
    if ((extent - _sheetExtent).abs() > 0.001) {
      setState(() => _sheetExtent = extent);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          LatLng mapCenter = const LatLng(9.0222, 38.7468);
          if (widget.pickupPosition != null &&
              widget.deliveryPosition != null) {
            mapCenter = LatLng(
              (widget.pickupPosition!.latitude +
                      widget.deliveryPosition!.latitude) /
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

          String? estimatedFeeText;
          if (!_isLoadingEstimate) {
            if (_estimateError != null) {
              estimatedFeeText = 'N/A';
            } else if (_estimatedCost != null) {
              estimatedFeeText =
                  '$_estimatedCurrency ${_estimatedCost!.toStringAsFixed(2)}';
            }
          }

          final itemLabel = PackageItemCatalog.allIds.contains(widget.itemType)
              ? PackageItemCatalog.labelFor(widget.itemType, l10n)
              : widget.itemType;
          final paymentLabel = _isWalletPayment
              ? l10n.paymentWallet
              : l10n.paymentCashOnDelivery;
          final scheduledAt = widget.scheduledPickup;
          final materialL10n = MaterialLocalizations.of(context);
          final scheduledText = scheduledAt == null
              ? null
              : '${materialL10n.formatMediumDate(scheduledAt)} · '
                  '${materialL10n.formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt))}';
          final topPad = MediaQuery.paddingOf(context).top;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            // Map is always light: keep status bar icons dark.
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: HomeColors.backgroundOf(context),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.paddingOf(context).bottom;
                  final footerHeight = _footerContentHeight + bottomInset;
                  final sheetAreaHeight = constraints.maxHeight - footerHeight;
                  final mapBottomPadding =
                      footerHeight + sheetAreaHeight * _sheetExtent;
                  return NotificationListener<DraggableScrollableNotification>(
                    onNotification: _onSheetNotification,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _buildMapOrFallback(
                            mapCenter,
                            bottomPadding: mapBottomPadding,
                          ),
                        ),
                        Positioned(
                          top: topPad + 8,
                          left: 16,
                          child: Row(
                            children: [
                              _MapCircle(
                                child: IconButton(
                                  tooltip: MaterialLocalizations.of(context)
                                      .backButtonTooltip,
                                  iconSize: 26,
                                  constraints: const BoxConstraints(
                                    minWidth: 52,
                                    minHeight: 52,
                                  ),
                                  icon: Icon(
                                    Icons.arrow_back_rounded,
                                    color: HomeColors.textPrimaryOf(context),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const _MapCircle(
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Center(
                                    child: CallSupportButton(compact: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: topPad + 8,
                          right: 16,
                          child: _MapCircle(
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: Icon(
                                courierVehicleIcon(_selectedVehicle),
                                color: HomeColors.violetOf(context),
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: footerHeight,
                          child: DraggableScrollableSheet(
                            initialChildSize: _initialSheetSize,
                            minChildSize: _minSheetSize,
                            maxChildSize: 0.85,
                            builder: (context, scrollController) {
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: HomeColors.backgroundOf(context),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x261B1530),
                                      blurRadius: 24,
                                      offset: Offset(0, -6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      width: 44,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: HomeColors.textMutedOf(context)
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        12,
                                        0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Confirm Details',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.5,
                                                color: HomeColors.textPrimaryOf(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _EditPill(
                                            onTap: () => Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: scrollController,
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          14,
                                          16,
                                          20,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (_estimateError != null &&
                                                !_isLoadingEstimate) ...[
                                              _ErrorNote(text: _estimateError!),
                                              const SizedBox(height: 12),
                                            ],
                                            _DetailCard(
                                              child: _RouteSummary(
                                                pickupLabel:
                                                    l10n.pickupLocationLabel,
                                                pickup: widget.pickupLocation,
                                                dropoffLabel:
                                                    l10n.deliveryLocationLabel,
                                                dropoff:
                                                    widget.deliveryLocation,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            _DetailCard(
                                              child: Column(
                                                children: [
                                                  _DetailRow(
                                                    icon: PackageItemCatalog
                                                        .iconFor(
                                                            widget.itemType),
                                                    label:
                                                        'What you are sending',
                                                    value: itemLabel,
                                                  ),
                                                  const _Hairline(),
                                                  _DetailRow(
                                                    icon: Icons.scale_rounded,
                                                    label: l10n.labelWeight,
                                                    value:
                                                        '${widget.quantity} × ${_formatWeight(widget.packageWeight)} kg',
                                                  ),
                                                  const _Hairline(),
                                                  _DetailRow(
                                                    icon: courierVehicleIcon(
                                                      _selectedVehicle,
                                                    ),
                                                    label: l10n.vehicleType,
                                                    value: courierVehicleLabel(
                                                      _selectedVehicle,
                                                      l10n,
                                                    ),
                                                  ),
                                                  if (scheduledText !=
                                                      null) ...[
                                                    const _Hairline(),
                                                    _DetailRow(
                                                      icon: Icons.event_rounded,
                                                      label: l10n
                                                          .labelScheduledPickup,
                                                      value: scheduledText,
                                                    ),
                                                  ],
                                                  const _Hairline(),
                                                  _DetailRow(
                                                    icon: Icons.phone_rounded,
                                                    label: 'Sender phone',
                                                    value:
                                                        formatPhoneForDisplay(
                                                      widget.senderPhone,
                                                    ),
                                                  ),
                                                  const _Hairline(),
                                                  _DetailRow(
                                                    icon: Icons.person_rounded,
                                                    label: 'Recipient',
                                                    value: widget.recipientName,
                                                  ),
                                                  const _Hairline(),
                                                  _DetailRow(
                                                    icon: Icons
                                                        .phone_in_talk_rounded,
                                                    label:
                                                        'Recipient contact number',
                                                    value:
                                                        widget.recipientPhone,
                                                  ),
                                                  const _Hairline(),
                                                  _DetailRow(
                                                    icon: _isWalletPayment
                                                        ? Icons
                                                            .account_balance_wallet_rounded
                                                        : Icons
                                                            .payments_rounded,
                                                    label:
                                                        l10n.labelPaymentMethod,
                                                    value: paymentLabel,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _ConfirmDetailsFooter(
                            bottomInset: bottomInset,
                            isLoadingRequest: _isLoadingRequest,
                            hasServerEstimate: _hasServerEstimate,
                            isLoadingEstimate: _isLoadingEstimate,
                            feeText: estimatedFeeText,
                            onLookForCourier: _createDeliveryRequest,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatWeight(double kg) {
    if (kg == kg.roundToDouble()) return kg.toStringAsFixed(0);
    return kg.toStringAsFixed(1);
  }

  Widget _buildMapOrFallback(
    LatLng mapCenter, {
    double bottomPadding = 0,
  }) {
    if (_hasGoogleMapsApiKey == null) {
      return ColoredBox(
        color: HomeColors.backgroundOf(context),
        child: const Center(
          child: CircularProgressIndicator(color: HomeColors.orange),
        ),
      );
    }
    if (_hasGoogleMapsApiKey == false) {
      return ColoredBox(
        color: HomeColors.backgroundOf(context),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.taxiGoogleMapsNotConfigured,
              textAlign: TextAlign.center,
              style: TextStyle(color: HomeColors.textPrimaryOf(context)),
            ),
          ),
        ),
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _toG(mapCenter),
        zoom: 13.0,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: {
        if (widget.pickupPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('pickup'),
            position: _toG(widget.pickupPosition!),
            infoWindow: gmaps.InfoWindow(
              title: 'Pickup',
              snippet: widget.pickupLocation,
            ),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              22.0,
            ),
          ),
        if (widget.deliveryPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('delivery'),
            position: _toG(widget.deliveryPosition!),
            infoWindow: gmaps.InfoWindow(
              title: 'Delivery',
              snippet: widget.deliveryLocation,
            ),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              266.0,
            ),
          ),
      },
      polylines:
          widget.pickupPosition != null && widget.deliveryPosition != null
              ? {
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('route'),
                    points: _routePolylinePoints != null &&
                            _routePolylinePoints!.length >= 2
                        ? _routePolylinePoints!.map(_toG).toList()
                        : [
                            _toG(widget.pickupPosition!),
                            _toG(widget.deliveryPosition!),
                          ],
                    color: HomeColors.violetOf(context),
                    width: 4,
                  ),
                }
              : {},
      onMapCreated: (controller) {
        _mapController = controller;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitBounds();
        });
      },
    );
  }
}

/// Round surface wrapper for floating map controls (soft shadow, no clipping
/// artefacts).
class _MapCircle extends StatelessWidget {
  const _MapCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: CircleBorder(
          side: BorderSide(color: HomeColors.borderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Small indigo "Edit Details" pill next to the sheet title.
class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    return Material(
      color: HomeColors.violetTintOf(context),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 18, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Edit Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

/// Fixed footer: estimated total + one full-width orange primary button.
class _ConfirmDetailsFooter extends StatelessWidget {
  const _ConfirmDetailsFooter({
    required this.bottomInset,
    required this.isLoadingRequest,
    required this.hasServerEstimate,
    required this.isLoadingEstimate,
    required this.feeText,
    required this.onLookForCourier,
  });

  final double bottomInset;
  final bool isLoadingRequest;
  final bool hasServerEstimate;
  final bool isLoadingEstimate;
  final String? feeText;
  final VoidCallback onLookForCourier;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        border: Border(
          top: BorderSide(color: HomeColors.borderOf(context)),
        ),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x141B1530),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.orangeTintDark
                          : AppColors.orangeTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      size: 18,
                      color: HomeColors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estimated fee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HomeColors.textMutedOf(context),
                      ),
                    ),
                  ),
                  if (isLoadingEstimate)
                    const _EstimateFeeLoading()
                  else
                    Text(
                      feeText ?? 'N/A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: HomeColors.textPrimaryOf(context),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (isLoadingRequest || !hasServerEstimate)
                    ? null
                    : onLookForCourier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor:
                      HomeColors.surfaceElevatedOf(context),
                  disabledForegroundColor: HomeColors.textMutedOf(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoadingRequest
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: HomeColors.orange,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 22),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Look for Courier',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateFeeLoading extends StatelessWidget {
  const _EstimateFeeLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder;
    final highlightColor =
        isDark ? AppColors.darkBorder : AppColors.lightInputFill;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 110,
        height: 26,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Receipt-style card surface.
class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(22),
        border: HomeColors.isDark(context)
            ? Border.all(color: HomeColors.borderOf(context))
            : null,
        boxShadow: AppColors.softShadow(context),
      ),
      child: child,
    );
  }
}

/// Hairline divider between receipt rows (indented past the icon tile).
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        thickness: 1,
        color: HomeColors.borderOf(context),
      ),
    );
  }
}

/// Pickup → drop-off summary with a dotted connector.
class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.pickupLabel,
    required this.pickup,
    required this.dropoffLabel,
    required this.dropoff,
  });

  final String pickupLabel;
  final String pickup;
  final String dropoffLabel;
  final String dropoff;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          _RouteStop(
            icon: Icons.my_location_rounded,
            color: HomeColors.orange,
            tint: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
            label: pickupLabel,
            value: pickup,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 19),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: HomeColors.textMutedOf(context)
                            .withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _RouteStop(
            icon: Icons.location_on_rounded,
            color: HomeColors.violetOf(context),
            tint: HomeColors.violetTintOf(context),
            label: dropoffLabel,
            value: dropoff,
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.color,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Receipt row: icon tile + muted label on the left, bold value on the right.
class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _DetailRow({
    this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HomeColors.violetTintOf(context),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft error banner: icon tile + text.
class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 22,
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
