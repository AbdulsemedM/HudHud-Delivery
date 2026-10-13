import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hudhud_delivery/core/easy_mode/easy_mode_controller.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/widgets/call_support_button.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/easy_booking_wizard_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/active_delivery_card.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/courier_history_empty_state.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/delivery_history_card.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_access_gate.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_live_job_screen.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:provider/provider.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import 'delivery_details_screen.dart';
import 'delivery_history_screen.dart';
import 'instant_delivery_screen.dart';
import 'schedule_delivery_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  static const _homeHistoryPreviewCount = 5;

  late final CourierRepository _courierRepository;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoadingDeliveries = true;
  String? _deliveriesError;
  Map<String, dynamic>? _activeDelivery;
  bool _isLoadingActiveDelivery = true;
  int _deliveriesLastPage = 1;

  /// Call FAB collapses to an icon while scrolling down so it never hides content.
  bool _fabExtended = true;
  late final void Function() _homeRefreshListener;

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _homeRefreshListener = () => _refreshData();
    CourierHomeRefresh.instance.addListener(_homeRefreshListener);
    _fetchDeliveries();
    _fetchActiveDelivery();
  }

  @override
  void dispose() {
    CourierHomeRefresh.instance.removeListener(_homeRefreshListener);
    super.dispose();
  }

  List<Map<String, dynamic>> get _recentDeliveries {
    if (_deliveries.length <= _homeHistoryPreviewCount) {
      return _deliveries;
    }
    return _deliveries.take(_homeHistoryPreviewCount).toList();
  }

  bool get _hasMoreHistory =>
      _deliveries.length > _homeHistoryPreviewCount || _deliveriesLastPage > 1;

  Future<void> _fetchActiveDelivery({bool refresh = false}) async {
    if (!refresh && mounted) {
      setState(() => _isLoadingActiveDelivery = true);
    }
    try {
      final result = await _courierRepository.getUserActiveDelivery();
      if (mounted) {
        setState(() {
          _isLoadingActiveDelivery = false;
          if (result['success'] == true && result['delivery'] != null) {
            _activeDelivery = result['delivery'] as Map<String, dynamic>?;
          } else {
            _activeDelivery = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingActiveDelivery = false;
          _activeDelivery = null;
        });
      }
    }
  }

  Future<void> _fetchDeliveries({bool refresh = false}) async {
    if (!refresh && mounted) {
      setState(() => _isLoadingDeliveries = true);
    }
    try {
      final result = await _courierRepository.getUserDeliveries(page: 1);
      if (mounted) {
        setState(() {
          _isLoadingDeliveries = false;
          if (result['success'] == true) {
            _deliveries = result['deliveries'] as List<Map<String, dynamic>>;
            _deliveriesLastPage = result['lastPage'] as int? ?? 1;
            _deliveriesError = null;
          } else {
            _deliveries = [];
            _deliveriesLastPage = 1;
            _deliveriesError = result['message'] as String?;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveries = [];
          _deliveriesLastPage = 1;
          _isLoadingDeliveries = false;
          _deliveriesError = context.l10n.failedToLoadHistory;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchActiveDelivery(),
      _fetchDeliveries(),
    ]);
  }

  void _navigateToTracking(Map<String, dynamic> delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => courierLiveJobScreenFromDelivery(delivery),
      ),
    );
  }

  void _openFullHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeliveryHistoryScreen(),
      ),
    );
  }

  Future<void> _openInstantDelivery() async {
    if (!await requireCourierSendAccess(context)) return;
    if (!mounted) return;
    final easyMode = context.read<EasyModeController>().enabled;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => easyMode
            ? const EasyBookingWizardScreen()
            : const InstantDeliveryScreen(),
      ),
    );
  }

  Future<void> _openScheduleDelivery() async {
    if (!await requireCourierSendAccess(context)) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduleDeliveryScreen(),
      ),
    );
  }

  Widget _buildCreateDeliveryRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _InstantDeliveryCard(
            l10n: l10n,
            onTap: _openInstantDelivery,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ScheduleDeliveryCard(
            l10n: l10n,
            onTap: _openScheduleDelivery,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final borderColor = HomeColors.borderOf(context);
    final hasActive = !_isLoadingActiveDelivery && _activeDelivery != null;

    return Scaffold(
      // Transparent so the home service tiles' shadow isn't painted over.
      backgroundColor: Colors.transparent,
      floatingActionButton: hasActive
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CallSupportFab(
                  heroTag: 'courier_call_support_fab',
                  label: l10n.orderByCall,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'courier_instant_delivery_fab',
                  backgroundColor: AuthScreenColors.orange,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.courierAddDelivery),
                  onPressed: _openInstantDelivery,
                ),
              ],
            )
          : AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: CallSupportFab(
                heroTag: 'courier_call_support_fab',
                label: l10n.orderByCall,
                extended: _fabExtended,
              ),
            ),
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: (n) {
            final extend =
                n.direction == ScrollDirection.forward || n.metrics.pixels <= 0;
            final collapse = n.direction == ScrollDirection.reverse;
            if (collapse && _fabExtended) {
              setState(() => _fabExtended = false);
            } else if (extend && !_fabExtended) {
              setState(() => _fabExtended = true);
            }
            return false;
          },
          child: RefreshIndicator(
            color: HomeColors.violetOf(context),
            backgroundColor: HomeColors.surfaceOf(context),
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasActive) ...[
                    _SectionTitle(l10n.courierActiveDelivery),
                    const SizedBox(height: AppColors.spaceMD),
                    ActiveDeliveryCard(
                      delivery: _activeDelivery!,
                      onTrack: () => _navigateToTracking(_activeDelivery!),
                    ),
                  ] else ...[
                    _SectionTitle(l10n.courierWhatToDo),
                    const SizedBox(height: AppColors.spaceMD),
                    _buildCreateDeliveryRow(l10n),
                  ],
                  const SizedBox(height: 28),
                  _SectionTitle(
                    l10n.history,
                    trailing: _hasMoreHistory
                        ? TextButton.icon(
                            onPressed: _openFullHistory,
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.chevron_right_rounded,
                                size: 22),
                            label: Text(l10n.showMore),
                            style: TextButton.styleFrom(
                              foregroundColor: AuthScreenColors.orange,
                              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                              minimumSize: const Size(0, 40),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingDeliveries)
                    const ShimmerListView(itemCount: 3)
                  else if (_deliveriesError != null)
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Text(
                            _deliveriesError!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: HomeColors.textSecondaryOf(context),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _isLoadingDeliveries = true);
                              _fetchDeliveries();
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.actionRetry),
                            style: TextButton.styleFrom(
                              foregroundColor: HomeColors.violetOf(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_recentDeliveries.isEmpty)
                    CourierHistoryEmptyState(
                      compact: true,
                      onPrimaryAction: hasActive ? null : _openInstantDelivery,
                      primaryActionLabel: l10n.courierInstantTitle,
                    )
                  else
                    ..._recentDeliveries.map((d) {
                      final id = d['id'] as int?;
                      return DeliveryHistoryCard(
                        orderId: id != null ? 'DEL-$id' : '—',
                        recipient: d['receiver_name']?.toString() ?? '—',
                        location: d['dropoff_location']?.toString() ?? '—',
                        dateTime: formatDeliveryHistoryDate(d['created_at']),
                        status: resolveDeliveryStatusLabel(d),
                        borderColor: borderColor,
                        onTap: id != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DeliveryDetailsScreen(deliveryId: id),
                                  ),
                                );
                              }
                            : null,
                      );
                    }),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstantDeliveryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _InstantDeliveryCard({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _BookingCard(
      icon: Icons.bolt_rounded,
      title: l10n.courierNowTitle,
      subtitle: l10n.courierNowSubtitle,
      onTap: onTap,
      filled: true,
    );
  }
}

class _ScheduleDeliveryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _ScheduleDeliveryCard({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _BookingCard(
      icon: Icons.event_rounded,
      title: l10n.courierLaterTitle,
      subtitle: l10n.courierLaterSubtitle,
      onTap: onTap,
      filled: false,
    );
  }
}

/// Big, picture-first booking choice. [filled] = the primary (orange) option.
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filled;

  static const _radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final accent = filled ? Colors.white : HomeColors.violetOf(context);
    final titleColor =
        filled ? Colors.white : HomeColors.textPrimaryOf(context);
    final subColor = filled
        ? Colors.white.withValues(alpha: 0.88)
        : HomeColors.textMutedOf(context);
    final chipBg = filled
        ? Colors.white.withValues(alpha: 0.18)
        : HomeColors.violetTintOf(context);

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Container(
        height: 184,
        decoration: BoxDecoration(
          borderRadius: _radius,
          color: filled ? null : HomeColors.surfaceOf(context),
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                )
              : null,
          border: filled
              ? null
              : Border.all(color: HomeColors.borderOf(context), width: 1.2),
          boxShadow: filled && !dark
              ? [
                  BoxShadow(
                    color: AppColors.brandOrange.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : AppColors.softShadow(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: _radius,
            child: ClipRRect(
              borderRadius: _radius,
              child: Stack(
                children: [
                  // Oversized watermark icon gives the primary card depth.
                  if (filled)
                    Positioned(
                      right: -26,
                      bottom: -30,
                      child: Icon(
                        icon,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.13),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(icon, color: accent, size: 32),
                            ),
                            const Spacer(),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled
                                    ? Colors.white
                                    : HomeColors.violetTintOf(context),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: filled
                                    ? AppColors.brandOrange
                                    : HomeColors.violetOf(context),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 26,
                            height: 1.1,
                            letterSpacing: -0.6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title used on the courier home.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
