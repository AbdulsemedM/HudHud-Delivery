import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/repository/payment_repository.dart';

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

  PaymentBloc({required this.paymentRepository}) : super(const PaymentInitial()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<GetPaymentMethodsEvent>(_onGetPaymentMethods);
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final result = await paymentRepository.processPayment(
        paymentMethod: event.paymentMethod,
        amount: event.amount,
        orderId: event.orderId,
        paymentDetails: event.paymentDetails,
      );
      
      emit(PaymentSuccess(
        transactionId: result['transaction_id'] ?? '',
        message: result['message'] ?? 'Payment processed successfully',
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