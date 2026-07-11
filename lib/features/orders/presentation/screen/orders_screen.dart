import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import '../../bloc/orders_bloc.dart';
import '../widgets/orders_widget.dart';
import '../../data/repositories/orders_repository.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late ScrollController _scrollController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<OrdersBloc>().add(const LoadMoreOrdersEvent());
    }
  }

  void _onFilterChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<OrdersBloc>().add(FilterOrdersByStatusEvent(status));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => OrdersBloc(
        ordersRepository: context.read<OrdersRepository>(),
      )..add(const FetchOrdersEvent()),
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<OrdersBloc>().add(const RefreshOrdersEvent());
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const OrdersHeader(),
                        const SizedBox(height: AppColors.spaceLG),
                        const OrdersTitle(),
                        const SizedBox(height: AppColors.spaceMD),
                        OrderFilterChips(
                          selectedStatus: _selectedStatus,
                          onFilterChanged: _onFilterChanged,
                        ),
                        const SizedBox(height: AppColors.spaceMD),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, state) {
                    if (state is OrdersLoading && state.orders.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: OrdersShimmer(),
                        ),
                      );
                    }

                    if (state is OrdersError && state.orders.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.failedToLoadOrders(state.message),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () {
                                  context
                                      .read<OrdersBloc>()
                                      .add(const FetchOrdersEvent());
                                },
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.actionRetry),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final orders = state is OrdersLoaded
                        ? state.orders
                        : state is OrdersError
                            ? state.orders
                            : [];

                    if (orders.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/browse.json',
                                width: 200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.orderHistoryEmptyTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  l10n.orderHistoryEmptyHint,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= orders.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4.0,
                            ),
                            child: OrderItemCard(
                              order: order,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      orderId: order.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: orders.length +
                            (state is OrdersLoading && orders.isNotEmpty
                                ? 1
                                : 0),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
