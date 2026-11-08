import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../app/services/cart_service.dart';
import '../../../core/l10n/context_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../orders/bloc/orders_bloc.dart';
import '../../orders/data/repositories/orders_repository.dart';
import '../../orders/presentation/screen/order_details_screen.dart';
import '../utils/order_payment_issue.dart';

/// Localized, customer-friendly copy for an [OrderPaymentIssue].
String orderPaymentIssueMessage(BuildContext context, OrderPaymentIssue issue) {
  final l10n = context.l10n;
  switch (issue) {
    case OrderPaymentIssue.inProgress:
      return l10n.p5PaymentInProgress;
    case OrderPaymentIssue.alreadyPaid:
      return l10n.p5PaymentAlreadyPaid;
    case OrderPaymentIssue.totalsChanged:
      return l10n.p5PaymentTotalsChanged;
    case OrderPaymentIssue.notPayable:
      return l10n.p5OrderNotPayable;
  }
}

/// The order exists (it was just created) but this payment attempt was
/// refused: the cart is spent, so replace the current screen with the
/// order (which loads fresh totals / status and keeps polling) and explain
/// why. Never offers to pay again from here, so no duplicate order/charge.
void openOrderAfterPaymentIssue(
  BuildContext context, {
  required OrderPaymentIssue issue,
  required String orderId,
}) {
  final id = int.tryParse(orderId) ?? 0;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = orderPaymentIssueMessage(context, issue);
  final checkLabel = context.l10n.p5CheckOrderStatus;
  CartService().clear();
  if (id <= 0) {
    messenger?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    return;
  }
  final repo = _ordersRepositoryOf(context);
  if (repo == null) {
    messenger?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    return;
  }
  final bloc = OrdersBloc(ordersRepository: repo);
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider<OrdersBloc>(
        create: (_) => bloc,
        child: OrderDetailsScreen(orderId: id),
      ),
    ),
  );
  messenger?.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 8),
      backgroundColor: issue == OrderPaymentIssue.alreadyPaid
          ? AppColors.successColor
          : AppColors.primaryColor,
      // The order screen also refreshes itself every few seconds.
      action: issue == OrderPaymentIssue.inProgress
          ? SnackBarAction(
              label: checkLabel,
              textColor: Colors.white,
              onPressed: () {
                if (!bloc.isClosed) bloc.add(FetchOrderDetailsEvent(id));
              },
            )
          : null,
    ),
  );
}

OrdersRepository? _ordersRepositoryOf(BuildContext context) {
  try {
    return context.read<OrdersRepository>();
  } on ProviderNotFoundException {
    return null;
  }
}
