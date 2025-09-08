import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/signup_widget.dart';
import '../../bloc/signup_bloc.dart';
import '../../data/repository/signup_repository.dart';
import '../../data/data_provider/signup_data_provider.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupBloc(
          SignupRepository(
            SignupDataProvider(apiService: ApiService.instance),
          ),
        ),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration:  BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.secondaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Color(0xFF2C3E50)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // const SizedBox(height: 20),
                      const SignupTitle(),
                      const SizedBox(height: 20),
                      createSignupForm(),
                      const SizedBox(height: 20),
                      const SignupButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
