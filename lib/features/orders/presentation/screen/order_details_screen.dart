import 'dart:async';

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
import '../widgets/orders_widget.dart' show shortOrderNumber;

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const _pollInterval = Duration(seconds: 12);
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(FetchOrderDetailsEvent(widget.orderId));
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      final state = context.read<OrdersBloc>().state;
      if (state is OrderDetailsLoaded && state.order.isTerminal) {
        _pollTimer?.cancel();
        return;
      }
      // Silent refresh — keep showing last loaded order while fetching.
      context.read<OrdersBloc>().add(FetchOrderDetailsEvent(widget.orderId));
    });
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
        iconTheme: IconThemeData(
          color: HomeColors.textPrimaryOf(context),
          size: 26,
        ),
        centerTitle: true,
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
                _pollTimer?.cancel();
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
              if (state is OrderDetailsLoaded && state.order.isTerminal) {
                _pollTimer?.cancel();
              }
            },
            buildWhen: (previous, current) {
              // Avoid flicker to loading shimmer on poll refreshes.
              if (current is OrderDetailsLoading &&
                  previous is OrderDetailsLoaded) {
                return false;
              }
              return true;
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

              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandOrange,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final baseColor = HomeColors.surfaceElevatedOf(context);
    final highlightColor = HomeColors.surfaceOf(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: HomeColors.backgroundOf(context),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 26),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
            icon: const Icon(Icons.arrow_back_rounded, size: 26),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            context.l10n.orderAppBarTitle(
              shortOrderNumber(order.orderNumber).replaceFirst('#', ''),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            if (order.canBeCancelled)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.errorColor.withValues(
                      alpha: HomeColors.isDark(context) ? 0.2 : 0.1,
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.errorColor,
                  ),
                  onPressed: () => _showCancelOrderDialog(context, order),
                ),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderStatusCard(
                  order: order,
                  trackingEstimatedTime: tracking?.estimatedTime,
                ),
                const SizedBox(height: 14),
                if (tracking != null) ...[
                  OrderTrackingCard(tracking: tracking),
                  const SizedBox(height: 14),
                ],
                OrderTimelineCard(order: order),
                const SizedBox(height: 14),
                PackageInfoCard(order: order),
                const SizedBox(height: 14),
                DeliveryInfoCard(order: order),
                const SizedBox(height: 14),
                PaymentInfoCard(order: order),
                const SizedBox(height: 14),
                VendorInfoCard(vendor: order.vendor),
                const SizedBox(height: 14),
                OrderItemsCard(items: order.items),
                const SizedBox(height: 14),
                OrderSummaryCard(order: order),
                if (order.isDelivered) ...[
                  const SizedBox(height: 14),
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
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 26,
                  color: HomeColors.textPrimaryOf(context),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.errorColor
                            .withValues(alpha: dark ? 0.2 : 0.1),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 46,
                        color: AppColors.errorColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.orderDetailsLoadErrorTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HomeColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.textMutedOf(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: () {
                          context
                              .read<OrdersBloc>()
                              .add(FetchOrderDetailsEvent(widget.orderId));
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.actionRetry),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              height: index == 0 ? 150 : 120,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }
}
