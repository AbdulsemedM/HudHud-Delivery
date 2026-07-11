import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/handyman_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

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

  Color _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
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
          l10n.handymanProfileTitle,
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
      body: _isLoading
          ? _HandymanDetailsShimmer(borderColor: borderColor)
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.spaceLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppColors.spaceMD),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppColors.spaceMD),
                        TextButton.icon(
                          onPressed: _fetchDetails,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.actionRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : _handyman == null
                  ? Center(
                      child: Text(
                        l10n.handymanNotFound,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppColors.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppColors.spaceLG),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusLG),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 48,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: AppColors.spaceMD),
                                Text(
                                  _handyman!.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_handyman!.handymanProfile != null) ...[
                            const SizedBox(height: AppColors.spaceMD),
                            _buildProfileSection(
                              context,
                              theme,
                              borderColor,
                            ),
                          ],
                          if (_stats != null) ...[
                            const SizedBox(height: AppColors.spaceMD),
                            _buildStatsSection(
                              context,
                              theme,
                              borderColor,
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    ThemeData theme,
    Color borderColor,
  ) {
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final profile = _handyman!.handymanProfile!;

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Text(
              l10n.handymanAbout,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppColors.spaceSM),
            Text(
              profile.bio!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppColors.spaceMD),
          ],
          if (profile.skills.isNotEmpty) ...[
            Text(
              l10n.handymanSkillsHeading,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppColors.spaceSM),
            Wrap(
              spacing: AppColors.spaceSM,
              runSpacing: AppColors.spaceSM,
              children: profile.skills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusFull),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _skillChipLabel(l10n, s),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppColors.spaceMD),
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

  Widget _buildStatsSection(
    BuildContext context,
    ThemeData theme,
    Color borderColor,
  ) {
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final stats = _stats!;

    return Container(
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
            l10n.handymanStatsHeading,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppColors.spaceMD),
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

class _HandymanDetailsShimmer extends StatelessWidget {
  final Color borderColor;

  const _HandymanDetailsShimmer({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Padding(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
            ),
            const SizedBox(height: AppColors.spaceMD),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
