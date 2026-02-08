import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/service_request_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'handyman_details_screen.dart';
import 'rate_service_screen.dart';
import 'service_quotes_screen.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this service request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Yes, Cancel'),
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
          content: Text(result['message'] as String? ?? 'Request cancelled'),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Failed to cancel'),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _request.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.lightTextPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.lightTextPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.lightBorder.withOpacity(0.5),
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
                style: const TextStyle(
                  color: Colors.white,
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
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Location',
              value: _request.location,
            ),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Scheduled',
              value: _formatDate(_request.scheduledAt),
            ),
            _DetailRow(
              icon: Icons.attach_money,
              label: 'Estimated Cost',
              value: _request.formattedEstimatedCost ?? '—',
            ),
            if (_request.requirements != null) ...[
              const SizedBox(height: 8),
              const Text('Requirements', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (_request.requirements!.skills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _request.requirements!.skills
                      .map((s) => Chip(label: Text(s)))
                      .toList(),
                ),
              if (_request.requirements!.tools.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Tools: ${_request.requirements!.tools.join(", ")}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
              if (_request.requirements!.estimatedHours != null)
                Text(
                  'Est. hours: ${_request.requirements!.estimatedHours}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                    label: Text('View ${_request.quotesCount} Quote(s)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
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
                  label: const Text('Cancel Request'),
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
                  label: const Text('Rate Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
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
                  _request.provider!['name']?.toString() ?? 'Provider',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
