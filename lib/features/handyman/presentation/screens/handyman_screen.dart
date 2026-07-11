import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/service_request_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/features/home/presentation/widgets/home_widget.dart';
import 'package:lottie/lottie.dart';
import 'create_handyman_request_screen.dart';
import 'service_request_details_screen.dart';

class HandymanScreen extends StatefulWidget {
  const HandymanScreen({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = _cardBorder(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
        color: AppColors.primaryColor,
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
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              _CreateRequestCard(
                borderColor: borderColor,
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
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              if (_isLoading)
                const ShimmerListView(itemCount: 3)
              else if (_error != null)
                _HandymanErrorState(
                  message: _error!,
                  borderColor: borderColor,
                  onRetry: _fetchRequests,
                )
              else if (_requests.isEmpty)
                _HandymanEmptyState(borderColor: borderColor)
              else
                ..._requests.map((req) => _RequestCard(
                      request: req,
                      borderColor: borderColor,
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

  const _CreateRequestCard({
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.08),
                AppColors.primaryColor.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppColors.radiusMD),
                ),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primaryColor,
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.handymanCreateRequestSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.primaryColor.withValues(alpha: 0.7),
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

  const _HandymanEmptyState({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppColors.spaceSM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceXL,
        vertical: AppColors.spaceXL,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppColors.spaceSM),
          Text(
            l10n.handymanNoRequestsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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

  const _HandymanErrorState({
    required this.message,
    required this.borderColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppColors.spaceMD),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppColors.spaceMD),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.actionRetry),
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

  const _RequestCard({
    required this.request,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
      child: Material(
        color: colorScheme.surface,
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
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppColors.radiusMD),
                      ),
                      child: const Icon(
                        Icons.handyman_rounded,
                        color: AppColors.primaryColor,
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
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
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
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                      request.formattedEstimatedCost ?? '—',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (request.quotesCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppColors.radiusFull),
                        ),
                        child: Text(
                          l10n.handymanQuoteCount(request.quotesCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
