import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/models/create_delivery_result.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
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
  gmaps.GoogleMapController? _mapController;

  bool _isLoadingEstimate = true;
  bool _isLoadingRequest = false;
  WalletBalance? _walletBalance;
  bool _isLoadingWalletBalance = false;
  String? _walletBalanceError;
  double? _estimatedCost;
  double? _estimatedDistance;
  int? _estimatedDuration;
  String _estimatedCurrency = 'ETB';
  double? _baseDeliveryFee;
  double? _weightCharge;
  String? _estimateError;
  List<LatLng>? _routePolylinePoints;
  bool? _hasGoogleMapsApiKey;

  /// After create succeeds, keep delivery so pay can retry without re-creating.
  CreateDeliveryResult? _pendingCreatedDelivery;
  /// Reused only for safe retries of the same logical payment attempt.
  String? _paymentIdempotencyKey;

  @override
  void initState() {
    super.initState();
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
    if (widget.paymentType == 'wallet') {
      _fetchWalletBalance();
    }
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
    if (widget.pickupPosition == null || widget.deliveryPosition == null) return;
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
      !_isLoadingEstimate && _estimateError == null && _estimatedCost != null;

  bool get _isWalletPayment => widget.paymentType == 'wallet';

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoadingWalletBalance = true;
      _walletBalanceError = null;
    });
    try {
      final balance = await _walletRepository.getBalance();
      if (!mounted) return;
      setState(() {
        _walletBalance = balance;
        _isLoadingWalletBalance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletBalance = null;
        _isLoadingWalletBalance = false;
        _walletBalanceError = 'Could not load wallet balance';
      });
    }
  }

  String? get _walletBalanceLabel {
    if (!_isWalletPayment) return null;
    if (_isLoadingWalletBalance) return 'Loading balance...';
    if (_walletBalanceError != null) return _walletBalanceError;
    if (_walletBalance != null) {
      return '${_walletBalance!.currency} ${_walletBalance!.balance.toStringAsFixed(2)}';
    }
    return null;
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
          title: const Text('Insufficient wallet balance'),
          content: Text(error.displayMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Top up $currency $formattedTopUp'),
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

  void _navigateToFindingCourier(CreateDeliveryResult created) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FindingCourierScreen(
          deliveryId: created.deliveryId,
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
      serviceType: deliveryServiceType(isInstantDelivery: widget.isInstantDelivery),
    );

    if (mounted) {
      setState(() {
        _isLoadingEstimate = false;
        if (result['success'] == true) {
          _estimatedCost = result['estimatedCost'] as double?;
          _estimatedDistance = result['estimatedDistance'] as double?;
          _estimatedDuration = result['estimatedDuration'] as int?;
          _estimatedCurrency = result['currency'] as String? ?? 'ETB';
          _baseDeliveryFee = result['baseDeliveryFee'] as double?;
          _weightCharge = result['weightCharge'] as double?;
          _estimateError = _estimatedCost == null
              ? 'Estimate did not include a cost'
              : null;
        } else {
          _estimateError = result['message'] as String?;
          _estimatedCost = null;
          _baseDeliveryFee = null;
          _weightCharge = null;
        }
      });
    }
  }

  Future<void> _createDeliveryRequest() async {
    if (!_hasServerEstimate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait for a server price estimate before booking'),
          backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('Please enter a valid sender phone (09xxxxxxxx)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

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
          'vehicle_type': _mapVehicleType(widget.selectedVehicle),
          'service_type':
              deliveryServiceType(isInstantDelivery: widget.isInstantDelivery),
          'scheduled_pickup': _formatScheduledDateTime(widget.scheduledPickup),
          'scheduled_delivery':
              _formatScheduledDateTime(widget.scheduledDelivery),
          'estimated_distance': _estimatedDistance ?? 0,
          'estimated_duration': _estimatedDuration ?? 0,
          'estimated_cost': _estimatedCost ?? 0,
          'payment_method': _mapPaymentMethod(widget.paymentType),
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
          widget.paymentDetails?['phone']?.toString(),
          widget.paymentType,
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
            await _showInsufficientBalanceDialog(error!);
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ??
                  'Failed to create delivery request'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        created = result['created'] as CreateDeliveryResult? ??
            parseCreateDeliveryResponse(result['data']);

        if (!created.isValid) {
          setState(() => _isLoadingRequest = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid delivery id from create delivery'),
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
                  'Delivery booked. Wallet balance: '
                  '${balance.currency} ${balance.balance.toStringAsFixed(2)}',
                ),
              ),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delivery booked with wallet payment'),
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

      _paymentIdempotencyKey ??= createPaymentIdempotencyKey(
        type: 'delivery',
        entityId: delivery.deliveryId,
      );

      final paymentResult = await initiateDeliveryPayment(
        repo: _paymentRepository,
        packageDeliveryId: delivery.deliveryId,
        paymentMethodCode: widget.paymentType,
        amount: amount,
        currency: currency,
        paymentDetails: widget.paymentDetails,
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
              Navigator.of(resultContext).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => FindingCourierScreen(
                    deliveryId: delivery.deliveryId,
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
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Definitive failure — next press starts a new payment attempt.
    _paymentIdempotencyKey = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userFacingApiError(error)),
        backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          LatLng mapCenter = const LatLng(9.0222, 38.7468);
          if (widget.pickupPosition != null && widget.deliveryPosition != null) {
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

          String estimatedFeeText = 'N/A';
          if (_isLoadingEstimate) {
            estimatedFeeText = 'Loading...';
          } else if (_estimateError != null) {
            estimatedFeeText = 'N/A';
          } else if (_estimatedCost != null) {
            estimatedFeeText =
                '$_estimatedCurrency ${_estimatedCost!.toStringAsFixed(2)}';
          }

          final breakdownParts = <String>[];
          if (_baseDeliveryFee != null) {
            breakdownParts.add(
              'Base ${_baseDeliveryFee!.toStringAsFixed(2)}',
            );
          }
          if (_weightCharge != null) {
            breakdownParts.add(
              'Weight ${_weightCharge!.toStringAsFixed(2)}',
            );
          }
          final breakdownText =
              breakdownParts.isEmpty ? null : breakdownParts.join(' · ');

          final theme = Theme.of(context);
          const borderColor = HomeColors.border;
          return Scaffold(
            backgroundColor: HomeColors.background,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final mapBottomPadding = constraints.maxHeight * 0.48;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: _buildMapOrFallback(
                        mapCenter,
                        bottomPadding: mapBottomPadding,
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: HomeColors.surfaceElevated,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: HomeColors.textPrimary),
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
                          color: HomeColors.surfaceElevated,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: HomeColors.violet,
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
                            color: HomeColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(AppColors.radiusLG),
                              topRight: Radius.circular(AppColors.radiusLG),
                            ),
                            border: Border(
                              top: BorderSide(color: borderColor),
                              left: BorderSide(color: borderColor),
                              right: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: HomeColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Confirm Details',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: HomeColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: AppColors.spaceMD),
                                      _DetailCard(
                                        borderColor: borderColor,
                                        child: Column(
                                          children: [
                                            _DetailRow(
                                              icon: Icons.location_on,
                                              iconColor:
                                                  Theme.of(context).colorScheme.error,
                                              label: 'Pickup Location',
                                              value: widget.pickupLocation,
                                            ),
                                            const Divider(height: 24),
                                            _DetailRow(
                                              icon: Icons.location_on,
                                              iconColor: AppColors.delivered,
                                              label: 'Delivery Location',
                                              value: widget.deliveryLocation,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppColors.spaceMD),
                                      _DetailCard(
                                        borderColor: borderColor,
                                        child: Column(
                                          children: [
                                            _DetailRow(
                                              label: 'What you are sending',
                                              value: widget.itemType,
                                            ),
                                            const SizedBox(height: 12),
                                            _DetailRow(
                                              label: 'Sender phone',
                                              value: formatPhoneForDisplay(
                                                widget.senderPhone,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _DetailRow(
                                              label: 'Recipient',
                                              value: widget.recipientName,
                                            ),
                                            const SizedBox(height: 12),
                                            _DetailRow(
                                              label:
                                                  'Recipient contact number',
                                              value: widget.recipientPhone,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppColors.spaceMD),
                                      _DetailCard(
                                        borderColor: borderColor,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _DetailRow(
                                                    label: 'Payment',
                                                    value: widget.paymentType,
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Estimated fee',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color:
                                                            HomeColors.textMuted,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    _isLoadingEstimate
                                                        ? Shimmer.fromColors(
                                                            baseColor: HomeColors
                                                                .surfaceElevated,
                                                            highlightColor:
                                                                HomeColors
                                                                    .surfaceElevated
                                                                    .withValues(
                                                                        alpha:
                                                                            0.6),
                                                            child: Container(
                                                              width: 80,
                                                              height: 24,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    Colors.white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                            ),
                                                          )
                                                        : Text(
                                                            estimatedFeeText,
                                                            style: theme
                                                                .textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                              color: HomeColors
                                                                  .violet,
                                                            ),
                                                          ),
                                                    if (breakdownText != null &&
                                                        !_isLoadingEstimate &&
                                                        _estimateError == null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                top: 4),
                                                        child: Text(
                                                          breakdownText,
                                                          style: theme
                                                              .textTheme.bodySmall
                                                              ?.copyWith(
                                                            color: HomeColors
                                                                .textMuted,
                                                          ),
                                                        ),
                                                      ),
                                                    if (_estimateError != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                top: 4),
                                                        child: Text(
                                                          _estimateError!,
                                                          style: theme
                                                              .textTheme.bodySmall
                                                              ?.copyWith(
                                                            color: AppColors
                                                                .errorColor,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (_isWalletPayment &&
                                                _walletBalanceLabel != null) ...[
                                              const SizedBox(height: 12),
                                              _DetailRow(
                                                label: 'Wallet balance',
                                                value: _walletBalanceLabel!,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppColors.spaceLG),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text(
                                          'Edit Details',
                                          style: TextStyle(
                                            color: HomeColors.violet,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          height: AppColors.spaceMD),
                                      SizedBox(
                                        width: double.infinity,
                                        height: AppColors.buttonHeightMD,
                                        child: ElevatedButton(
                                          onPressed: (_isLoadingRequest ||
                                                  !_hasServerEstimate)
                                              ? null
                                              : _createDeliveryRequest,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                HomeColors.violet,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppColors.radiusLG),
                                            ),
                                          ),
                                          child: _isLoadingRequest
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text(
                                                  'Look for Courier',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600,
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
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapOrFallback(
    LatLng mapCenter, {
    double bottomPadding = 0,
  }) {
    if (_hasGoogleMapsApiKey == null) {
      return const ColoredBox(
        color: HomeColors.background,
        child: Center(
          child: CircularProgressIndicator(color: HomeColors.violet),
        ),
      );
    }
    if (_hasGoogleMapsApiKey == false) {
      return const ColoredBox(
        color: HomeColors.background,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Google Maps is not configured on iOS. Add GOOGLE_MAPS_API_KEY and restart the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: HomeColors.textPrimary),
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
              gmaps.BitmapDescriptor.hueRed,
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
              gmaps.BitmapDescriptor.hueGreen,
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
                    color: HomeColors.violet,
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

class _DetailCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _DetailCard({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: child,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeColors.textMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: HomeColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
