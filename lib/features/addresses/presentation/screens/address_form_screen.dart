import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/addresses/bloc/addresses_bloc.dart';
import 'package:hudhud_delivery/features/addresses/model/address_model.dart';
import 'package:hudhud_delivery/features/addresses/model/address_payload.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/address_map_picker_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';

class AddressFormScreen extends StatefulWidget {
  final AddressModel? existing;
  final Map<String, dynamic>? mapPrefill;
  final bool fromMap;

  const AddressFormScreen({
    super.key,
    this.existing,
    this.mapPrefill,
    this.fromMap = false,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _country;
  late final TextEditingController _label;
  late final TextEditingController _landmark;
  String _addressType = 'home';
  bool _isDefault = false;
  double? _latitude;
  double? _longitude;
  bool _autoGeocode = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final m = widget.mapPrefill;
    _line1 = TextEditingController(
      text: e?.addressLine1 ?? m?['address_line_1']?.toString() ?? '',
    );
    _line2 = TextEditingController(
      text: e?.addressLine2 ?? m?['address_line_2']?.toString() ?? '',
    );
    _city = TextEditingController(
      text: e?.city ?? m?['city']?.toString() ?? '',
    );
    _state = TextEditingController(
      text: e?.state ?? m?['state']?.toString() ?? '',
    );
    _country = TextEditingController(
      text: e?.country ?? m?['country']?.toString() ?? 'Kenya',
    );
    _label = TextEditingController(
      text: e?.label ?? m?['label']?.toString() ?? '',
    );
    _landmark = TextEditingController(text: e?.landmark ?? '');
    _addressType = e?.addressType ?? 'home';
    _isDefault = e?.isDefault ?? false;
    _latitude = e?.latitude ?? (m?['latitude'] as num?)?.toDouble();
    _longitude = e?.longitude ?? (m?['longitude'] as num?)?.toDouble();
    _autoGeocode = widget.fromMap && !_isEdit;
  }

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _label.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddressMapPickerScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _line1.text = result['address_line_1']?.toString() ?? _line1.text;
      _city.text = result['city']?.toString() ?? _city.text;
      _state.text = result['state']?.toString() ?? _state.text;
      _country.text = result['country']?.toString() ?? _country.text;
      if (result['label'] != null) {
        _label.text = result['label'].toString();
      }
      _latitude = (result['latitude'] as num?)?.toDouble();
      _longitude = (result['longitude'] as num?)?.toDouble();
      _autoGeocode = true;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final payload = AddressPayload(
      addressLine1: _line1.text.trim(),
      addressLine2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      postalCode: AddressPayload.defaultPostalCode,
      country: _country.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      addressType: _addressType,
      label: _label.text.trim().isEmpty ? null : _label.text.trim(),
      landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
      isDefault: _isDefault,
      autoGeocode: _autoGeocode,
    );
    if (_isEdit) {
      context.read<AddressesBloc>().add(
            UpdateAddressEvent(id: widget.existing!.id, payload: payload),
          );
    } else {
      context.read<AddressesBloc>().add(CreateAddressEvent(payload));
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AuthScreenColors.textSecondary),
      filled: true,
      fillColor: AuthScreenColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthScreenColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthScreenColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AuthScreenColors.orange, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<AddressesBloc, AddressesState>(
      listenWhen: (prev, curr) =>
          curr is AddressesLoaded && curr.successMessage != null,
      listener: (context, state) {
        if (state is AddressesLoaded && state.successMessage != null) {
          final msg = state.successMessage == 'updated'
              ? l10n.addressesUpdatedSuccess
              : l10n.addressesCreatedSuccess;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          Navigator.pop(context, true);
        } else if (state is AddressesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: ProfileDarkPage(
        title: _isEdit ? l10n.addressFormEditTitle : l10n.addressFormAddTitle,
        body: BlocBuilder<AddressesBloc, AddressesState>(
          builder: (context, state) {
            final submitting = state is AddressesLoaded && state.isSubmitting;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  OutlinedButton.icon(
                    onPressed: submitting ? null : _pickOnMap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AuthScreenColors.orange,
                      side: const BorderSide(color: AuthScreenColors.orange),
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.addressFormPickOnMap),
                  ),
                  const SizedBox(height: 16),
                  _field(_line1, l10n.addressFormLine1, required: true),
                  _field(_line2, l10n.addressFormLine2),
                  _field(_city, l10n.addressFormCity, required: true),
                  _field(_state, l10n.addressFormState),
                  _field(_country, l10n.addressFormCountry, required: true),
                  _field(_label, l10n.addressFormLabel),
                  _field(_landmark, l10n.addressFormLandmark),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _addressType,
                    dropdownColor: AuthScreenColors.surface,
                    style: const TextStyle(color: AuthScreenColors.textPrimary),
                    decoration: _decoration(l10n.addressFormType),
                    items: [
                      DropdownMenuItem(
                        value: 'home',
                        child: Text(l10n.addressesTypeHome),
                      ),
                      DropdownMenuItem(
                        value: 'work',
                        child: Text(l10n.addressesTypeWork),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(l10n.addressesTypeOther),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (v) {
                            if (v != null) setState(() => _addressType = v);
                          },
                  ),
                  SwitchListTile(
                    title: Text(
                      l10n.addressFormSetDefault,
                      style: const TextStyle(color: AuthScreenColors.textPrimary),
                    ),
                    activeThumbColor: AuthScreenColors.orange,
                    value: _isDefault,
                    onChanged: submitting
                        ? null
                        : (v) => setState(() => _isDefault = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AuthScreenColors.orange,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(l10n.actionSave),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AuthScreenColors.textPrimary),
        decoration: _decoration(label),
        validator: required
            ? (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.l10n.addressFormRequired;
                }
                return null;
              }
            : null,
      ),
    );
  }
}
