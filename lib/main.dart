import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/splash/presentation/screen/splash_screen.dart';
import 'package:provider/provider.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/api/api_service.dart';
import 'core/api/dio_client.dart';
import 'core/utils/snackbar_util.dart';
import 'core/utils/button_util.dart';

// Controllers
import 'controllers/theme_controller.dart';
import 'controllers/auth_controller.dart';

// Services
import 'app/services/auth_service.dart';
import 'app/services/fcm_service.dart';

// Orders feature
import 'features/orders/data/providers/orders_data_provider.dart';
import 'features/orders/data/repositories/orders_repository.dart';

// Widgets
import 'app/widgets/primary_button.dart';
import 'app/widgets/secondary_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FCM (non-blocking: app starts even if Firebase/FCM fails)
  FcmService? fcmService;
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    fcmService = await FcmService.initialize();
    fcmService.onNotificationTap = (message, {localPayload}) {
      // Handle notification tap: navigate to order/screen using message?.data or localPayload
    };
    fcmService.onTokenRefresh = (token) async {
      final authService = AuthService();
      if (await authService.isAuthenticated()) {
        await authService.sendFcmTokenToBackend();
      }
    };
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('FCM/Firebase init failed (app will run without push): $e');
      debugPrint('$st');
    }
  }

  // Initialize API service
  // DioClient.initialize(); // Will be implemented when needed

  // Initialize theme controller
  final themeController = ThemeController();
  await themeController.init();

  // Initialize auth service
  final authService = AuthService();

  // Register 401 redirect to login
  final navigatorKey = GlobalKey<NavigatorState>();
  DioClient.instance.setOnUnauthorized(() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  });

  // Initialize orders repository
  final ordersDataProvider =
      OrdersDataProvider(apiService: ApiService.instance);
  final ordersRepository =
      OrdersRepositoryImpl(dataProvider: ordersDataProvider);

  runApp(MyApp(
    themeController: themeController,
    authService: authService,
    ordersRepository: ordersRepository,
    navigatorKey: navigatorKey,
  ));
}

class MyApp extends StatefulWidget {
  final ThemeController themeController;
  final AuthService authService;
  final OrdersRepository ordersRepository;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    Key? key,
    required this.themeController,
    required this.authService,
    required this.ordersRepository,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeController),
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ),
        Provider<OrdersRepository>.value(value: widget.ordersRepository),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            navigatorKey: widget.navigatorKey,
            title: 'HudHud Delivery',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            home: SplashScreen(),
            builder: (context, child) {
              // Update system UI overlay style when theme changes
              themeController.updateSystemUIOverlayStyle();
              return child!;
            },
          );
        },
      ),
    );
  }
}

class SampleHomePage extends StatefulWidget {
  const SampleHomePage({Key? key}) : super(key: key);

  @override
  State<SampleHomePage> createState() => _SampleHomePageState();
}

class _SampleHomePageState extends State<SampleHomePage> {
  bool _isLoading = false;
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HudHud Delivery Demo'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeController.toggleTheme();
              SnackbarUtil.showInfo(
                context,
                'Theme switched to ${themeController.themeModeDisplayName}',
              );
            },
            tooltip: 'Toggle Theme',
          ),
          // Theme mode selector
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.palette),
            onSelected: (ThemeMode mode) {
              themeController.setThemeMode(mode);
              SnackbarUtil.showSuccess(
                context,
                'Theme mode set to ${themeController.themeModeDisplayName}',
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.auto_mode),
                    SizedBox(width: 8),
                    Text('System'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode),
                    SizedBox(width: 8),
                    Text('Light'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode),
                    SizedBox(width: 8),
                    Text('Dark'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to HudHud Delivery!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a demo showcasing the clean architecture with custom buttons, snackbars, and theme switching.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Current theme: ${themeController.themeModeDisplayName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Counter Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Counter Demo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_counter',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SecondaryButton(
                          text: 'Decrease',
                          icon: Icons.remove,
                          isFullWidth: false,
                          onPressed: () {
                            setState(() {
                              _counter--;
                            });
                            SnackbarUtil.showInfo(
                                context, 'Counter decreased to $_counter');
                          },
                        ),
                        PrimaryButton(
                          text: 'Increase',
                          icon: Icons.add,
                          isFullWidth: false,
                          onPressed: () {
                            setState(() {
                              _counter++;
                            });
                            SnackbarUtil.showSuccess(
                                context, 'Counter increased to $_counter');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Button Showcase
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Button Showcase',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Primary Buttons
                    PrimaryButton(
                      text: 'Primary Button',
                      onPressed: () => SnackbarUtil.showSuccess(
                          context, 'Primary button pressed!'),
                    ),
                    const SizedBox(height: 12),

                    PrimaryButtonLarge(
                      text: 'Large Primary Button',
                      icon: Icons.star,
                      onPressed: () => SnackbarUtil.showInfo(
                          context, 'Large primary button with icon pressed!'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButtonSmall(
                            text: 'Small',
                            isFullWidth: true,
                            onPressed: () => SnackbarUtil.showWarning(
                                context, 'Small button pressed!'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        PrimaryButtonIcon(
                          icon: Icons.favorite,
                          onPressed: () => SnackbarUtil.showError(
                              context, 'Icon button pressed!'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Secondary Buttons
                    SecondaryButton(
                      text: 'Secondary Button',
                      onPressed: () => SnackbarUtil.showInfo(
                          context, 'Secondary button pressed!'),
                    ),
                    const SizedBox(height: 12),

                    SecondaryButtonLarge(
                      text: 'Large Secondary Button',
                      icon: Icons.settings,
                      onPressed: () => SnackbarUtil.showSuccess(
                          context, 'Large secondary button pressed!'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButtonSmall(
                            text: 'Small Secondary',
                            isFullWidth: true,
                            onPressed: () => SnackbarUtil.showWarning(
                                context, 'Small secondary button pressed!'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GhostButton(
                            text: 'Ghost Button',
                            isFullWidth: true,
                            onPressed: () => SnackbarUtil.showInfo(
                                context, 'Ghost button pressed!'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Snackbar Showcase
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Snackbar Showcase',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => SnackbarUtil.showSuccess(
                            context,
                            'This is a success message!',
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () => SnackbarUtil.showInfo(
                                  context, 'Undo action pressed'),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Success'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => SnackbarUtil.showError(
                            context,
                            'This is an error message!',
                          ),
                          icon: const Icon(Icons.error),
                          label: const Text('Error'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => SnackbarUtil.showWarning(
                            context,
                            'This is a warning message!',
                          ),
                          icon: const Icon(Icons.warning),
                          label: const Text('Warning'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => SnackbarUtil.showInfo(
                            context,
                            'This is an info message!',
                          ),
                          icon: const Icon(Icons.info),
                          label: const Text('Info'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                SnackbarUtil.showLoading(
                                    context, 'Loading data...');
                                // Simulate loading
                                Future.delayed(const Duration(seconds: 3), () {
                                  SnackbarUtil.hideSnackbar(context);
                                  SnackbarUtil.showSuccess(
                                      context, 'Data loaded successfully!');
                                });
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Show Loading'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  SnackbarUtil.hideSnackbar(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Hide Snackbar'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // API Demo Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'API Demo',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (authController.isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      PrimaryButton(
                        text: 'Sample Login',
                        icon: Icons.login,
                        isLoading: _isLoading,
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            // Sample login call
                            await authController.login(
                              'demo@example.com',
                              'password123',
                            );

                            if (authController.currentUser != null) {
                              SnackbarUtil.showSuccess(
                                context,
                                'Login successful! Welcome ${authController.currentUser!.name}',
                              );
                            }
                          } catch (e) {
                            SnackbarUtil.showError(
                              context,
                              'Login failed: ${e.toString()}',
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        text: 'Get User Profile',
                        icon: Icons.person,
                        onPressed: authController.currentUser == null
                            ? null
                            : () async {
                                try {
                                  await authController.refreshUserProfile();
                                  SnackbarUtil.showSuccess(
                                    context,
                                    'Profile refreshed successfully!',
                                  );
                                } catch (e) {
                                  SnackbarUtil.showError(
                                    context,
                                    'Failed to refresh profile: ${e.toString()}',
                                  );
                                }
                              },
                      ),
                      if (authController.currentUser != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current User:',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text('Name: ${authController.currentUser!.name}'),
                              Text(
                                  'Email: ${authController.currentUser!.email}'),
                              Text(
                                  'Role: ${authController.currentUser!.permissions}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          text: 'Logout',
                          icon: Icons.logout,
                          onPressed: () async {
                            await authController.logout();
                            SnackbarUtil.showInfo(
                                context, 'Logged out successfully!');
                          },
                        ),
                      ],
                    ],
                    if (authController.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Error: ${authController.errorMessage}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Utility Buttons Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Utility Buttons Demo',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ButtonUtil.primaryButton(
                      text: 'Utility Primary Button',
                      onPressed: () => SnackbarUtil.showSuccess(
                          context, 'Utility primary button pressed!'),
                    ),
                    const SizedBox(height: 12),
                    ButtonUtil.secondaryButton(
                      text: 'Utility Secondary Button',
                      onPressed: () => SnackbarUtil.showInfo(
                          context, 'Utility secondary button pressed!'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ButtonUtil.textButton(
                              text: 'Text Button',
                              onPressed: () => SnackbarUtil.showWarning(
                                  context, 'Text button pressed!'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ButtonUtil.iconButton(
                          icon: Icons.share,
                          onPressed: () => SnackbarUtil.showInfo(
                              context, 'Share button pressed!'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ButtonUtil.gradientButton(
                      text: 'Gradient Button',
                      gradientColors: [Colors.purple, Colors.blue],
                      onPressed: () => SnackbarUtil.showSuccess(
                          context, 'Gradient button pressed!'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: ButtonUtil.floatingActionButton(
        icon: Icons.refresh,
        onPressed: () {
          setState(() {
            _counter = 0;
          });
          SnackbarUtil.showInfo(context, 'Counter reset!');
        },
      ),
    );
  }
}
