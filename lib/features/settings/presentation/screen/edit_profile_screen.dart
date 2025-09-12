import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import '../widgets/edit_profile_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  
  String firstName = '';
  String lastName = '';
  String countryCode = '+';
  String phoneNumber = '';
  String email = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _user = user;
          
          // Split the name into first and last name
          final nameParts = user?.name?.split(' ') ?? [];
          firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          // Extract country code and phone number
          final fullPhone = user?.phone ?? '';
          if (fullPhone.startsWith('+')) {
            // Simple extraction - this might need to be more sophisticated
            countryCode = fullPhone.substring(0, 3); // Assuming +XX format
            phoneNumber = fullPhone.substring(3);
          } else {
            countryCode = '+';
            phoneNumber = fullPhone;
          }
          
          email = user?.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: Colors.black,
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
                imageUrl: 'assets/images/profile.jpg',
                onImageTap: () {
                  // Handle image selection
                },
              ),
            ),
            const SizedBox(height: 32),
            ProfileTextField(
              label: 'First Name',
              value: firstName,
              onChanged: (value) => setState(() => firstName = value),
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Last Name',
              value: lastName,
              onChanged: (value) => setState(() => lastName = value),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                PhoneNumberField(
                  countryCode: countryCode,
                  number: phoneNumber,
                  onNumberChanged: (value) =>
                      setState(() => phoneNumber = value),
                  onCountryChanged: (Country value) {
                    setState(() {
                      countryCode = value.phoneCode;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProfileTextField(
              label: 'Email',
              value: email,
              onChanged: (value) => setState(() => email = value),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            UpdateButton(
              onPressed: _isLoading ? () {} : () async {
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  // Combine first and last name
                  final fullName = '$firstName $lastName'.trim();
                  // Combine country code and phone number
                  final fullPhone = '$countryCode$phoneNumber';
                  
                  await _authService.updateProfile(
                    name: fullName,
                    phone: fullPhone,
                    email: email,
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update profile: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
