import 'package:flutter/material.dart';
import '../widgets/signup_widget.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE6E6FA),
                  Color(0xFFB2DFEE),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Color(0xFF2C3E50)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 20),
                    SignupTitle(),
                    const SizedBox(height: 40),
                    SignupForm(),
                    const SizedBox(height: 20),
                    SignupButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
