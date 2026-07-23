import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/saved_location_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
import 'package:hudhud_delivery/features/home/presentation/screen/location_search_screen.dart';
import 'package:hudhud_delivery/features/home/presentation/widgets/home_widget.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/notifications_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import '../../bloc/orders_bloc.dart';
import '../widgets/orders_widget.dart';
import '../../data/repositories/orders_repository.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final AuthService _authService = AuthService();
  late ScrollController _scrollController;
  String? _selectedStatus;
  UserModel? _currentUser;
  String _currentLocation = '';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadUserData();
    _requestLocationAndUpdate();
  }

  Future<void> _loadUserData() async {
    if (GuestBrowseService().isGuestBrowseMode) {
      if (mounted) setState(() => _currentUser = null);
      return;
    }
    final user =
        await _authService.getUserProfile() ?? await _authService.getStoredUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _requestLocationAndUpdate() async {
    try {
      setState(() => _isLoadingLocation = true);
      final saved = await SavedLocationService.getSavedLocationData();
      final savedAddress = saved?['address'] as String?;
      if (savedAddress != null && savedAddress.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentLocation = savedAddress;
            _isLoadingLocation = false;
          });
        }
        return;
      }
      final location = await LocationService.getCurrentLocationAddress();
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = context.l10n.locationUnable;
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _openNotifications() async {
    if (GuestBrowseService().isGuestBrowseMode) {
      final l10n = AppLocalizations.of(context)!;
      final authed = await showGuestSignInRequiredDialog(
        context,
        message: l10n.guestSignInRequiredMessage,
      );
      if (!authed) return;
      if (!context.mounted) return;
      await _loadUserData();
      if (!context.mounted) return;
    }
    if (!context.mounted) return;
    _pushNotificationsScreen();
  }

  void _pushNotificationsScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (_) => createNotificationsBloc(),
          child: const NotificationsScreen(),
        ),
      ),
    );
  }

  void _openLocationSearch() {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSearchScreen(
          currentLocation: _currentLocation,
        ),
      ),
    ).then((result) {
      if (result != null && result['address'] != null && mounted) {
        setState(() {
          _currentLocation = result['address'] as String;
        });
      }
    });
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
                        UserProfileHeader(
                          name: _currentUser?.name ?? l10n.userDefault,
                          location: _currentLocation,
                          isLoadingLocation: _isLoadingLocation,
                          user: _currentUser,
                          onLocationTap: _openLocationSearch,
                          onNotificationsTap: _openNotifications,
                        ),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 56,
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                l10n.orderHistoryEmptyTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
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
