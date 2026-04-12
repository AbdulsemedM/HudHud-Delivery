import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
// import 'package:hudhud_delivery/features/handyman/data/models/service_request_model.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';
import 'package:hudhud_delivery/features/home/presentation/screen/location_search_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'service_request_details_screen.dart';

class CreateHandymanRequestScreen extends StatefulWidget {
  const CreateHandymanRequestScreen({super.key});

  @override
  State<CreateHandymanRequestScreen> createState() =>
      _CreateHandymanRequestScreenState();
}

class _CreateHandymanRequestScreenState
    extends State<CreateHandymanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _toolsController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  late final HandymanRepository _repository;

  String _locationAddress = '';
  double? _latitude;
  double? _longitude;
  DateTime? _scheduledAt;
  final List<String> _selectedSkills = [];
  bool _isSubmitting = false;

  static const List<String> _skillOptions = [
    'plumbing',
    'electrical',
    'carpentry',
    'painting',
    'general',
  ];

  static String _skillDisplay(AppLocalizations l10n, String code) {
    switch (code) {
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

  @override
  void initState() {
    super.initState();
    _repository = HandymanRepository(
      dataProvider: HandymanDataProvider(apiService: ApiService.instance),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _estimatedCostController.dispose();
    _toolsController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationSearchScreen(),
      ),
    );

    if (result != null && result['address'] != null) {
      setState(() {
        _locationAddress = result['address'] as String;
        _locationController.text = _locationAddress;
        final coords = result['coordinates'] as LatLng?;
        if (coords != null) {
          _latitude = coords.latitude;
          _longitude = coords.longitude;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _scheduledAt ?? DateTime(now.year, now.month, now.day, 10, 0),
        ),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationHandymanSelectLocation),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationHandymanSelectDateTime),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationHandymanSelectSkill),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final costStr = _estimatedCostController.text.trim();
    final cost = double.tryParse(costStr) ?? 0;
    final hoursStr = _estimatedHoursController.text.trim();
    final hours = int.tryParse(hoursStr);

    final toolsStr = _toolsController.text.trim();
    final tools = toolsStr.isNotEmpty
        ? toolsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final scheduledAtStr = _scheduledAt!.toIso8601String().replaceAll('T', ' ').substring(0, 19);

    final body = {
      'service_type_code': 'handyman',
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationAddress,
      'latitude': _latitude,
      'longitude': _longitude,
      'scheduled_at': scheduledAtStr,
      'estimated_cost': cost,
      'requirements': {
        'skills': _selectedSkills,
        'tools': tools,
        'estimated_hours': hours,
      },
    };

    final result = await _repository.createServiceRequest(body);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      final serviceRequest = result['serviceRequest'];
      final id = serviceRequest?.id;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanRequestCreatedToast),
          backgroundColor: AppColors.successColor,
        ),
      );

      if (id != null && serviceRequest != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceRequestDetailsScreen(request: serviceRequest!),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.handymanRequestCreateFailed),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.handymanNewRequestTitle,
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.labelTitle,
                  hintText: l10n.hintTitleHandymanExample,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.validationTitleRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.labelDescription,
                  hintText: l10n.hintDescribeRepair,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.validationDescriptionRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.labelLocation,
                  hintText: l10n.handymanTapToSelectLocation,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.search),
                ),
                onTap: _selectLocation,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.validationHandymanSelectLocation : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.labelScheduledDateTime,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _scheduledAt != null
                        ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                        : l10n.selectDateAndTime,
                    style: TextStyle(
                      color: _scheduledAt != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedCostController,
                decoration: InputDecoration(
                  labelText: l10n.labelEstimatedCostOptional,
                  hintText: l10n.hintCostExample,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Text(l10n.handymanSkillsNeeded, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skillOptions.map((skill) {
                  final selected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(_skillDisplay(l10n, skill)),
                    selected: selected,
                    onSelected: (_) => _toggleSkill(skill),
                    selectedColor: AppColors.primaryColor.withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toolsController,
                decoration: InputDecoration(
                  labelText: l10n.labelToolsCommaSeparated,
                  hintText: l10n.hintToolsHandymanExample,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedHoursController,
                decoration: InputDecoration(
                  labelText: l10n.labelEstimatedHoursOptional,
                  hintText: l10n.hintHoursExample,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                          ),
                        )
                      : Text(l10n.handymanCreateRequestCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
