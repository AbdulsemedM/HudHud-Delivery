import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/handyman_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

String _skillChipLabel(AppLocalizations l10n, String code) {
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

class HandymanDetailsScreen extends StatefulWidget {
  final int handymanId;

  const HandymanDetailsScreen({super.key, required this.handymanId});

  @override
  State<HandymanDetailsScreen> createState() => _HandymanDetailsScreenState();
}

class _HandymanDetailsScreenState extends State<HandymanDetailsScreen> {
  late final HandymanRepository _repository;
  HandymanModel? _handyman;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = HandymanRepository(
      dataProvider: HandymanDataProvider(apiService: ApiService.instance),
    );
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repository.getHandymanDetails(widget.handymanId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _handyman = result['handyman'] as HandymanModel?;
        _stats = result['stats'] as Map<String, dynamic>?;
        _error = null;
      } else {
        _handyman = null;
        _stats = null;
        _error = result['message'] as String?;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.handymanProfileTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
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
      body: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _fetchDetails,
                          child: Text(
                            l10n.actionRetry,
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _handyman == null
                  ? Center(
                      child: Text(
                        l10n.handymanNotFound,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.6),
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _handyman!.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_handyman!.handymanProfile != null) ...[
                            const SizedBox(height: 24),
                            _buildProfileSection(context, theme),
                          ],
                          if (_stats != null) ...[
                            const SizedBox(height: 24),
                            _buildStatsSection(context, theme),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileSection(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final profile = _handyman!.handymanProfile!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Text(
              l10n.handymanAbout,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (profile.skills.isNotEmpty) ...[
            Text(
              l10n.handymanSkillsHeading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .map((s) => Chip(
                        label: Text(_skillChipLabel(l10n, s)),
                        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.35),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (profile.hourlyRate != null) ...[
            _DetailRow(
              theme: theme,
              label: l10n.handymanHourlyRateLabel,
              value: '\$${profile.hourlyRate}',
            ),
          ],
          if (profile.experienceYears != null) ...[
            _DetailRow(
              theme: theme,
              label: l10n.handymanExperienceLabel,
              value: l10n.handymanExperienceYears('${profile.experienceYears}'),
            ),
          ],
          if (profile.address != null && profile.address!.isNotEmpty) ...[
            _DetailRow(
              theme: theme,
              label: l10n.labelAddress,
              value: profile.address!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final stats = _stats!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.handymanStatsHeading,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                theme: theme,
                label: l10n.handymanStatServices,
                value: stats['total_services']?.toString() ?? '0',
              ),
              _StatItem(
                theme: theme,
                label: l10n.handymanStatRating,
                value: stats['average_rating']?.toString() ?? '—',
              ),
              _StatItem(
                theme: theme,
                label: l10n.handymanStatResponse,
                value: '${stats['response_rate'] ?? 0}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;

  const _DetailRow({required this.theme, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    );
  }
}

class _StatItem extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;

  const _StatItem({required this.theme, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
