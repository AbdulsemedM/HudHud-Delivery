import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import '../../bloc/orders_bloc.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_tracking_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listener: (context, state) {
          if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is OrderCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is OrderRated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            );
          }

          if (state is OrderDetailsLoaded) {
            return _buildOrderDetails(
                context, state.order, state.tracking);
          }

          if (state is OrdersError) {
            return _buildErrorState(context, state.message);
          }

          return Center(
            child: Text(context.l10n.orderDetailsLoadingMessage),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetails(
      BuildContext context, OrderModel order, OrderTrackingModel? tracking) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              context.l10n.orderAppBarTitle(order.orderNumber),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange, Colors.deepOrange],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Copy order ID',
              icon: const Icon(Icons.copy_outlined, color: Colors.white),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: '${order.id}'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.orderIdCopied)),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Share order',
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () {
                final l10n = context.l10n;
                Share.share(
                  'Order #${order.orderNumber} (ID: ${order.id})\n${order.status}',
                  subject: l10n.orderShareSubject,
                );
              },
            ),
            if (order.canBeCancelled)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: () => _showCancelOrderDialog(context, order),
              ),
          ],
        ),

        // Order Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Card
                OrderStatusCard(order: order),
                const SizedBox(height: 16),

                // Order Tracking (when available)
                if (tracking != null) ...[
                  OrderTrackingCard(tracking: tracking),
                  const SizedBox(height: 16),
                ],

                // Order Timeline
                OrderTimelineCard(order: order),
                const SizedBox(height: 16),

                // Vendor Information
                VendorInfoCard(vendor: order.vendor),
                const SizedBox(height: 16),

                // Order Items
                OrderItemsCard(items: order.items),
                const SizedBox(height: 16),

                // Delivery Information
                DeliveryInfoCard(order: order),
                const SizedBox(height: 16),

                // Payment Information
                PaymentInfoCard(order: order),
                const SizedBox(height: 16),

                // Order Summary
                OrderSummaryCard(order: order),
                if (order.isDelivered) ...[
                  const SizedBox(height: 16),
                  RateOrderCard(
                    order: order,
                    onRate: (rating, review) {
                      context.read<OrdersBloc>().add(
                            RateOrderEvent(order.id, rating: rating, review: review),
                          );
                    },
                  ),
                ],
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.orderDetailsLoadErrorTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<OrdersBloc>().add(FetchOrderDetailsEvent(widget.orderId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.actionRetry),
          ),
        ],
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