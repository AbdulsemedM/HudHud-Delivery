import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../screen/verify_contact_screen.dart';
import '../../bloc/signup_bloc.dart';

class SignupTitle extends StatelessWidget {
  const SignupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign Up',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? cs.onSurface : const Color(0xFF2C3E50),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account and proceed to access all the Businesses offered to you',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? cs.onSurfaceVariant : Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  _SignupFormState createState() => _SignupFormState();
}

// Create the form with the global key
Widget createSignupForm() {
  return SignupForm(key: signupFormKey);
}

class SignupFormData {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;

  SignupFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
  });
}

// Global key to access form state
final GlobalKey<_SignupFormState> signupFormKey = GlobalKey<_SignupFormState>();

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _phoneNumber = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _dataProtectionAccepted = false;

  // Ethiopian phone number validation
  String? validateAndFormatPhoneNumber(String input) {
    // Remove all whitespace and trim
    input = input.trim().replaceAll(RegExp(r'\s+'), '');

    // Must only contain digits
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      return null;
    }

    // Remove starting '0' if present
    if (input.startsWith('0')) {
      input = input.substring(1);
    }

    // Check if it starts with valid Ethiopian prefixes and has correct length
    if ((input.startsWith('9') || input.startsWith('7')) && input.length == 9) {
      return input; // Valid and cleaned
    }

    return null; // Invalid
  }

  SignupFormData getFormData() {
    return SignupFormData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
      phoneNumber: _phoneNumber.isNotEmpty ? _phoneNumber : _phoneController.text.trim(),
    );
  }

  bool isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  bool areCheckboxesAccepted() {
    return _termsAccepted && _dataProtectionAccepted;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  TextStyle _signupLabelStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextStyle(
      fontSize: 13,
      color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[700],
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle _signupFieldTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? theme.colorScheme.onSurface : Colors.grey[800],
      fontSize: 14,
    );
  }

  InputDecoration _signupFieldDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fieldFill =
        isDark ? cs.surfaceContainerHighest : Colors.grey[50]!;
    final borderColor =
        isDark ? cs.outline.withValues(alpha: 0.45) : Colors.grey[200]!;
    final hintColor = isDark
        ? cs.onSurfaceVariant.withValues(alpha: 0.75)
        : Colors.grey[400]!;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 14,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconMuted =
        isDark ? cs.onSurfaceVariant : Colors.grey[600]!;
    final checkboxBodyStyle = TextStyle(
      fontSize: 13,
      color: isDark ? cs.onSurfaceVariant : Colors.grey[700],
      height: 1.4,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Name and Last Name in a Row
          Row(
            children: [
              // First Name Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First name',
                      style: _signupLabelStyle(context),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _signupFieldDecoration(
                        context,
                        hintText: 'Eg. John',
                      ),
                      style: _signupFieldTextStyle(context),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Last Name Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last name',
                      style: _signupLabelStyle(context),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _signupFieldDecoration(
                        context,
                        hintText: 'Eg. Doe',
                      ),
                      style: _signupFieldTextStyle(context),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email Field
          Text(
            'Email address',
            style: _signupLabelStyle(context),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _signupFieldDecoration(
              context,
              hintText: 'Eg. JohnDoe@gmail.com',
            ),
            style: _signupFieldTextStyle(context),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Number Field
          Text(
            'Phone number',
            style: _signupLabelStyle(context),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _signupFieldDecoration(
              context,
              hintText: 'Eg. 0712345678',
            ),
            style: _signupFieldTextStyle(context),
            onChanged: (value) {
              _phoneNumber = value;
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          Text(
            'Password',
            style: _signupLabelStyle(context),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: _signupFieldDecoration(
              context,
              hintText: 'Enter password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: iconMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            style: _signupFieldTextStyle(context),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          Text(
            'Confirm Password',
            style: _signupLabelStyle(context),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: _signupFieldDecoration(
              context,
              hintText: 'Enter password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: iconMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            style: _signupFieldTextStyle(context),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Terms & Conditions Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: checkboxBodyStyle,
                      children: [
                        TextSpan(text: "I have read and accepted "),
                        TextSpan(
                          text: "Hudhud's Terms & Conditions",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Data Protection Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _dataProtectionAccepted,
                onChanged: (value) {
                  setState(() {
                    _dataProtectionAccepted = value ?? false;
                  });
                },
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: checkboxBodyStyle,
                      children: [
                        TextSpan(text: "I consent to the collection and processing of my personal data in accordance with the applicable "),
                        TextSpan(
                          text: "Data Protection",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: " laws."),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SignupButton extends StatelessWidget {
  const SignupButton({super.key});

  void _handleSignup(BuildContext context) {
    final formState = signupFormKey.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!formState.isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!formState.areCheckboxesAccepted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions and Data Protection consent'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formData = formState.getFormData();

    // Trigger signup event
    context.read<SignupBloc>().add(
          SignupFormSubmitted(
            '${formData.firstName} ${formData.lastName}',
            formData.email,
            formData.phoneNumber,
            formData.password,
            formData.password, // confirmPassword same as password
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to combined email + phone verification screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const VerifyContactScreen()),
            (route) => false,
          );
        } else if (state is SignupFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<SignupBloc, SignupState>(
        builder: (context, state) {
          final isLoading = state is SignupLoading;
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _handleSignup(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
