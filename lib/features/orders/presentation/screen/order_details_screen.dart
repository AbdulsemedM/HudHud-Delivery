import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/tips/presentation/widgets/tip_order_card.dart';
import 'package:hudhud_delivery/features/tips/tips_bloc_provider.dart';
import '../../bloc/orders_bloc.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_tracking_model.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_navigation.dart';

import '../widgets/order_details_header.dart';
import '../widgets/order_details_widgets.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(FetchOrderDetailsEvent(widget.orderId));
  }

  Future<void> _onRefresh() async {
    context.read<OrdersBloc>().add(FetchOrderDetailsEvent(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return tipsBlocProvider(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocConsumer<OrdersBloc, OrdersState>(
          listener: (context, state) {
            if (state is OrdersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
            if (state is OrderCancelled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.successColor,
                ),
              );
              Navigator.of(context).pop();
            }
            if (state is OrderRated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.successColor,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is OrderDetailsLoading) {
              return const OrderDetailsShimmer();
            }

            if (state is OrderDetailsLoaded) {
              return _buildOrderDetails(
                context,
                state.order,
                state.tracking,
              );
            }

            if (state is OrdersError) {
              return _buildErrorState(context, state.message);
            }

            return Center(
              child: Text(context.l10n.orderDetailsLoadingMessage),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderDetails(
    BuildContext context,
    OrderModel order,
    OrderTrackingModel? tracking,
  ) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          OrderDetailsSliverHeader(
            order: order,
            onChat: () => openOrderChat(context, order.id),
            onCancel: order.canBeCancelled
                ? () => _showCancelOrderDialog(context, order)
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderTrackingStepper(order: order, tracking: tracking),
                  const SizedBox(height: 16),
                  PackageInfoCard(order: order),
                  const SizedBox(height: 12),
                  RouteInfoCard(order: order),
                  const SizedBox(height: 12),
                  PaymentInfoCard(order: order),
                  const SizedBox(height: 16),
                  OrderItemsCard(items: order.items),
                  const SizedBox(height: 16),
                  OrderSummaryCard(order: order),
                  if (order.isDelivered) ...[
                    const SizedBox(height: 16),
                    RateOrderCard(
                      order: order,
                      onRate: (rating, review) {
                        context.read<OrdersBloc>().add(
                              RateOrderEvent(
                                order.id,
                                rating: rating,
                                review: review,
                              ),
                            );
                      },
                    ),
                    const SizedBox(height: 16),
                    TipOrderCard(order: order),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.75),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.orderDetailsLoadErrorTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context
                    .read<OrdersBloc>()
                    .add(FetchOrderDetailsEvent(widget.orderId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.lightOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.r10),
                ),
              ),
              child: Text(l10n.actionRetry),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelOrderDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CancelOrderDialog(
          order: order,
          onCancel: (reason) {
            context.read<OrdersBloc>().add(
                  CancelOrderEvent(order.id, reason: reason),
                );
          },
        );
      },
    );
  }
}
