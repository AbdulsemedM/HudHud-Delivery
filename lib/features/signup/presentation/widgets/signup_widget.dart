import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/widgets/primary_button.dart';
import '../../../dashboard/presentation/screen/dashboard_screen.dart';
import '../../bloc/signup_bloc.dart';

class SignupTitle extends StatelessWidget {
  const SignupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'Excited to see you',
        //   style: TextStyle(
        //     fontSize: 16,
        //     color: Color(0xFF7F8C8D),
        //   ),
        // ),
        // const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a New Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.only(top: 4),
            //   child: const Text(
            //     'Account',
            //     style: TextStyle(
            //       fontSize: 28,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.black,
            //       decoration: TextDecoration.underline,
            //       decorationThickness: 2,
            //     ),
            //   ),
            // ),
          ],
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
      phoneNumber: _phoneController.text.trim(),
    );
  }

  bool isFormValid() {
    return _formKey.currentState?.validate() ?? false;
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone Number Field
          const Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: '987654321',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              final formatted = validateAndFormatPhoneNumber(value);
              if (formatted == null) {
                return 'Please enter a valid Ethiopian phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // First Name Field
          const Text(
            'First Name',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _firstNameController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Abdu',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'First name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Last Name Field
          const Text(
            'Last Name',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Musa',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Last name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email Field
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'abdu.musa@example.com',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          const Text(
            'Your Password',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: '********',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          const Text(
            'Confirm Password',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: '********',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
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
          // Navigate to dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
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
      child: Column(
        children: [
          BlocBuilder<SignupBloc, SignupState>(
            builder: (context, state) {
              final isLoading = state is SignupLoading;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: PrimaryButton(
                  text: 'Signup Now',
                  onPressed: isLoading ? null : () => _handleSignup(context),
                  isLoading: isLoading,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Have an Account? ',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Login Instead',
                  style: TextStyle(
                    color: Color(0xFF6C3EE9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
