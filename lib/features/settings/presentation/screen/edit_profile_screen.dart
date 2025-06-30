import 'package:flutter/material.dart';
import '../widgets/edit_profile_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String firstName = 'Samara';
  String lastName = 'Mehmood';
  String countryCode = '+92';
  String phoneNumber = '3069278009';
  String email = 'debbie.baker@example.com';

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
      body: SingleChildScrollView(
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
                  onCountryTap: () {
                    // Handle country selection
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
              onPressed: () {
                // Handle update profile
              },
            ),
          ],
        ),
      ),
    );
  }
}
