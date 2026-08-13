import 'core/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/wishlist/bloc/wishlist_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/splash/presentation/screen/splash_screen.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/api/api_service.dart';
import 'core/theme/service_tab_palette.dart';

// Controllers
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/service_accent_controller.dart';

// Services
import 'app/services/fcm_service.dart';
import 'app/services/auth_service.dart';
import 'app/services/guest_browse_service.dart';
import 'app/services/remote_config_service.dart';
import 'app/navigation/app_navigator.dart';
import 'app/navigation/fcm_notification_router.dart';

// Orders feature
import 'features/orders/data/providers/orders_data_provider.dart';
import 'features/orders/data/repositories/orders_repository.dart';

// Widgets
import 'app/widgets/app_connectivity_banner.dart';
import 'app/widgets/ota_lifecycle_binder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must exist before FCM tap handlers so they can push routes.
  final navigatorKey = GlobalKey<NavigatorState>();
  AppNavigator.key = navigatorKey;

  // Initialize FCM (non-blocking: app starts even if Firebase/FCM fails)
  FcmService? fcmService;
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    fcmService = await FcmService.initialize();
    fcmService.onNotificationTap = (message, {localPayload}) {
      openNotificationFromFcm(
        navigatorKey,
        message: message,
        localPayload: localPayload,
      );
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

  // Remote Config (force-update + Shorebird kill switch). Fail-open.
  try {
    await RemoteConfigService.instance.initialize();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Remote Config init failed: $e');
      debugPrint('$st');
    }
  }

  // Initialize API service
  // DioClient.initialize(); // Will be implemented when needed

  // Initialize theme controller
  final themeController = ThemeController();
  await themeController.init();

  final localeController = LocaleController();
  await localeController.init();

  // Initialize auth service
  final authService = AuthService();

  // Register 401 redirect to home as guest (skip if login is already showing).
  DioClient.instance.setOnUnauthorized(() {
    if (loginScreenIsActive || GuestBrowseService().isGuestBrowseMode) return;
    GuestBrowseService().enterGuestBrowseMode().then((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    });
  });

  // Initialize orders repository
  final ordersDataProvider =
      OrdersDataProvider(apiService: ApiService.instance);
  final ordersRepository =
      OrdersRepositoryImpl(dataProvider: ordersDataProvider);

  runApp(MyApp(
    themeController: themeController,
    localeController: localeController,
    authService: authService,
    ordersRepository: ordersRepository,
    navigatorKey: navigatorKey,
  ));
}

class MyApp extends StatefulWidget {
  final ThemeController themeController;
  final LocaleController localeController;
  final AuthService authService;
  final OrdersRepository ordersRepository;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    Key? key,
    required this.themeController,
    required this.localeController,
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
        ChangeNotifierProvider.value(value: widget.localeController),
        ChangeNotifierProvider(create: (_) => ServiceAccentController()),
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ),
        Provider<OrdersRepository>.value(value: widget.ordersRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WishlistBloc>(
            create: (_) => WishlistBloc(),
          ),
        ],
        child: Consumer3<ThemeController, LocaleController,
            ServiceAccentController>(
          builder: (context, themeController, localeController,
              serviceAccent, child) {
            final seed =
                ServiceTabPalette.seedFor(serviceAccent.homeServiceMode);
            final themeLight = serviceAccent.shouldApplyServiceAccent
                ? AppTheme.lightThemeWithSeed(seed)
                : AppTheme.lightTheme;
            final themeDark = serviceAccent.shouldApplyServiceAccent
                ? AppTheme.darkThemeWithSeed(seed)
                : AppTheme.darkTheme;
            return MaterialApp(
              navigatorKey: widget.navigatorKey,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              debugShowCheckedModeBanner: false,
              theme: themeLight,
              darkTheme: themeDark,
              themeMode: themeController.themeMode,
              locale: localeController.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SplashScreen(),
              builder: (context, child) {
                // Update system UI overlay style when theme changes
                themeController.updateSystemUIOverlayStyle();
                return OtaLifecycleBinder(
                  child: AppConnectivityBanner(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

