import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/orders/bloc/orders_bloc.dart';
import 'package:hudhud_delivery/features/orders/data/repositories/orders_repository.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/orders_widget.dart';
import 'package:hudhud_delivery/models/user_model.dart';

/// Marketplace order history (Food / vendor orders).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(
        ordersRepository: context.read<OrdersRepository>(),
      )..add(const FetchOrdersEvent()),
      child: const _OrdersScreenBody(),
    );
  }
}

class _OrdersScreenBody extends StatefulWidget {
  const _OrdersScreenBody();

  @override
  State<_OrdersScreenBody> createState() => _OrdersScreenBodyState();
}

class _OrdersScreenBodyState extends State<_OrdersScreenBody> {
  UserModel? _user;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getStoredUser();
    if (mounted) setState(() => _user = user);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 200) {
      context.read<OrdersBloc>().add(const LoadMoreOrdersEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HomeColors.themeFor(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: Scaffold(
          backgroundColor: HomeColors.backgroundOf(context),
          body: SafeArea(
            child: BlocConsumer<OrdersBloc, OrdersState>(
              listener: (context, state) {
                if (state is OrdersError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              },
              builder: (context, state) {
                String? filter;
                if (state is OrdersLoaded) {
                  filter = state.currentFilter;
                }

                return RefreshIndicator(
                  color: HomeColors.violet,
                  onRefresh: () async {
                    context
                        .read<OrdersBloc>()
                        .add(const RefreshOrdersEvent());
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OrdersHeader(user: _user),
                              const SizedBox(height: 16),
                              const OrdersTitle(),
                              const SizedBox(height: 12),
                              OrderFilterChips(
                                selectedStatus: filter,
                                onFilterChanged: (status) {
                                  context.read<OrdersBloc>().add(
                                        FilterOrdersByStatusEvent(status),
                                      );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      ..._buildOrderSlivers(context, state),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrderSlivers(BuildContext context, OrdersState state) {
    if (state is OrdersLoading || state is OrdersInitial) {
      return [
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: OrdersShimmer()),
        ),
      ];
    }

    if (state is OrdersError) {
      final l10n = context.l10n;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: HomeColors.textMutedOf(context),
                ),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HomeColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context
                      .read<OrdersBloc>()
                      .add(const RefreshOrdersEvent()),
                  child: Text(l10n.actionRetry),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final orders = state is OrdersLoaded
        ? state.orders
        : state is OrdersLoadingMore
            ? state.currentOrders
            : <dynamic>[];

    if (orders.isEmpty) {
      final l10n = context.l10n;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.noOrdersYetStore,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HomeColors.textMutedOf(context),
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= orders.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final order = orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OrderItemCard(
                  order: order,
                  onTap: () => pushOrderDetailsById(
                    context,
                    orderId: order.id,
                  ),
                ),
              );
            },
            childCount: orders.length + (state is OrdersLoadingMore ? 1 : 0),
          ),
        ),
      ),
    ];
  }
}
