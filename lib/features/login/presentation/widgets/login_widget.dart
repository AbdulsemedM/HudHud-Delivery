import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/core/widgets/custom_text_field.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 60,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('assets/images/logo.png'),
      ),
    );
  }
}

class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF7F8C8D),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFieldStyles.authField(
          label: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        CustomTextFieldStyles.authField(
          label: 'Password',
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
        ),
      ],
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 3,
            ),
            child: const Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Color(0xFF3498DB),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
