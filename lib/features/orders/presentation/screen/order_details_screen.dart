import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
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

  ThemeData _homeTheme(BuildContext context) {
    final base = HomeColors.themeFor(context);
    return base.copyWith(
      cardTheme: CardThemeData(
        color: HomeColors.surfaceOf(context),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          side: BorderSide(color: HomeColors.borderOf(context)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HomeColors.backgroundOf(context),
        foregroundColor: HomeColors.textPrimaryOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: HomeColors.textPrimaryOf(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _homeTheme(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: Scaffold(
          backgroundColor: HomeColors.backgroundOf(context),
          body: BlocConsumer<OrdersBloc, OrdersState>(
            listener: (context, state) {
              if (state is OrdersError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.errorColor,
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
                return _buildLoadingState(context);
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
                child: CircularProgressIndicator(color: HomeColors.violet),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final baseColor = HomeColors.surfaceOf(context);
    final highlightColor = HomeColors.surfaceElevatedOf(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: HomeColors.backgroundOf(context),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _DetailsShimmer(
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(
    BuildContext context,
    OrderModel order,
    OrderTrackingModel? tracking,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: HomeColors.backgroundOf(context),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            context.l10n.orderAppBarTitle(order.orderNumber),
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (order.canBeCancelled)
              IconButton(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: AppColors.errorColor,
                ),
                onPressed: () => _showCancelOrderDialog(context, order),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppColors.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderStatusCard(
                  order: order,
                  trackingEstimatedTime: tracking?.estimatedTime,
                ),
                SizedBox(height: AppColors.spaceMD),
                if (tracking != null) ...[
                  OrderTrackingCard(tracking: tracking),
                  SizedBox(height: AppColors.spaceMD),
                ],
                OrderTimelineCard(order: order),
                SizedBox(height: AppColors.spaceMD),
                PackageInfoCard(order: order),
                SizedBox(height: AppColors.spaceMD),
                DeliveryInfoCard(order: order),
                SizedBox(height: AppColors.spaceMD),
                PaymentInfoCard(order: order),
                SizedBox(height: AppColors.spaceMD),
                VendorInfoCard(vendor: order.vendor),
                SizedBox(height: AppColors.spaceMD),
                OrderItemsCard(items: order.items),
                SizedBox(height: AppColors.spaceMD),
                OrderSummaryCard(order: order),
                if (order.isDelivered) ...[
                  SizedBox(height: AppColors.spaceMD),
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
                ],
                SizedBox(height: 100),
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
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: HomeColors.textMutedOf(context),
          ),
          SizedBox(height: 16),
          Text(
            l10n.orderDetailsLoadErrorTitle,
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(color: HomeColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: HomeColors.violet),
            onPressed: () {
              context
                  .read<OrdersBloc>()
                  .add(FetchOrderDetailsEvent(widget.orderId));
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.actionRetry),
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

class _DetailsShimmer extends StatelessWidget {
  const _DetailsShimmer({
    required this.baseColor,
    required this.highlightColor,
  });

  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
              ),
            ),
          );
        }),
      ),
    );
  }
}
