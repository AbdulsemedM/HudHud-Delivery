import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/phone_number_field.dart';
import 'package:hudhud_delivery/features/sos/bloc/sos_bloc.dart';
import 'package:hudhud_delivery/features/sos/model/emergency_contact_model.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class EmergencyContactFormScreen extends StatefulWidget {
  final EmergencyContactModel? contact;

  const EmergencyContactFormScreen({super.key, this.contact});

  @override
  State<EmergencyContactFormScreen> createState() =>
      _EmergencyContactFormScreenState();
}

class _EmergencyContactFormScreenState
    extends State<EmergencyContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  String _countryCode = 'US';
  String _dialCode = '+1';
  bool _isPrimary = false;
  bool _submitted = false;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    if (contact != null) {
      _nameController.text = contact.name;
      _emailController.text = contact.email ?? '';
      _relationshipController.text = contact.relationship ?? '';
      _isPrimary = contact.isPrimary;
      final parts = splitPhoneForDisplay(contact.phone, defaultDialCode: '+1');
      _dialCode = parts.countryDialCode;
      _countryCode = 'US';
      _phoneController.text = parts.nationalNumber;
    }
  }

  String _fullPhone() {
    final code = _dialCode.startsWith('+') ? _dialCode : '+$_dialCode';
    final national = cleanNationalPhoneDigits(_phoneController.text);
    return normalizePhoneToBackend('$code$national');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _fullPhone();
    final contact = EmergencyContactModel(
      id: widget.contact?.id ?? 0,
      name: _nameController.text.trim(),
      phone: phone,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      relationship: _relationshipController.text.trim().isEmpty
          ? null
          : _relationshipController.text.trim(),
      isPrimary: _isPrimary,
      isActive: widget.contact?.isActive ?? true,
    );

    setState(() => _submitted = true);
    if (_isEditing) {
      context.read<SosBloc>().add(UpdateEmergencyContactEvent(contact));
    } else {
      context.read<SosBloc>().add(AddEmergencyContactEvent(contact));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SosBloc, SosState>(
      listener: (context, state) {
        if (state is SosError) {
          setState(() => _submitted = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is SosLoaded &&
            _submitted &&
            (state.successMessage == 'contact_added' ||
                state.successMessage == 'contact_updated')) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? l10n.sosEditContact : l10n.sosAddContact,
          ),
        ),
        body: BlocBuilder<SosBloc, SosState>(
          builder: (context, state) {
            final isSubmitting =
                state is SosLoaded && state.isSubmitting;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.sosName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  PhoneNumberField(
                    countryCode: _countryCode,
                    numberController: _phoneController,
                    hintText: l10n.sosPhone,
                    onCountryChanged: (Country country) {
                      setState(() {
                        _countryCode = country.countryCode;
                        _dialCode = '+${country.phoneCode}';
                      });
                    },
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.sosEmail,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _relationshipController,
                    decoration: InputDecoration(
                      labelText: l10n.sosRelationship,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(l10n.sosPrimaryContact),
                    value: _isPrimary,
                    onChanged: isSubmitting
                        ? null
                        : (v) => setState(() => _isPrimary = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? Text(l10n.sosSaving)
                        : Text(_isEditing ? l10n.sosEditContact : l10n.sosAddContact),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
