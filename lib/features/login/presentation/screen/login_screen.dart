import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/login/bloc/login_bloc.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/features/login/data/repository/login_repository.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_brand_header.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_widget.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/auth_screen_presence.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_navigation.dart';

class LoginScreen extends StatefulWidget {
  /// When true, successful auth pops back to the caller instead of opening dashboard.
  final bool resumeAfterAuth;

  const LoginScreen({Key? key, this.resumeAfterAuth = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();
    authScreenMounted();
    _loginBloc = LoginBloc(
      LoginRepository(LoginDataProvider(apiService: ApiService.instance)),
    );
  }

  @override
  void dispose() {
    authScreenUnmounted();
    _loginBloc.close();
    super.dispose();
  }




  Future<void> _navigateAfterSuccess({
    required bool phoneEnrollmentRequired,
  }) async {
    if (!mounted) return;
    await navigateAfterAuthenticatedLogin(
      context,
      phoneEnrollmentRequired: phoneEnrollmentRequired,
      resumeAfterAuth: widget.resumeAfterAuth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _loginBloc,
      child: PopScope(
        // Always pushed from AuthEntryScreen now, so back simply returns
        // there; the "exit app?" confirmation moved with the root.
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {},
        child: BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) =>
              current is LoginSuccess || current is LoginFailure,
          listener: (context, state) async {
            if (state is LoginSuccess) {
              await _navigateAfterSuccess(
                phoneEnrollmentRequired: state.phoneEnrollmentRequired,
              );
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: AuthDarkScaffold(
            // Always reachable from the phone screen, so always escapable.
            showBackButton: true,
            child: Builder(
              builder: (context) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthBrandHeader(height: 40),
                    const SizedBox(height: 32),
                    const LoginTitle(),
                    const SizedBox(height: 28),
                    const LoginForm(),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

