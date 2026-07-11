import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/service_request_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'handyman_details_screen.dart';
import 'rate_service_screen.dart';
import 'service_quotes_screen.dart';

String _localizedSkillLabel(AppLocalizations l10n, String code) {
  switch (code.toLowerCase()) {
    case 'plumbing':
      return l10n.handymanSkillPlumbing;
    case 'electrical':
      return l10n.handymanSkillElectrical;
    case 'carpentry':
      return l10n.handymanSkillCarpentry;
    case 'painting':
      return l10n.handymanSkillPainting;
    case 'general':
      return l10n.handymanSkillGeneral;
    default:
      return code;
  }
}

class ServiceRequestDetailsScreen extends StatefulWidget {
  final ServiceRequestModel request;

  const ServiceRequestDetailsScreen({super.key, required this.request});

  @override
  State<ServiceRequestDetailsScreen> createState() =>
      _ServiceRequestDetailsScreenState();
}

class _ServiceRequestDetailsScreenState extends State<ServiceRequestDetailsScreen> {
  late ServiceRequestModel _request;
  late final HandymanRepository _repository;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _repository = HandymanRepository(
      dataProvider: HandymanDataProvider(apiService: ApiService.instance),
    );
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

  Color _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
  }

  Future<void> _cancelRequest() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
        ),
        title: Text(l10n.handymanDialogCancelRequestTitle),
        content: Text(l10n.handymanDialogCancelRequestMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: Text(l10n.actionYesCancel),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await _repository.cancelServiceRequest(_request.id);

    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanRequestCancelled),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanCancelFailed),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _openQuotes() async {
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceQuotesScreen(requestId: _request.id),
      ),
    );
    if (accepted == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _openHandyman(int handymanId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HandymanDetailsScreen(handymanId: handymanId),
      ),
    );
  }

  void _rateService() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateServiceScreen(requestId: _request.id),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final borderColor = _cardBorder(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _request.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(status: _request.status),
            const SizedBox(height: AppColors.spaceMD),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppColors.spaceMD),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _request.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: l10n.labelLocation,
                    value: _request.location,
                  ),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: l10n.handymanLabelScheduled,
                    value: _formatDate(_request.scheduledAt),
                  ),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: l10n.labelEstimatedCost,
                    value: _request.formattedEstimatedCost ?? '—',
                  ),
                ],
              ),
            ),
            if (_request.requirements != null) ...[
              const SizedBox(height: AppColors.spaceMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.handymanSectionRequirements,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceSM),
                    if (_request.requirements!.skills.isNotEmpty)
                      Wrap(
                        spacing: AppColors.spaceSM,
                        runSpacing: AppColors.spaceSM,
                        children: _request.requirements!.skills
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppColors.radiusFull),
                                  border: Border.all(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  _localizedSkillLabel(l10n, s),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    if (_request.requirements!.tools.isNotEmpty) ...[
                      const SizedBox(height: AppColors.spaceSM),
                      Text(
                        l10n.handymanToolsLine(
                          _request.requirements!.tools.join(', '),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_request.requirements!.estimatedHours != null)
                      Text(
                        l10n.handymanEstHoursLine(
                          '${_request.requirements!.estimatedHours}',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppColors.spaceLG),
            if (_request.isPending) ...[
              if (_request.quotesCount > 0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openQuotes,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: Text(l10n.handymanViewQuotesCta(_request.quotesCount)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusLG),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppColors.spaceMD),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelRequest,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.handymanCancelRequest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: BorderSide(
                      color: AppColors.errorColor.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                ),
              ),
            ],
            if (_request.isCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _rateService,
                  icon: const Icon(Icons.star_rounded),
                  label: Text(l10n.handymanRateServiceTitle),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                ),
              ),
            ],
            if (_request.provider != null &&
                _request.provider!['id'] != null) ...[
              const SizedBox(height: AppColors.spaceMD),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  border: Border.all(color: borderColor),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.primaryColor.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: Text(
                    _request.provider!['name']?.toString() ??
                        l10n.handymanProviderFallback,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => _openHandyman(
                    _request.provider!['id'] as int,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppColors.radiusMD),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryColor),
          ),
          const SizedBox(width: AppColors.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
