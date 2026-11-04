import 'dart:io';

import 'core/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/wishlist/bloc/wishlist_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hudhud_delivery/core/l10n/fallback_localizations.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/splash/presentation/screen/splash_screen.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/api/api_service.dart';
import 'core/theme/service_tab_palette.dart';
import 'app/config/app_env.dart';

// Controllers
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/service_accent_controller.dart';
import 'core/easy_mode/easy_mode_controller.dart';
import 'core/easy_mode/voice_hint_service.dart';
import 'features/growth/deep_link_service.dart';
import 'features/growth/growth_config_controller.dart';
import 'features/growth/market_controller.dart';

// Services
import 'app/services/client_error_reporter.dart';
import 'app/services/fcm_service.dart';
import 'app/services/auth_service.dart';
import 'app/services/remote_config_service.dart';
import 'app/navigation/app_navigator.dart';
import 'app/navigation/fcm_notification_router.dart';

// Orders feature
import 'features/orders/data/providers/orders_data_provider.dart';
import 'features/orders/data/repositories/orders_repository.dart';

// Widgets
import 'app/widgets/app_connectivity_banner.dart';
import 'app/widgets/ota_lifecycle_binder.dart';
import 'package:hudhud_delivery/features/wallet/services/wallet_topup_recovery_service.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// One instance for the app's lifetime (MaterialApp rebuilds keep it).
final ClientErrorRouteObserver _clientErrorRouteObserver =
    ClientErrorRouteObserver();

void _configureAndroidPhotoPicker() {
  if (!Platform.isAndroid) return;
  final impl = ImagePickerPlatform.instance;
  if (impl is ImagePickerAndroid) {
    impl.useAndroidPhotoPicker = true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Error/crash reports to POST /api/client-errors (release builds; debug
  // only with --dart-define=REPORT_ERRORS_IN_DEBUG=true). runZonedGuarded is
  // not used: main() awaits plugin init before runApp, and
  // PlatformDispatcher.onError already covers uncaught async errors.
  ClientErrorReporter.instance.install();
  _configureAndroidPhotoPicker();

  // Config is compile-time (--dart-define); kept as a no-op hook.
  await loadAppEnv();

  // Must exist before FCM tap handlers so they can push routes.
  final navigatorKey = GlobalKey<NavigatorState>();
  AppNavigator.key = navigatorKey;
  // App links (/r/{code}, /o/{id}); see DeepLinkService TODO.
  DeepLinkService.instance.start(navigatorKey);

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

  try {
    await WalletTopUpRecoveryService.instance.initialize();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Wallet top-up recovery init failed: $e');
      debugPrint('$st');
    }
  }

  // Initialize theme controller
  final themeController = ThemeController();
  await themeController.init();

  final localeController = LocaleController();
  await localeController.init();
  ClientErrorReporter.instance.localeProvider =
      () => localeController.locale.languageCode;

  final easyModeController = EasyModeController();
  await easyModeController.init();
  await VoiceHintService.instance.init(
    languageCode: localeController.locale.languageCode,
  );

  // Initialize auth service
  final authService = AuthService();

  // Register 401 redirect to login (skip if login is already showing).
  DioClient.instance.setOnUnauthorized(() {
    if (loginScreenIsActive) return;
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
    localeController: localeController,
    easyModeController: easyModeController,
    authService: authService,
    ordersRepository: ordersRepository,
    navigatorKey: navigatorKey,
  ));
}

class MyApp extends StatefulWidget {
  final ThemeController themeController;
  final LocaleController localeController;
  final EasyModeController easyModeController;
  final AuthService authService;
  final OrdersRepository ordersRepository;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    Key? key,
    required this.themeController,
    required this.localeController,
    required this.easyModeController,
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
        ChangeNotifierProvider.value(value: widget.easyModeController),
        ChangeNotifierProvider(create: (_) => ServiceAccentController()),
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ),
        // Phase 2 growth flags; everything stays hidden until this loads.
        ChangeNotifierProvider(
          create: (_) => GrowthConfigController()..start(),
          lazy: false,
        ),
        // Phase 3 markets; no market (= Addis/ETB, unchanged) until loaded.
        ChangeNotifierProvider(
          create: (_) => MarketController()..start(),
          lazy: false,
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
            VoiceHintService.instance.setLanguage(
              localeController.locale.languageCode,
            );
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
              navigatorObservers: [_clientErrorRouteObserver],
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              debugShowCheckedModeBanner: false,
              theme: themeLight,
              darkTheme: themeDark,
              themeMode: themeController.themeMode,
              locale: localeController.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                FallbackMaterialLocalizationsDelegate(),
                FallbackCupertinoLocalizationsDelegate(),
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              localeListResolutionCallback: (locales, supported) {
                final selected = localeController.locale;
                for (final locale in supported) {
                  if (locale.languageCode == selected.languageCode) {
                    return selected;
                  }
                }
                return const Locale('en');
              },
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

