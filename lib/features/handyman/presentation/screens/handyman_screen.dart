import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/service_request_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'create_handyman_request_screen.dart';
import 'service_request_details_screen.dart';

class HandymanScreen extends StatefulWidget {
  const HandymanScreen({super.key, this.embedded = false});

  /// When true (embedded in home service tabs), hides [AppBar] and back button.
  final bool embedded;

  @override
  State<HandymanScreen> createState() => _HandymanScreenState();
}

class _HandymanScreenState extends State<HandymanScreen> {
  late final HandymanRepository _repository;
  List<ServiceRequestModel> _requests = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _repository = HandymanRepository(
      dataProvider: HandymanDataProvider(apiService: ApiService.instance),
    );
    if (GuestBrowseService().isGuestBrowseMode) {
      _isLoading = false;
    } else {
      _fetchRequests();
    }
  }

  Future<void> _fetchRequests() async {
    if (!await requireSignInForBackend(context)) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repository.getServiceRequests(page: 1);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _requests = result['requests'] as List<ServiceRequestModel>;
        _error = null;
      } else {
        _requests = [];
        _error = result['message'] as String?;
      }
    });
  }

  List<ServiceRequestModel> get _filteredRequests {
    if (_statusFilter == 'all') return _requests;
    return _requests
        .where((r) => r.status.toLowerCase() == _statusFilter)
        .toList();
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '—';
    try {
      final dt = DateTime.tryParse(value);
      if (dt != null) {
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return value;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.pending;
      case 'completed':
        return AppColors.successColor;
      case 'cancelled':
        return AppColors.errorColor;
      case 'in_progress':
      case 'accepted':
        return AppColors.infoColor;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'in_progress':
      case 'accepted':
        return Icons.build_circle_outlined;
      default:
        return Icons.handyman_outlined;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final filtered = _filteredRequests;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                l10n.handymanServicesTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppColors.sp16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.handymanWhatToDo),
              _CreateRequestCard(
                onTap: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateHandymanRequestScreen(),
                    ),
                  );
                  if (created == true) {
                    _fetchRequests();
                  }
                },
              ),
              const SizedBox(height: AppColors.sp24),
              SectionHeader(title: l10n.handymanMyRequests),
              const SizedBox(height: AppColors.sp8),
              _HandymanFilterChips(
                selectedFilter: _statusFilter,
                onFilterChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
              const SizedBox(height: AppColors.sp12),
              if (_isLoading)
                const _HandymanRequestsShimmer()
              else if (_error != null)
                _HandymanErrorState(
                  message: _error!,
                  onRetry: _fetchRequests,
                )
              else if (_requests.isEmpty)
                _HandymanEmptyState()
              else if (filtered.isEmpty)
                _HandymanEmptyState(
                  title: l10n.handymanNoRequestsYet,
                  subtitle: l10n.handymanNoRequestsSubtitle,
                )
              else
                ...filtered.map(
                  (req) => _RequestCard(
                    request: req,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ServiceRequestDetailsScreen(request: req),
                        ),
                      );
                      _fetchRequests();
                    },
                    formatDate: _formatDate,
                    statusColor: _statusColor,
                    statusIcon: _statusIcon,
                    formatStatus: _formatStatus,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandymanFilterChips extends StatelessWidget {
  const _HandymanFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = <String, String>{
      'all': l10n.sosStatusAll,
      'pending': l10n.orderStatusPending,
      'accepted': l10n.orderStatusConfirmed,
      'in_progress': l10n.taxiStatusTripInProgress,
      'completed': l10n.tipsStatusCompleted,
      'cancelled': l10n.orderStatusCancelled,
    };

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppColors.sp8),
        itemBuilder: (context, index) {
          final entry = filters.entries.elementAt(index);
          final isSelected = selectedFilter == entry.key;

          return FilterChip(
            label: Text(entry.value),
            selected: isSelected,
            showCheckmark: false,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryColor
                  : theme.colorScheme.onSurface,
            ),
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            selectedColor: AppColors.primaryColor.withOpacity(0.12),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.5)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.rFull),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) => onFilterChanged(entry.key),
          );
        },
      ),
    );
  }
}

class _HandymanRequestsShimmer extends StatelessWidget {
  const _HandymanRequestsShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.grey.shade300;
    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    final placeholder = isDark ? AppColors.surfaceDark : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: AppColors.sp12),
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(AppColors.r12),
            ),
          ),
        ),
      ),
    );
  }
}

class _HandymanEmptyState extends StatelessWidget {
  const _HandymanEmptyState({
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppColors.sp8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.sp24,
        vertical: AppColors.sp32,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.r16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/browse.json',
            width: 160,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppColors.sp16),
          Text(
            title ?? l10n.handymanNoRequestsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppColors.sp8),
          Text(
            subtitle ?? l10n.handymanNoRequestsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HandymanErrorState extends StatelessWidget {
  const _HandymanErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppColors.sp24),
      child: Column(
        children: [
          IconBox(
            icon: Icons.error_outline_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppColors.sp12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppColors.sp12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.actionRetry,
              style: const TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateRequestCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateRequestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.r16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withOpacity(0.14),
                AppColors.primaryLightColor.withOpacity(0.08),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppColors.sp20),
            child: Row(
              children: [
                IconBox(
                  icon: Icons.add_circle_outline_rounded,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: AppColors.sp16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.handymanCreateNewRequest,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppColors.sp8),
                      Text(
                        l10n.handymanCreateRequestSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback onTap;
  final String Function(String?) formatDate;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final String Function(String) formatStatus;

  const _RequestCard({
    required this.request,
    required this.onTap,
    required this.formatDate,
    required this.statusColor,
    required this.statusIcon,
    required this.formatStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final color = statusColor(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppColors.sp12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.r12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: Padding(
          padding: const EdgeInsets.all(AppColors.sp12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBox(
                    icon: statusIcon(request.status),
                    color: color,
                  ),
                  const SizedBox(width: AppColors.sp12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDate(request.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: formatStatus(request.status)),
                ],
              ),
              const SizedBox(height: AppColors.sp8),
              Text(
                request.description,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppColors.sp8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: muted),
                  const SizedBox(width: AppColors.sp8),
                  Expanded(
                    child: Text(
                      request.location,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppColors.sp8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    request.formattedEstimatedCost ?? '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  if (request.quotesCount > 0)
                    Text(
                      l10n.handymanQuoteCount(request.quotesCount),
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
