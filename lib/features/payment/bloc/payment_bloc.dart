import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_service.dart';
import '../../../core/utils/payment_idempotency.dart';
import '../../checkout/data/models/create_order_result.dart';
import '../../checkout/data/repository/checkout_repository.dart';
import '../data/repository/payment_repository.dart';
import '../model/payment_initiate_result.dart';
import '../utils/order_payment_issue.dart';
import '../presentation/widgets/payment_details_form.dart';

// Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPaymentEvent extends PaymentEvent {
  final String paymentMethod;
  final double amount;
  final String orderId;
  final Map<String, dynamic>? paymentDetails;

  const ProcessPaymentEvent({
    required this.paymentMethod,
    required this.amount,
    required this.orderId,
    this.paymentDetails,
  });

  @override
  List<Object?> get props => [paymentMethod, amount, orderId, paymentDetails];
}

class GetPaymentMethodsEvent extends PaymentEvent {
  const GetPaymentMethodsEvent();
}

// States
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentSuccess extends PaymentState {
  final String transactionId;
  final String message;

  const PaymentSuccess({
    required this.transactionId,
    required this.message,
  });

  @override
  List<Object?> get props => [transactionId, message];
}

class PaymentInitiated extends PaymentState {
  final PaymentInitiateResult result;
  final String orderId;
  /// True when server delivery fee differs from the checkout quote preview.
  final bool deliveryFeeUpdated;
  final double? finalDeliveryFee;
  final String? currencySymbol;

  /// Phase 6: set when the order is a gift (recipient's name).
  final String? giftRecipientName;

  const PaymentInitiated({
    required this.result,
    required this.orderId,
    this.deliveryFeeUpdated = false,
    this.finalDeliveryFee,
    this.currencySymbol,
    this.giftRecipientName,
  });

  bool get isGift => giftRecipientName != null;

  @override
  List<Object?> get props => [
        result,
        orderId,
        deliveryFeeUpdated,
        finalDeliveryFee,
        currencySymbol,
        giftRecipientName,
      ];
}

/// The order exists but the server refused this payment attempt for a
/// reason that needs the order screen (already paid, payment in progress,
/// totals / currency changed, no longer payable). The cart is spent.
class PaymentOrderNeedsAttention extends PaymentState {
  final OrderPaymentIssue issue;
  final String orderId;

  /// Server text, for logs / fallback only (UI uses localized copy).
  final String message;

  const PaymentOrderNeedsAttention({
    required this.issue,
    required this.orderId,
    required this.message,
  });

  @override
  List<Object?> get props => [issue, orderId, message];
}

class PaymentFailure extends PaymentState {
  final String error;

  /// API error code when known (e.g. FEATURE_DISABLED for gift orders,
  /// STORE_CLOSED, ITEM_SOLD_OUT, OUTSTANDING_DUES, CITY_*).
  final String? code;

  /// HTTP status of the refused order call (null for transport errors).
  final int? statusCode;

  /// Error body of the refused order call (store_status, amount, currency,
  /// product_id, market, …) for checkout to explain the refusal.
  final Map<String, dynamic>? details;

  const PaymentFailure({
    required this.error,
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  List<Object?> get props => [error, code, statusCode, details];
}

class PaymentMethodsLoaded extends PaymentState {
  final List<Map<String, dynamic>> paymentMethods;

  const PaymentMethodsLoaded({required this.paymentMethods});

  @override
  List<Object?> get props => [paymentMethods];
}

// Bloc
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository paymentRepository;
  final CheckoutRepository checkoutRepository;

  /// Reused across retries of the same checkout action until order is created.
  String? _orderIdempotencyKey;

  PaymentBloc({
    required this.paymentRepository,
    required this.checkoutRepository,
  }) : super(const PaymentInitial()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<GetPaymentMethodsEvent>(_onGetPaymentMethods);
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final orderDetails =
          event.paymentDetails?['order_details'] as Map<String, dynamic>?;
      if (orderDetails == null) {
        emit(const PaymentFailure(error: 'Order details missing'));
        return;
      }

      _orderIdempotencyKey ??= createOrderIdempotencyKey();

      final quotedDeliveryFee =
          (orderDetails['quoted_delivery_fee'] as num?)?.toDouble();
      final branchId = orderDetails['branch_id'] is int
          ? orderDetails['branch_id'] as int
          : int.tryParse(orderDetails['branch_id']?.toString() ?? '');

      // Phase 6: a gift goes to POST /customer/gift-orders (no points,
      // never cash on delivery); payment is then initiated as usual.
      final gift = orderDetails['gift'] is Map
          ? Map<String, dynamic>.from(orderDetails['gift'] as Map)
          : null;
      final giftRecipientName = gift?['recipient_name']?.toString();

      final orderResult = gift != null
          ? await checkoutRepository.createGiftOrder(
              vendorId: orderDetails['vendor_id'] as int,
              items: List<Map<String, dynamic>>.from(
                orderDetails['items'] as List,
              ),
              deliveryAddress: orderDetails['delivery_address'] as String,
              deliveryLocation: (orderDetails['delivery_location'] ??
                  orderDetails['delivery_address']) as String,
              deliveryLatitude:
                  (orderDetails['delivery_latitude'] as num?)?.toDouble() ??
                      0.0,
              deliveryLongitude:
                  (orderDetails['delivery_longitude'] as num?)?.toDouble() ??
                      0.0,
              paymentMethod: event.paymentMethod,
              recipientName: giftRecipientName ?? '',
              recipientPhone: gift['recipient_phone']?.toString() ?? '',
              giftMessage: gift['gift_message']?.toString(),
              serviceType:
                  orderDetails['service_type'] as String? ?? 'restaurant',
              notes: orderDetails['notes'] as String?,
              couponCode: orderDetails['coupon_code'] as String?,
              branchId: branchId,
              idempotencyKey: _orderIdempotencyKey,
            )
          : await checkoutRepository.createOrder(
        vendorId: orderDetails['vendor_id'] as int,
        items: List<Map<String, dynamic>>.from(orderDetails['items'] as List),
        taxAmount: (orderDetails['tax_amount'] ?? 0.0) as double,
        discountAmount: (orderDetails['discount_amount'] ??
            orderDetails['discount'] ??
            0.0) as double,
        deliveryAddress: orderDetails['delivery_address'] as String,
        deliveryLocation:
            (orderDetails['delivery_location'] ?? orderDetails['delivery_address'])
                as String,
        deliveryLatitude:
            (orderDetails['delivery_latitude'] as num?)?.toDouble() ?? 0.0,
        deliveryLongitude:
            (orderDetails['delivery_longitude'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: event.paymentMethod,
        serviceType: orderDetails['service_type'] as String? ?? 'restaurant',
        notes: orderDetails['notes'] as String?,
        couponCode: orderDetails['coupon_code'] as String? ??
            orderDetails['couponCode'] as String?,
        pickupLocation: orderDetails['pickup_location'] as String?,
        pickupLatitude:
            (orderDetails['pickup_latitude'] as num?)?.toDouble(),
        pickupLongitude:
            (orderDetails['pickup_longitude'] as num?)?.toDouble(),
        branchId: branchId,
        idempotencyKey: _orderIdempotencyKey,
        redeemPoints: _parseRedeemPoints(orderDetails['redeem_points']),
      );

      if (orderResult['success'] != true) {
        final details = orderResult['errorData'];
        final status = orderResult['statusCode'];
        emit(PaymentFailure(
          error: orderResult['message'] ?? 'Failed to create order',
          code: orderResult['code']?.toString(),
          statusCode: status is int ? status : null,
          details:
              details is Map ? Map<String, dynamic>.from(details) : null,
        ));
        return;
      }

      // Order exists — mint a new key only on a future distinct checkout.
      _orderIdempotencyKey = null;

      final fallbackId = int.tryParse(event.orderId) ?? 0;
      final created = parseCreateOrderResponse(
        orderResult['data'],
        fallbackOrderId: fallbackId,
      );

      if (!created.isValid) {
        emit(const PaymentFailure(error: 'Invalid order id from create order'));
        return;
      }

      final currency = created.currency ?? 'ETB';
      final amount = created.totalAmount ?? event.amount;
      final deliveryFeeUpdated = quotedDeliveryFee != null &&
          created.deliveryFee != null &&
          (quotedDeliveryFee - created.deliveryFee!).abs() > 0.009;

      final collectedDetails = Map<String, dynamic>.from(
        (event.paymentDetails ?? {})..remove('order_details'),
      );
      final initiateDetails = buildInitiatePaymentDetails(
        paymentMethodCode: event.paymentMethod,
        collectedDetails: collectedDetails,
        orderId: created.orderId,
      );

      try {
        final raw = await paymentRepository.initiatePayment(
          paymentMethodCode: event.paymentMethod,
          type: 'order',
          orderId: created.orderId,
          amount: amount,
          currency: currency,
          paymentDetails: initiateDetails,
          idempotencyKey: createPaymentIdempotencyKey(
            type: 'order',
            entityId: created.orderId,
          ),
        );

        final result = PaymentInitiateResult.fromJson(raw);
        if (!result.isSuccess) {
          emit(PaymentFailure(
            error:
                '${result.message ?? 'Payment initiation failed'} (order #${created.orderId} was created)',
          ));
          return;
        }

        emit(PaymentInitiated(
          result: result,
          orderId: created.orderId.toString(),
          deliveryFeeUpdated: deliveryFeeUpdated,
          finalDeliveryFee: created.deliveryFee,
          giftRecipientName: gift == null
              ? null
              : (giftRecipientName?.trim().isNotEmpty == true
                  ? giftRecipientName!.trim()
                  : gift['recipient_phone']?.toString() ?? ''),
        ));
      } catch (e) {
        final issue = classifyOrderPaymentError(e);
        if (issue != null) {
          emit(PaymentOrderNeedsAttention(
            issue: issue,
            orderId: created.orderId.toString(),
            message: userFacingApiError(e),
          ));
          return;
        }
        emit(PaymentFailure(
          error:
              '${userFacingApiError(e)} Order #${created.orderId} was already created — avoid checking out again (duplicate order).',
        ));
      }
    } catch (e) {
      emit(PaymentFailure(error: userFacingApiError(e)));
    }
  }

  static int? _parseRedeemPoints(dynamic raw) {
    if (raw == null) return null;
    final parsed = raw is int ? raw : int.tryParse(raw.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<void> _onGetPaymentMethods(
    GetPaymentMethodsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final paymentMethods = await paymentRepository.getPaymentMethods();
      emit(PaymentMethodsLoaded(paymentMethods: paymentMethods));
    } catch (e) {
      emit(PaymentFailure(error: userFacingApiError(e)));
    }
  }
}
