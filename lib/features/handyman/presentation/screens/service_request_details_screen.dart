import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
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

  Future<void> _cancelRequest() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _request.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: theme.colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.dividerColor.withOpacity(0.5),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(_request.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _request.status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.surface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _request.description,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.location_on,
              label: l10n.labelLocation,
              value: _request.location,
            ),
            _DetailRow(
              icon: Icons.schedule,
              label: l10n.handymanLabelScheduled,
              value: _formatDate(_request.scheduledAt),
            ),
            _DetailRow(
              icon: Icons.attach_money,
              label: l10n.labelEstimatedCost,
              value: _request.formattedEstimatedCost ?? '—',
            ),
            if (_request.requirements != null) ...[
              const SizedBox(height: 8),
              Text(l10n.handymanSectionRequirements, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (_request.requirements!.skills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _request.requirements!.skills
                      .map((s) => Chip(label: Text(_localizedSkillLabel(l10n, s))))
                      .toList(),
                ),
              if (_request.requirements!.tools.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.handymanToolsLine(_request.requirements!.tools.join(', ')),
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (_request.requirements!.estimatedHours != null)
                Text(
                  l10n.handymanEstHoursLine('${_request.requirements!.estimatedHours}'),
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
            const SizedBox(height: 24),
            if (_request.isPending) ...[
              if (_request.quotesCount > 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openQuotes,
                    icon: const Icon(Icons.receipt_long),
                    label: Text(l10n.handymanViewQuotesCta(_request.quotesCount)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelRequest,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.handymanCancelRequest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: const BorderSide(color: AppColors.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            if (_request.isCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _rateService,
                  icon: const Icon(Icons.star),
                  label: Text(l10n.handymanRateServiceTitle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            if (_request.provider != null &&
                _request.provider!['id'] != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  _request.provider!['name']?.toString() ?? l10n.handymanProviderFallback,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _openHandyman(
                  _request.provider!['id'] as int,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
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
