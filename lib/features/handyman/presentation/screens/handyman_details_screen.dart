import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/models/handyman_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Handyman Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.lightTextPrimary,
          ),
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
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _fetchDetails,
                          child: Text(
                            'Retry',
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _handyman == null
                  ? const Center(child: Text('Handyman not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFF795548).withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: Color(0xFF795548),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _handyman!.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          if (_handyman!.handymanProfile != null) ...[
                            const SizedBox(height: 24),
                            _buildProfileSection(),
                          ],
                          if (_stats != null) ...[
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileSection() {
    final profile = _handyman!.handymanProfile!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
            const Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (profile.skills.isNotEmpty) ...[
            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .map((s) => Chip(
                        label: Text(s),
                        backgroundColor: const Color(0xFF795548).withOpacity(0.1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (profile.hourlyRate != null) ...[
            _DetailRow(
              label: 'Hourly Rate',
              value: '\$${profile.hourlyRate}',
            ),
          ],
          if (profile.experienceYears != null) ...[
            _DetailRow(
              label: 'Experience',
              value: '${profile.experienceYears} years',
            ),
          ],
          if (profile.address != null && profile.address!.isNotEmpty) ...[
            _DetailRow(
              label: 'Address',
              value: profile.address!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _stats!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Services',
                value: stats['total_services']?.toString() ?? '0',
              ),
              _StatItem(
                label: 'Rating',
                value: stats['average_rating']?.toString() ?? '—',
              ),
              _StatItem(
                label: 'Response',
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
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF795548),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
