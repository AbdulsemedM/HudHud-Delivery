import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/service_request_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/widgets/home_widget.dart';
import 'package:lottie/lottie.dart';
import 'create_handyman_request_screen.dart';
import 'service_request_details_screen.dart';

const Color _handymanBlue = ServiceTabPalette.handyman;

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

  @override
  void initState() {
    super.initState();
    _repository = HandymanRepository(
      dataProvider: HandymanDataProvider(apiService: ApiService.instance),
    );
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
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

  Color _cardBorder(BuildContext context) {
    if (widget.embedded) return HomeColors.border;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = _cardBorder(context);
    final embedded = widget.embedded;
    final bg = embedded ? HomeColors.background : theme.scaffoldBackgroundColor;
    final onSurface = embedded ? HomeColors.textPrimary : colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: embedded
          ? null
          : AppBar(
        title: Text(
          l10n.handymanServicesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: embedded ? _handymanBlue : AppColors.primaryColor,
        onRefresh: _fetchRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppColors.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.handymanWhatToDo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              _CreateRequestCard(
                borderColor: borderColor,
                embedded: embedded,
                onTap: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateHandymanRequestScreen(),
                    ),
                  );
                  if (created == true) {
                    _fetchRequests();
                  }
                },
              ),
              const SizedBox(height: AppColors.spaceLG),
              Text(
                l10n.handymanMyRequests,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              if (_isLoading)
                const ShimmerListView(itemCount: 3)
              else if (_error != null)
                _HandymanErrorState(
                  message: _error!,
                  borderColor: borderColor,
                  embedded: embedded,
                  onRetry: _fetchRequests,
                )
              else if (_requests.isEmpty)
                _HandymanEmptyState(
                  borderColor: borderColor,
                  embedded: embedded,
                )
              else
                ..._requests.map((req) => _RequestCard(
                      request: req,
                      borderColor: borderColor,
                      embedded: embedded,
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
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateRequestCard extends StatelessWidget {
  final VoidCallback onTap;
  final Color borderColor;
  final bool embedded;

  const _CreateRequestCard({
    required this.onTap,
    required this.borderColor,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = embedded ? _handymanBlue : AppColors.primaryColor;
    final surface = embedded ? HomeColors.surfaceElevated : colorScheme.surface;
    final titleColor = embedded ? HomeColors.textPrimary : colorScheme.onSurface;
    final subtitleColor =
        embedded ? HomeColors.textMuted : colorScheme.onSurfaceVariant;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppColors.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: embedded ? 0.16 : 0.08),
                accent.withValues(alpha: embedded ? 0.06 : 0.03),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppColors.radiusMD),
                ),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppColors.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.handymanCreateNewRequest,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.handymanCreateRequestSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: accent.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandymanEmptyState extends StatelessWidget {
  final Color borderColor;
  final bool embedded;

  const _HandymanEmptyState({
    required this.borderColor,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = embedded ? HomeColors.surface : colorScheme.surface;
    final titleColor = embedded ? HomeColors.textPrimary : colorScheme.onSurface;
    final subtitleColor =
        embedded ? HomeColors.textMuted : colorScheme.onSurfaceVariant;
    final iconColor = embedded ? _handymanBlue : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppColors.spaceSM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceXL,
        vertical: AppColors.spaceXL,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (embedded)
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _handymanBlue.withValues(alpha: 0.14),
              ),
              child: Icon(
                Icons.handyman_rounded,
                size: 44,
                color: iconColor,
              ),
            )
          else
            Lottie.asset(
              'assets/animations/browse.json',
              width: 160,
              errorBuilder: (_, __, ___) => Icon(
                Icons.handyman_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppColors.spaceMD),
          Text(
            l10n.handymanNoRequestsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: AppColors.spaceSM),
          Text(
            l10n.handymanNoRequestsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HandymanErrorState extends StatelessWidget {
  final String message;
  final Color borderColor;
  final VoidCallback onRetry;
  final bool embedded;

  const _HandymanErrorState({
    required this.message,
    required this.borderColor,
    required this.onRetry,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = embedded ? HomeColors.surface : colorScheme.surface;
    final muted =
        embedded ? HomeColors.textMuted : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: muted),
          const SizedBox(height: AppColors.spaceMD),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppColors.spaceMD),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.actionRetry),
            style: TextButton.styleFrom(
              foregroundColor: embedded ? _handymanBlue : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback onTap;
  final Color borderColor;
  final bool embedded;

  const _RequestCard({
    required this.request,
    required this.onTap,
    required this.borderColor,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = embedded ? _handymanBlue : AppColors.primaryColor;
    final surface = embedded ? HomeColors.surface : colorScheme.surface;
    final titleColor = embedded ? HomeColors.textPrimary : colorScheme.onSurface;
    final muted =
        embedded ? HomeColors.textMuted : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          child: Container(
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppColors.radiusMD),
                      ),
                      child: Icon(
                        Icons.handyman_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppColors.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppColors.spaceSM),
                    StatusChip(status: request.status),
                  ],
                ),
                const SizedBox(height: AppColors.spaceMD),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppColors.spaceMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.formattedEstimatedCost ?? '\u2014',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    if (request.quotesCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: embedded
                              ? HomeColors.surfaceElevated
                              : colorScheme.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusFull),
                        ),
                        child: Text(
                          l10n.handymanQuoteCount(request.quotesCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
