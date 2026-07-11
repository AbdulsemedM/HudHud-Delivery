import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/controllers/auth_controller.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:provider/provider.dart';
import '../../bloc/orders_bloc.dart';
import '../widgets/orders_widget.dart';
import '../../data/repositories/orders_repository.dart';

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

  void _onStatusFilterChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<OrdersBloc>().add(FilterOrdersByStatusEvent(status));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(
        ordersRepository: context.read<OrdersRepository>(),
      )..add(const FetchOrdersEvent()),
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () async {
              context.read<OrdersBloc>().add(const RefreshOrdersEvent());
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrdersHeader(
                          avatarUrl: getDisplayAvatarUrl(
                            context.watch<AuthController>().currentUser,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const OrdersTitle(),
                        const SizedBox(height: 12),
                        OrderStatusFilterChips(
                          selectedStatus: _selectedStatus,
                          onStatusChanged: _onStatusFilterChanged,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, state) {
                    if (state is OrdersLoading && state.orders.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: OrdersListShimmer(),
                      );
                    }

                    if (state is OrdersError && state.orders.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: OrdersErrorState(
                          message: state.message,
                          onRetry: () {
                            context
                                .read<OrdersBloc>()
                                .add(const FetchOrdersEvent());
                          },
                        ),
                      );
                    }

                    final orders = state is OrdersLoaded
                        ? state.orders
                        : state is OrdersError
                            ? state.orders
                            : [];

                    if (orders.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: OrdersEmptyState(),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= orders.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: OrderItemCard(
                              order: order,
                              onTap: () {
                                pushOrderDetailsById(
                                  context,
                                  orderId: order.id,
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
