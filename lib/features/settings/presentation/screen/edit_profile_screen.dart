import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/controllers/auth_controller.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../widgets/edit_profile_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String countryCode = kDefaultPhoneDialCode;
  String? _avatarNetworkUrl;
  String? _avatarLocalPath;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getUserProfile(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        final nameParts = user?.name?.split(' ') ?? [];
        _firstNameController.text =
            nameParts.isNotEmpty ? nameParts[0] : '';
        _lastNameController.text =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        _applyPhoneFromUser(user?.phone);
        _emailController.text = user?.email ?? '';
        _avatarNetworkUrl = getDisplayAvatarUrl(user);
        _avatarLocalPath = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileLoadFailed(e.toString()))),
      );
    }
  }

  void _applyPhoneFromUser(String? fullPhone) {
    final parts = splitPhoneForDisplay(fullPhone);
    countryCode = parts.countryDialCode;
    _phoneController.text = parts.nationalNumber;
  }

  Future<bool> _requestAvatarPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk >= 33) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }

    return true;
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final granted = await _requestAvatarPermissions(source);
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera or photo permission is required'),
        ),
      );
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _avatarLocalPath = picked.path);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final needsRestart = e.code == 'channel-error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            needsRestart
                ? 'Restart the app fully (stop and run again) to use the photo picker.'
                : 'Could not open photo picker: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open photo picker: $e')),
      );
    }
  }

  String _fullPhone() {
    final code =
        countryCode.startsWith('+') ? countryCode : '+$countryCode';
    final national = cleanNationalPhoneDigits(_phoneController.text);
    return normalizePhoneToBackend('$code$national');
  }

  Future<void> _saveProfile() async {
    final fullName =
        '${_firstNameController.text} ${_lastNameController.text}'.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authController = context.read<AuthController>();
    final success = await authController.updateProfile(
      name: fullName,
      phone: _fullPhone(),
      email: _emailController.text.trim(),
      avatarPath: _avatarLocalPath,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdatedSuccess)),
      );
      Navigator.pop(context, true);
    } else {
      final msg = authController.errorMessage ?? 'Profile update failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdateFailed(msg))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.profileMenuAccountSettings,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: ProfileImagePicker(
                      networkImageUrl: _avatarLocalPath == null
                          ? _avatarNetworkUrl
                          : null,
                      localImagePath: _avatarLocalPath,
                      onImageTap: _pickAvatar,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ProfileTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mobile Number',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      PhoneNumberField(
                        countryCode: countryCode,
                        numberController: _phoneController,
                        onCountryChanged: (Country value) {
                          setState(() {
                            countryCode = '+${value.phoneCode}';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  UpdateButton(
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
    );
  }
}
