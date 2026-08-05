import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../checkout/data/models/create_order_result.dart';
import '../../checkout/data/repository/checkout_repository.dart';
import '../data/repository/payment_repository.dart';
import '../model/payment_initiate_result.dart';
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

  const PaymentInitiated({
    required this.result,
    required this.orderId,
  });

  @override
  List<Object?> get props => [result, orderId];
}

class PaymentFailure extends PaymentState {
  final String error;

  const PaymentFailure({required this.error});

  @override
  List<Object?> get props => [error];
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

      final orderResult = await checkoutRepository.createOrder(
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
        serviceType: orderDetails['service_type'] as String? ?? 'delivery',
        notes: orderDetails['notes'] as String?,
      );

      if (orderResult['success'] != true) {
        emit(PaymentFailure(
            error: orderResult['message'] ?? 'Failed to create order'));
        return;
      }

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

      final collectedDetails = Map<String, dynamic>.from(
        (event.paymentDetails ?? {})..remove('order_details'),
      );
      final initiateDetails = buildInitiatePaymentDetails(
        paymentMethodCode: event.paymentMethod,
        collectedDetails: collectedDetails,
        orderId: created.orderId,
      );

      final raw = await paymentRepository.initiatePayment(
        paymentMethodCode: event.paymentMethod,
        type: 'order',
        orderId: created.orderId,
        amount: amount,
        currency: currency,
        paymentDetails: initiateDetails,
      );

      final result = PaymentInitiateResult.fromJson(raw);
      if (!result.isSuccess) {
        emit(PaymentFailure(
          error: result.message ?? 'Payment initiation failed',
        ));
        return;
      }

      emit(PaymentInitiated(
        result: result,
        orderId: created.orderId.toString(),
      ));
    } catch (e) {
      emit(PaymentFailure(error: e.toString()));
    }
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
      emit(PaymentFailure(error: e.toString()));
    }
  }
}
