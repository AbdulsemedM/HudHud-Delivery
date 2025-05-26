import 'package:flutter/material.dart';

class SignupTitle extends StatelessWidget {
  const SignupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please fill in the form to continue',
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

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  bool _isChecked = false;
  bool _obscurePassword = true;
  String _password = '';
  String _confirmPassword = '';
  bool _obscureConfirmPassword = true;

  String _getPasswordStrength() {
    if (_password.isEmpty) return '';
    if (_password.length < 6) return 'Weak';
    if (_password.length < 8) return 'Medium';
    bool hasUppercase = _password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = _password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters =
        _password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (hasUppercase && hasDigits && hasSpecialCharacters) return 'Strong';
    return 'Medium';
  }

  Color _getStrengthColor() {
    switch (_getPasswordStrength()) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInputField(
          label: 'Full Name',
          icon: Icons.person_outline,
          hint: 'Enter your full name',
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Email',
          icon: Icons.email_outlined,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: _getPasswordStrength() == 'Strong'
              ? 1
              : _getPasswordStrength() == 'Medium'
                  ? 0.5
                  : 0.2,
          backgroundColor: Colors.grey[200],
          color: _getStrengthColor(),
        ),
        const SizedBox(height: 20),
        _buildConfirmPasswordField(),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _isChecked,
              onChanged: (value) {
                setState(() {
                  _isChecked = value ?? false;
                });
              },
              activeColor: const Color(0xFF3498DB),
            ),
            const Expanded(
              child: Text(
                'I agree to the Terms of Service and Privacy Policy',
                style: TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF34495E)),
          prefixIcon: Icon(icon, color: const Color(0xFF3498DB)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        obscureText: _obscurePassword,
        onChanged: (value) {
          setState(() {
            _password = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Enter your password',
          labelStyle: const TextStyle(color: Color(0xFF34495E)),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3498DB)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF3498DB),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        obscureText: _obscureConfirmPassword,
        onChanged: (value) {
          setState(() {
            _confirmPassword = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          hintText: 'Re-enter your password',
          labelStyle: const TextStyle(color: Color(0xFF34495E)),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3498DB)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF3498DB),
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          border: InputBorder.none,
          errorText:
              _confirmPassword.isNotEmpty && _password != _confirmPassword
                  ? 'Passwords do not match'
                  : null,
        ),
      ),
    );
  }
}

class SignupButton extends StatelessWidget {
  const SignupButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3498DB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 3,
        ),
        child: const Text(
          'SIGN UP',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
