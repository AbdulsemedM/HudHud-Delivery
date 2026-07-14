import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';
import 'app_localizations_so.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('ar'),
    Locale('en'),
    Locale('om'),
    Locale('so')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HudHud Delivery'**
  String get appTitle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get actionVerify;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionResend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get actionResend;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get actionUndo;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get actionOpenSettings;

  /// No description provided for @actionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get actionViewAll;

  /// No description provided for @actionTrackDelivery.
  ///
  /// In en, this message translates to:
  /// **'Track delivery'**
  String get actionTrackDelivery;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get actionAddToCart;

  /// No description provided for @actionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'see all'**
  String get actionSeeAll;

  /// No description provided for @actionSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get actionSending;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get actionSignIn;

  /// No description provided for @actionLogOut.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get actionLogOut;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get navCourier;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get navTaxi;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get navOrderHistory;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get settingsContactEmail;

  /// No description provided for @offlineNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineNoConnection;

  /// No description provided for @orderIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Order ID copied'**
  String get orderIdCopied;

  /// No description provided for @orderShareSubject.
  ///
  /// In en, this message translates to:
  /// **'HudHud order'**
  String get orderShareSubject;

  /// No description provided for @settingsPersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get settingsPersonalDetails;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @appearanceChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred theme'**
  String get appearanceChooseTheme;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsBiometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric login'**
  String get settingsBiometricLogin;

  /// No description provided for @settingsBiometricLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in quickly with fingerprint or Face ID on this device'**
  String get settingsBiometricLoginSubtitle;

  /// No description provided for @biometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to continue'**
  String get biometricAuthReason;

  /// No description provided for @biometricEnableEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to enable biometric login'**
  String get biometricEnableEnterPassword;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric login is not available on this device'**
  String get biometricNotAvailable;

  /// No description provided for @biometricNoCredentials.
  ///
  /// In en, this message translates to:
  /// **'No saved login found. Sign in with your password first.'**
  String get biometricNoCredentials;

  /// No description provided for @biometricLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in failed. Try again or use your password.'**
  String get biometricLoginFailed;

  /// No description provided for @biometricEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled'**
  String get biometricEnabledSuccess;

  /// No description provided for @biometricDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get biometricDisabledSuccess;

  /// No description provided for @loginBiometricButtonSemantics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with biometrics'**
  String get loginBiometricButtonSemantics;

  /// No description provided for @loginBiometricOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or sign in with biometrics'**
  String get loginBiometricOrDivider;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsSmsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get settingsSmsNotifications;

  /// No description provided for @settingsWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get settingsWishlist;

  /// No description provided for @wishlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved items yet'**
  String get wishlistEmptyTitle;

  /// No description provided for @wishlistEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save products you love — tap the heart on a product to add it here.'**
  String get wishlistEmptySubtitle;

  /// No description provided for @wishlistAddedSnack.
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get wishlistAddedSnack;

  /// No description provided for @wishlistRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get wishlistRemovedSnack;

  /// No description provided for @wishlistSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use your wishlist'**
  String get wishlistSignInTitle;

  /// No description provided for @wishlistSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved items are stored on this device when you are logged in.'**
  String get wishlistSignInSubtitle;

  /// No description provided for @wishlistLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load wishlist'**
  String get wishlistLoadError;

  /// No description provided for @wishlistTooltipAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to wishlist'**
  String get wishlistTooltipAdd;

  /// No description provided for @wishlistTooltipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from wishlist'**
  String get wishlistTooltipRemove;

  /// No description provided for @settingsTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settingsTermsConditions;

  /// No description provided for @settingsFaqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get settingsFaqs;

  /// No description provided for @settingsHelpDesk.
  ///
  /// In en, this message translates to:
  /// **'Help Desk'**
  String get settingsHelpDesk;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0'**
  String get settingsVersion;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileCoupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get profileCoupons;

  /// No description provided for @profileWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get profileWallet;

  /// No description provided for @profileMenuProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileMenuProfile;

  /// No description provided for @profileMenuAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get profileMenuAddresses;

  /// No description provided for @profileMenuFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileMenuFavorites;

  /// No description provided for @profileMenuMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get profileMenuMessages;

  /// No description provided for @profileMenuAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get profileMenuAccountSettings;

  /// No description provided for @settingsGeneralPreferences.
  ///
  /// In en, this message translates to:
  /// **'General Preferences'**
  String get settingsGeneralPreferences;

  /// No description provided for @settingsDeliveryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Delivery Preferences'**
  String get settingsDeliveryPreferences;

  /// No description provided for @settingsAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsAppSettings;

  /// No description provided for @profileCouponsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coupons are not available yet.'**
  String get profileCouponsComingSoon;

  /// No description provided for @profileTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get profileTermsOfUse;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} HudHud Delivery. All Rights Reserved.'**
  String profileCopyright(String year);

  /// No description provided for @profileVersionFormatted.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (Build {buildNumber})'**
  String profileVersionFormatted(String version, String buildNumber);

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutMessage;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Error during logout: {error}'**
  String logoutError(String error);

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSubtitleLight.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeSubtitleLight;

  /// No description provided for @themeSubtitleDark.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeSubtitleDark;

  /// No description provided for @themeSubtitleSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow device theme'**
  String get themeSubtitleSystem;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAmharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ (Amharic)'**
  String get languageAmharic;

  /// No description provided for @languageOromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromo'**
  String get languageOromo;

  /// No description provided for @languageSomali.
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get languageSomali;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية (Arabic)'**
  String get languageArabic;

  /// No description provided for @greetingGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingGoodMorning;

  /// No description provided for @greetingGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingGoodAfternoon;

  /// No description provided for @greetingGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingGoodEvening;

  /// No description provided for @greetingGoodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get greetingGoodNight;

  /// No description provided for @userDefault.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userDefault;

  /// No description provided for @emDash.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get emDash;

  /// No description provided for @locationGetting.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get locationGetting;

  /// No description provided for @locationAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied'**
  String get locationAccessDenied;

  /// No description provided for @locationDisabledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Location access is disabled. Enable it in Settings to see your position.'**
  String get locationDisabledSnackbar;

  /// No description provided for @locationUnable.
  ///
  /// In en, this message translates to:
  /// **'Unable to get location'**
  String get locationUnable;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @selectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocationTitle;

  /// No description provided for @refreshLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh current location'**
  String get refreshLocationTooltip;

  /// No description provided for @searchPlacesHint.
  ///
  /// In en, this message translates to:
  /// **'Search for places...'**
  String get searchPlacesHint;

  /// No description provided for @searchLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a location...'**
  String get searchLocationHint;

  /// No description provided for @locationSearchScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get locationSearchScreenTitle;

  /// No description provided for @locationSelectedHeading.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get locationSelectedHeading;

  /// No description provided for @locationCoordinatesFormat.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {lat}, {lng}'**
  String locationCoordinatesFormat(String lat, String lng);

  /// No description provided for @locationConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get locationConfirmButton;

  /// No description provided for @locationSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No locations found'**
  String get locationSearchNoResults;

  /// No description provided for @locationCurrentPositionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get current location'**
  String get locationCurrentPositionFailed;

  /// No description provided for @currentLocationMap.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocationMap;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get verificationStatus;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @verifyEmailDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailDialogTitle;

  /// No description provided for @verifyPhoneDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhoneDialogTitle;

  /// No description provided for @verificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCodeLabel;

  /// No description provided for @verificationCodeHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 111248'**
  String get verificationCodeHintExample;

  /// No description provided for @verificationCodeHintSms.
  ///
  /// In en, this message translates to:
  /// **'e.g. 056869'**
  String get verificationCodeHintSms;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to {email}. Enter it below.'**
  String verifyEmailBody(String email);

  /// No description provided for @verifyPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to {phone}. Enter it below.'**
  String verifyPhoneBody(String phone);

  /// No description provided for @enterVerificationCodeError.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get enterVerificationCodeError;

  /// No description provided for @codeSentEmailDefault.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your email.'**
  String get codeSentEmailDefault;

  /// No description provided for @codeSentPhoneDefault.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your phone.'**
  String get codeSentPhoneDefault;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccess;

  /// No description provided for @phoneVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified successfully!'**
  String get phoneVerifiedSuccess;

  /// No description provided for @accountVerificationBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get accountVerificationBannerTitle;

  /// No description provided for @accountVerificationEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email for receipts and updates.'**
  String get accountVerificationEmailSubtitle;

  /// No description provided for @accountVerificationPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone for security and support.'**
  String get accountVerificationPhoneSubtitle;

  /// No description provided for @failedToLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders: {error}'**
  String failedToLoadOrders(String error);

  /// No description provided for @homeWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get homeWhatToDo;

  /// No description provided for @homeFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get homeFood;

  /// No description provided for @homeFoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order groceries from your favourite vendors.'**
  String get homeFoodSubtitle;

  /// No description provided for @homeCourierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order courier services for pickup and drop off.'**
  String get homeCourierSubtitle;

  /// No description provided for @homeTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get homeTaxi;

  /// No description provided for @homeTaxiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request taxi at affordable rates from anywhere.'**
  String get homeTaxiSubtitle;

  /// No description provided for @homeHandyman.
  ///
  /// In en, this message translates to:
  /// **'Handyman'**
  String get homeHandyman;

  /// No description provided for @homeHandymanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request handy men for casual services at home.'**
  String get homeHandymanSubtitle;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @featuresSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'What you can do with HudHud'**
  String get featuresSectionTitle;

  /// No description provided for @featureFoodGroceries.
  ///
  /// In en, this message translates to:
  /// **'Food & groceries'**
  String get featureFoodGroceries;

  /// No description provided for @featureFoodGroceriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Order from your favourite vendors.'**
  String get featureFoodGroceriesDesc;

  /// No description provided for @featureCourierTitle.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get featureCourierTitle;

  /// No description provided for @featureCourierDesc.
  ///
  /// In en, this message translates to:
  /// **'Pickup and drop-off.'**
  String get featureCourierDesc;

  /// No description provided for @featureTaxiTitle.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get featureTaxiTitle;

  /// No description provided for @featureTaxiDesc.
  ///
  /// In en, this message translates to:
  /// **'Request a ride anywhere.'**
  String get featureTaxiDesc;

  /// No description provided for @featureHandymanTitle.
  ///
  /// In en, this message translates to:
  /// **'Handyman'**
  String get featureHandymanTitle;

  /// No description provided for @featureHandymanDesc.
  ///
  /// In en, this message translates to:
  /// **'Home services on demand.'**
  String get featureHandymanDesc;

  /// No description provided for @featureTrackOrders.
  ///
  /// In en, this message translates to:
  /// **'Track orders'**
  String get featureTrackOrders;

  /// No description provided for @featureTrackOrdersDesc.
  ///
  /// In en, this message translates to:
  /// **'Real-time delivery status.'**
  String get featureTrackOrdersDesc;

  /// No description provided for @courierWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get courierWhatToDo;

  /// No description provided for @courierActiveDelivery.
  ///
  /// In en, this message translates to:
  /// **'Active Delivery'**
  String get courierActiveDelivery;

  /// No description provided for @courierNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No delivery history'**
  String get courierNoHistory;

  /// No description provided for @courierHistoryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your past deliveries will appear here'**
  String get courierHistoryEmptySubtitle;

  /// No description provided for @courierInstantTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Delivery'**
  String get courierInstantTitle;

  /// No description provided for @courierInstantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Courier takes only your package and delivers instantly.'**
  String get courierInstantSubtitle;

  /// No description provided for @courierScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Delivery'**
  String get courierScheduleTitle;

  /// No description provided for @courierScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Courier comes to pick up on your specified date and time.'**
  String get courierScheduleSubtitle;

  /// No description provided for @failedToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get failedToLoadHistory;

  /// No description provided for @recipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient: {name}'**
  String recipientLabel(String name);

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to track your orders and get your next delivery moving.'**
  String get loginSubtitle;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY, DELIVERED WELL'**
  String get brandTagline;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'YOUR CITY, DELIVERED'**
  String get splashTagline;

  /// No description provided for @splashStatus.
  ///
  /// In en, this message translates to:
  /// **'Getting things moving…'**
  String get splashStatus;

  /// No description provided for @loginContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get loginContinueAsGuest;

  /// No description provided for @labelEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email address or Phone number'**
  String get labelEmailOrPhone;

  /// No description provided for @loginTabEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginTabEmail;

  /// No description provided for @loginTabPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get loginTabPhone;

  /// No description provided for @loginTabEmailSemantics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get loginTabEmailSemantics;

  /// No description provided for @loginTabPhoneSemantics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with phone'**
  String get loginTabPhoneSemantics;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'Eg. JohnDoe@gmail.com'**
  String get hintEmail;

  /// No description provided for @hintPhoneNational.
  ///
  /// In en, this message translates to:
  /// **'912 345 678'**
  String get hintPhoneNational;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get validationPhoneInvalid;

  /// No description provided for @hintEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'Eg. JohnDoe@gmail.com'**
  String get hintEmailPhone;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get hintPassword;

  /// No description provided for @validationEmailOrPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or phone number'**
  String get validationEmailOrPhoneRequired;

  /// No description provided for @validationEmailOrPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email or phone number'**
  String get validationEmailOrPhoneInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordMin;

  /// No description provided for @validationPasswordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must include uppercase, lowercase, a number, and a special character'**
  String get validationPasswordComplexity;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @mainDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'HudHud Delivery Demo'**
  String get mainDemoTitle;

  /// No description provided for @toggleThemeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggleThemeTooltip;

  /// No description provided for @themeSwitched.
  ///
  /// In en, this message translates to:
  /// **'Theme switched to {mode}'**
  String themeSwitched(String mode);

  /// No description provided for @themeModeSet.
  ///
  /// In en, this message translates to:
  /// **'Theme mode set to {mode}'**
  String themeModeSet(String mode);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'This is a demo showcasing the clean architecture with custom buttons, snackbars, and theme switching.'**
  String get welcomeBody;

  /// No description provided for @currentThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Current theme: {mode}'**
  String currentThemeLabel(String mode);

  /// No description provided for @counterDemo.
  ///
  /// In en, this message translates to:
  /// **'Counter Demo'**
  String get counterDemo;

  /// No description provided for @counterDecreased.
  ///
  /// In en, this message translates to:
  /// **'Counter decreased to {count}'**
  String counterDecreased(int count);

  /// No description provided for @counterIncreased.
  ///
  /// In en, this message translates to:
  /// **'Counter increased to {count}'**
  String counterIncreased(int count);

  /// No description provided for @buttonShowcase.
  ///
  /// In en, this message translates to:
  /// **'Button Showcase'**
  String get buttonShowcase;

  /// No description provided for @primaryButton.
  ///
  /// In en, this message translates to:
  /// **'Primary Button'**
  String get primaryButton;

  /// No description provided for @primaryButtonPressed.
  ///
  /// In en, this message translates to:
  /// **'Primary button pressed!'**
  String get primaryButtonPressed;

  /// No description provided for @largePrimaryButton.
  ///
  /// In en, this message translates to:
  /// **'Large Primary Button'**
  String get largePrimaryButton;

  /// No description provided for @largePrimaryPressed.
  ///
  /// In en, this message translates to:
  /// **'Large primary button with icon pressed!'**
  String get largePrimaryPressed;

  /// No description provided for @smallButton.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get smallButton;

  /// No description provided for @smallButtonPressed.
  ///
  /// In en, this message translates to:
  /// **'Small button pressed!'**
  String get smallButtonPressed;

  /// No description provided for @iconButtonPressed.
  ///
  /// In en, this message translates to:
  /// **'Icon button pressed!'**
  String get iconButtonPressed;

  /// No description provided for @secondaryButton.
  ///
  /// In en, this message translates to:
  /// **'Secondary Button'**
  String get secondaryButton;

  /// No description provided for @secondaryPressed.
  ///
  /// In en, this message translates to:
  /// **'Secondary button pressed!'**
  String get secondaryPressed;

  /// No description provided for @largeSecondaryButton.
  ///
  /// In en, this message translates to:
  /// **'Large Secondary Button'**
  String get largeSecondaryButton;

  /// No description provided for @largeSecondaryPressed.
  ///
  /// In en, this message translates to:
  /// **'Large secondary button pressed!'**
  String get largeSecondaryPressed;

  /// No description provided for @smallSecondary.
  ///
  /// In en, this message translates to:
  /// **'Small Secondary'**
  String get smallSecondary;

  /// No description provided for @smallSecondaryPressed.
  ///
  /// In en, this message translates to:
  /// **'Small secondary button pressed!'**
  String get smallSecondaryPressed;

  /// No description provided for @ghostButton.
  ///
  /// In en, this message translates to:
  /// **'Ghost Button'**
  String get ghostButton;

  /// No description provided for @ghostPressed.
  ///
  /// In en, this message translates to:
  /// **'Ghost button pressed!'**
  String get ghostPressed;

  /// No description provided for @snackbarShowcase.
  ///
  /// In en, this message translates to:
  /// **'Snackbar Showcase'**
  String get snackbarShowcase;

  /// No description provided for @snackbarSuccess.
  ///
  /// In en, this message translates to:
  /// **'This is a success message!'**
  String get snackbarSuccess;

  /// No description provided for @snackbarSuccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get snackbarSuccessLabel;

  /// No description provided for @snackbarError.
  ///
  /// In en, this message translates to:
  /// **'This is an error message!'**
  String get snackbarError;

  /// No description provided for @snackbarErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get snackbarErrorLabel;

  /// No description provided for @snackbarWarning.
  ///
  /// In en, this message translates to:
  /// **'This is a warning message!'**
  String get snackbarWarning;

  /// No description provided for @snackbarWarningLabel.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get snackbarWarningLabel;

  /// No description provided for @snackbarInfo.
  ///
  /// In en, this message translates to:
  /// **'This is an info message!'**
  String get snackbarInfo;

  /// No description provided for @snackbarInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get snackbarInfoLabel;

  /// No description provided for @undoActionPressed.
  ///
  /// In en, this message translates to:
  /// **'Undo action pressed'**
  String get undoActionPressed;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @showLoadingButton.
  ///
  /// In en, this message translates to:
  /// **'Show Loading'**
  String get showLoadingButton;

  /// No description provided for @dataLoadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data loaded successfully!'**
  String get dataLoadedSuccess;

  /// No description provided for @hideSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Hide Snackbar'**
  String get hideSnackbar;

  /// No description provided for @apiDemo.
  ///
  /// In en, this message translates to:
  /// **'API Demo'**
  String get apiDemo;

  /// No description provided for @sampleLogin.
  ///
  /// In en, this message translates to:
  /// **'Sample Login'**
  String get sampleLogin;

  /// No description provided for @loginSuccessWelcome.
  ///
  /// In en, this message translates to:
  /// **'Login successful! Welcome {name}'**
  String loginSuccessWelcome(String name);

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @getUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Get User Profile'**
  String get getUserProfile;

  /// No description provided for @profileRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Profile refreshed successfully!'**
  String get profileRefreshed;

  /// No description provided for @profileRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh profile: {error}'**
  String profileRefreshFailed(String error);

  /// No description provided for @currentUser.
  ///
  /// In en, this message translates to:
  /// **'Current User:'**
  String get currentUser;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get emailLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get roleLabel;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully!'**
  String get logoutSuccess;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @utilityButtonsDemo.
  ///
  /// In en, this message translates to:
  /// **'Utility Buttons Demo'**
  String get utilityButtonsDemo;

  /// No description provided for @utilityPrimary.
  ///
  /// In en, this message translates to:
  /// **'Utility Primary Button'**
  String get utilityPrimary;

  /// No description provided for @utilityPrimaryPressed.
  ///
  /// In en, this message translates to:
  /// **'Utility primary button pressed!'**
  String get utilityPrimaryPressed;

  /// No description provided for @utilitySecondary.
  ///
  /// In en, this message translates to:
  /// **'Utility Secondary Button'**
  String get utilitySecondary;

  /// No description provided for @utilitySecondaryPressed.
  ///
  /// In en, this message translates to:
  /// **'Utility secondary button pressed!'**
  String get utilitySecondaryPressed;

  /// No description provided for @textButton.
  ///
  /// In en, this message translates to:
  /// **'Text Button'**
  String get textButton;

  /// No description provided for @textButtonPressed.
  ///
  /// In en, this message translates to:
  /// **'Text button pressed!'**
  String get textButtonPressed;

  /// No description provided for @sharePressed.
  ///
  /// In en, this message translates to:
  /// **'Share button pressed!'**
  String get sharePressed;

  /// No description provided for @gradientButton.
  ///
  /// In en, this message translates to:
  /// **'Gradient Button'**
  String get gradientButton;

  /// No description provided for @gradientPressed.
  ///
  /// In en, this message translates to:
  /// **'Gradient button pressed!'**
  String get gradientPressed;

  /// No description provided for @counterReset.
  ///
  /// In en, this message translates to:
  /// **'Counter reset!'**
  String get counterReset;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderStatusPreparing;

  /// No description provided for @orderStatusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get orderStatusReadyForPickup;

  /// No description provided for @orderStatusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get orderStatusOutForDelivery;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusTextPending.
  ///
  /// In en, this message translates to:
  /// **'Order Pending'**
  String get orderStatusTextPending;

  /// No description provided for @orderStatusTextAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order Accepted'**
  String get orderStatusTextAccepted;

  /// No description provided for @orderStatusTextPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing Order'**
  String get orderStatusTextPreparing;

  /// No description provided for @orderStatusTextReadyPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get orderStatusTextReadyPickup;

  /// No description provided for @orderStatusTextPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Order Picked Up'**
  String get orderStatusTextPickedUp;

  /// No description provided for @orderStatusTextDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order Delivered'**
  String get orderStatusTextDelivered;

  /// No description provided for @orderStatusTextCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order Cancelled'**
  String get orderStatusTextCancelled;

  /// No description provided for @paymentCashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get paymentCashOnDelivery;

  /// No description provided for @paymentPaidOnline.
  ///
  /// In en, this message translates to:
  /// **'Paid Online'**
  String get paymentPaidOnline;

  /// No description provided for @estimatedDeliveryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'30-45 mins'**
  String get estimatedDeliveryPlaceholder;

  /// No description provided for @searchRestaurantsHint.
  ///
  /// In en, this message translates to:
  /// **'Search restaurants by name'**
  String get searchRestaurantsHint;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Promo Code'**
  String get enterPromoCode;

  /// No description provided for @additionalNote.
  ///
  /// In en, this message translates to:
  /// **'Additional note'**
  String get additionalNote;

  /// No description provided for @enterCustomTip.
  ///
  /// In en, this message translates to:
  /// **'Enter custom tip amount'**
  String get enterCustomTip;

  /// No description provided for @hintFirstName.
  ///
  /// In en, this message translates to:
  /// **'John'**
  String get hintFirstName;

  /// No description provided for @hintLastName.
  ///
  /// In en, this message translates to:
  /// **'Doe'**
  String get hintLastName;

  /// No description provided for @hintEmailExample.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get hintEmailExample;

  /// No description provided for @hintPhoneExample.
  ///
  /// In en, this message translates to:
  /// **'912 345 678'**
  String get hintPhoneExample;

  /// No description provided for @hintEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get hintEnterPassword;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @dropOff.
  ///
  /// In en, this message translates to:
  /// **'Drop off'**
  String get dropOff;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @transactionIdHint.
  ///
  /// In en, this message translates to:
  /// **'From payment gateway'**
  String get transactionIdHint;

  /// No description provided for @cardLast4.
  ///
  /// In en, this message translates to:
  /// **'Card last 4 digits'**
  String get cardLast4;

  /// No description provided for @cardLast4Hint.
  ///
  /// In en, this message translates to:
  /// **'4242'**
  String get cardLast4Hint;

  /// No description provided for @cardBrand.
  ///
  /// In en, this message translates to:
  /// **'Card brand'**
  String get cardBrand;

  /// No description provided for @cardBrandHint.
  ///
  /// In en, this message translates to:
  /// **'visa, mastercard'**
  String get cardBrandHint;

  /// No description provided for @addFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get addFundsTitle;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select a payment method'**
  String get selectPaymentMethod;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @categoryGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get categoryGrocery;

  /// No description provided for @categoryAmerican.
  ///
  /// In en, this message translates to:
  /// **'American'**
  String get categoryAmerican;

  /// No description provided for @categoryConvenience.
  ///
  /// In en, this message translates to:
  /// **'Convenience'**
  String get categoryConvenience;

  /// No description provided for @categoryAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get categoryAlcohol;

  /// No description provided for @categoryPetSupplies.
  ///
  /// In en, this message translates to:
  /// **'Pet Supplies'**
  String get categoryPetSupplies;

  /// No description provided for @categoryMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get categoryMore;

  /// No description provided for @pickupLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocationLabel;

  /// No description provided for @deliveryLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocationLabel;

  /// No description provided for @vehicleMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get vehicleMotorcycle;

  /// No description provided for @vehicleCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get vehicleCar;

  /// No description provided for @vehicleVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleVan;

  /// No description provided for @fromWallet.
  ///
  /// In en, this message translates to:
  /// **'From Wallet'**
  String get fromWallet;

  /// No description provided for @enterWithdrawAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount to withdraw'**
  String get enterWithdrawAmount;

  /// No description provided for @withdrawalMethod.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Method'**
  String get withdrawalMethod;

  /// No description provided for @requestTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get requestTitle;

  /// No description provided for @requestTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fix leaking faucet'**
  String get requestTitleHint;

  /// No description provided for @requestDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get requestDescription;

  /// No description provided for @requestDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the repair or maintenance needed'**
  String get requestDescriptionHint;

  /// No description provided for @requestLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get requestLocation;

  /// No description provided for @requestLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to select location'**
  String get requestLocationHint;

  /// No description provided for @scheduledDateTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Date & Time'**
  String get scheduledDateTime;

  /// No description provided for @estimatedCostOptional.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost (optional)'**
  String get estimatedCostOptional;

  /// No description provided for @estimatedCostHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100'**
  String get estimatedCostHint;

  /// No description provided for @toolsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Tools needed (comma-separated)'**
  String get toolsNeeded;

  /// No description provided for @toolsNeededHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. wrench set, plumber\'s tape'**
  String get toolsNeededHint;

  /// No description provided for @estimatedHoursOptional.
  ///
  /// In en, this message translates to:
  /// **'Estimated hours (optional)'**
  String get estimatedHoursOptional;

  /// No description provided for @estimatedHoursHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2'**
  String get estimatedHoursHint;

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// No description provided for @commentExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get commentExperienceHint;

  /// No description provided for @commentHandymanHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Very professional and courteous'**
  String get commentHandymanHint;

  /// No description provided for @whatSending.
  ///
  /// In en, this message translates to:
  /// **'What you are sending'**
  String get whatSending;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @recipientContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Recipient contact number'**
  String get recipientContactNumber;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @commentsIfAny.
  ///
  /// In en, this message translates to:
  /// **'Your Comments if any....'**
  String get commentsIfAny;

  /// No description provided for @walletNotFound.
  ///
  /// In en, this message translates to:
  /// **'Wallet not found'**
  String get walletNotFound;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @packageWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Package Weight (kg)'**
  String get packageWeightKg;

  /// No description provided for @packageDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Package Description (optional)'**
  String get packageDescriptionOptional;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @recipientNames.
  ///
  /// In en, this message translates to:
  /// **'Recipient Names'**
  String get recipientNames;

  /// No description provided for @imagePickerTodo.
  ///
  /// In en, this message translates to:
  /// **'Image picker will be implemented'**
  String get imagePickerTodo;

  /// No description provided for @pleaseSelectItemType.
  ///
  /// In en, this message translates to:
  /// **'Please select item type'**
  String get pleaseSelectItemType;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @pleaseEnterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid package weight (kg)'**
  String get pleaseEnterValidWeight;

  /// No description provided for @pleaseSelectPaymentType.
  ///
  /// In en, this message translates to:
  /// **'Please select payment type'**
  String get pleaseSelectPaymentType;

  /// No description provided for @pleaseEnterRecipientName.
  ///
  /// In en, this message translates to:
  /// **'Please enter recipient name'**
  String get pleaseEnterRecipientName;

  /// No description provided for @pleaseEnterRecipientPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter recipient phone number'**
  String get pleaseEnterRecipientPhone;

  /// No description provided for @walletDetailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get walletDetailName;

  /// No description provided for @walletDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get walletDetailType;

  /// No description provided for @walletDetailScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Details'**
  String get walletDetailScreenTitle;

  /// No description provided for @walletInformation.
  ///
  /// In en, this message translates to:
  /// **'Wallet Information'**
  String get walletInformation;

  /// No description provided for @walletDetailCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get walletDetailCurrencyLabel;

  /// No description provided for @walletMyBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'My balance'**
  String get walletMyBalanceLabel;

  /// No description provided for @walletMyWalletsSection.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get walletMyWalletsSection;

  /// No description provided for @walletRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get walletRecentTransactions;

  /// No description provided for @walletSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get walletSeeAll;

  /// No description provided for @walletNoTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get walletNoTransactionsYet;

  /// No description provided for @walletAddMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get walletAddMoney;

  /// No description provided for @walletSendMoney.
  ///
  /// In en, this message translates to:
  /// **'Send Money'**
  String get walletSendMoney;

  /// No description provided for @withdrawFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawFundsTitle;

  /// No description provided for @walletNoWalletsForWithdraw.
  ///
  /// In en, this message translates to:
  /// **'No wallets available to withdraw from'**
  String get walletNoWalletsForWithdraw;

  /// No description provided for @walletNoPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'No payment methods available'**
  String get walletNoPaymentMethods;

  /// No description provided for @validationEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get validationEnterValidAmount;

  /// No description provided for @validationAmountExceedsWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds wallet balance'**
  String get validationAmountExceedsWalletBalance;

  /// No description provided for @withdrawAction.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawAction;

  /// No description provided for @selectWalletPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a wallet'**
  String get selectWalletPrompt;

  /// No description provided for @selectWithdrawalMethodPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a withdrawal method'**
  String get selectWithdrawalMethodPrompt;

  /// No description provided for @walletDefaultTransactionLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get walletDefaultTransactionLabel;

  /// No description provided for @walletTypeCurrency.
  ///
  /// In en, this message translates to:
  /// **'{type} • {currency}'**
  String walletTypeCurrency(String type, String currency);

  /// No description provided for @currencyEtb.
  ///
  /// In en, this message translates to:
  /// **'ETB'**
  String get currencyEtb;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @fruitsVegetables.
  ///
  /// In en, this message translates to:
  /// **'Fruits & Vegetables'**
  String get fruitsVegetables;

  /// No description provided for @beverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get beverages;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products'**
  String get noProducts;

  /// No description provided for @searchStoresHint.
  ///
  /// In en, this message translates to:
  /// **'Search stores and produ...'**
  String get searchStoresHint;

  /// No description provided for @failedToAddFunds.
  ///
  /// In en, this message translates to:
  /// **'Failed to add funds'**
  String get failedToAddFunds;

  /// No description provided for @failedToWithdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'Failed to withdraw funds'**
  String get failedToWithdrawFunds;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmNewPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCode;

  /// No description provided for @referralCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Referral code — optional'**
  String get referralCodeOptional;

  /// No description provided for @hintReferralCode.
  ///
  /// In en, this message translates to:
  /// **'UCZXSD3O'**
  String get hintReferralCode;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Hudhud to order from every business in your city.'**
  String get signupSubtitle;

  /// No description provided for @hintCreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get hintCreatePassword;

  /// No description provided for @hintReenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get hintReenterPassword;

  /// No description provided for @passwordStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Use 8+ characters'**
  String get passwordStrengthHint;

  /// No description provided for @signupAcceptTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I\'ve read and accepted Hudhud\'s '**
  String get signupAcceptTermsPrefix;

  /// No description provided for @signupTermsLink.
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get signupTermsLink;

  /// No description provided for @signupConsentDataPrefix.
  ///
  /// In en, this message translates to:
  /// **'I consent to my data being processed under applicable '**
  String get signupConsentDataPrefix;

  /// No description provided for @signupDataProtectionLink.
  ///
  /// In en, this message translates to:
  /// **'data protection laws'**
  String get signupDataProtectionLink;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signupFormIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get signupFormIncomplete;

  /// No description provided for @signupAcceptLegalRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and data protection consent'**
  String get signupAcceptLegalRequired;

  /// No description provided for @searchQuestions.
  ///
  /// In en, this message translates to:
  /// **'Search question'**
  String get searchQuestions;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @taxiCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get taxiCurrentLocation;

  /// No description provided for @taxiCouldNotGetLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not get location details'**
  String get taxiCouldNotGetLocationDetails;

  /// No description provided for @taxiTimeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get taxiTimeNow;

  /// No description provided for @taxiScheduleForLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule for later'**
  String get taxiScheduleForLater;

  /// No description provided for @taxiActiveRide.
  ///
  /// In en, this message translates to:
  /// **'Active ride'**
  String get taxiActiveRide;

  /// No description provided for @taxiEstFare.
  ///
  /// In en, this message translates to:
  /// **'Est. fare'**
  String get taxiEstFare;

  /// No description provided for @taxiTrackRide.
  ///
  /// In en, this message translates to:
  /// **'Track ride'**
  String get taxiTrackRide;

  /// No description provided for @taxiRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get taxiRefreshStatus;

  /// No description provided for @taxiCarsNearby.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 car nearby} other{{count} cars nearby}}'**
  String taxiCarsNearby(int count);

  /// No description provided for @taxiMinutesWait.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String taxiMinutesWait(int minutes);

  /// No description provided for @taxiBrandHudHud.
  ///
  /// In en, this message translates to:
  /// **'HUDHUD'**
  String get taxiBrandHudHud;

  /// No description provided for @taxiBrandDelivery.
  ///
  /// In en, this message translates to:
  /// **' delivery'**
  String get taxiBrandDelivery;

  /// No description provided for @taxiDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} KM'**
  String taxiDistanceKm(String distance);

  /// No description provided for @taxiGoogleMapsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google Maps is not configured. Add GOOGLE_MAPS_API_KEY and restart the app.'**
  String get taxiGoogleMapsNotConfigured;

  /// No description provided for @taxiStatusFindingDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding a driver…'**
  String get taxiStatusFindingDriver;

  /// No description provided for @taxiStatusDriverOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Driver on the way'**
  String get taxiStatusDriverOnTheWay;

  /// No description provided for @taxiStatusDriverArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived'**
  String get taxiStatusDriverArrived;

  /// No description provided for @taxiStatusTripInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get taxiStatusTripInProgress;

  /// No description provided for @taxiStatusActiveRide.
  ///
  /// In en, this message translates to:
  /// **'Active ride'**
  String get taxiStatusActiveRide;

  /// No description provided for @taxiPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get taxiPickup;

  /// No description provided for @taxiDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get taxiDestination;

  /// No description provided for @taxiFareAmount.
  ///
  /// In en, this message translates to:
  /// **'ETB {amount}'**
  String taxiFareAmount(String amount);

  /// No description provided for @taxiErrorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String taxiErrorWithDetails(String details);

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String profileUpdateFailed(String error);

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String profileLoadFailed(String error);

  /// No description provided for @servicesTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get servicesTryAgain;

  /// No description provided for @unexpectedCheckoutError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String unexpectedCheckoutError(String error);

  /// No description provided for @failedOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order history: {error}'**
  String failedOrderHistory(String error);

  /// No description provided for @timelineOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get timelineOrderPlaced;

  /// No description provided for @timelineOrderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get timelineOrderConfirmed;

  /// No description provided for @timelinePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get timelinePreparing;

  /// No description provided for @timelineReadyPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get timelineReadyPickup;

  /// No description provided for @timelineOutDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get timelineOutDelivery;

  /// No description provided for @timelineDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get timelineDelivered;

  /// No description provided for @addReviewOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a review (optional)'**
  String get addReviewOptional;

  /// No description provided for @pleaseSpecify.
  ///
  /// In en, this message translates to:
  /// **'Please specify...'**
  String get pleaseSpecify;

  /// No description provided for @courierNumber.
  ///
  /// In en, this message translates to:
  /// **'Courier Number'**
  String get courierNumber;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @deliveryDetailsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deliveryDetailsStatus;

  /// No description provided for @deliveryDetailsPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get deliveryDetailsPickup;

  /// No description provided for @deliveryDetailsDropoff.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get deliveryDetailsDropoff;

  /// No description provided for @labelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get labelLocation;

  /// No description provided for @labelInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get labelInstructions;

  /// No description provided for @labelReceiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get labelReceiver;

  /// No description provided for @labelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get labelPhone;

  /// No description provided for @labelPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get labelPackage;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @labelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get labelDescription;

  /// No description provided for @labelWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get labelWeight;

  /// No description provided for @labelSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get labelSpecialInstructions;

  /// No description provided for @paymentAndCost.
  ///
  /// In en, this message translates to:
  /// **'Payment & Cost'**
  String get paymentAndCost;

  /// No description provided for @labelPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get labelPaymentMethod;

  /// No description provided for @labelEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get labelEstimatedCost;

  /// No description provided for @labelPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get labelPaymentStatus;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @labelScheduledPickup.
  ///
  /// In en, this message translates to:
  /// **'Scheduled pickup'**
  String get labelScheduledPickup;

  /// No description provided for @labelScheduledDelivery.
  ///
  /// In en, this message translates to:
  /// **'Scheduled delivery'**
  String get labelScheduledDelivery;

  /// No description provided for @labelDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get labelDelivered;

  /// No description provided for @noEmailAvailable.
  ///
  /// In en, this message translates to:
  /// **'No email available'**
  String get noEmailAvailable;

  /// No description provided for @noPhoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get noPhoneAvailable;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerificationTitle;

  /// No description provided for @phoneVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Verification'**
  String get phoneVerificationTitle;

  /// No description provided for @enterEmailCode.
  ///
  /// In en, this message translates to:
  /// **'Enter email code'**
  String get enterEmailCode;

  /// No description provided for @enterSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Enter SMS code'**
  String get enterSmsCode;

  /// No description provided for @noEmailAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'No email available'**
  String get noEmailAvailableShort;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @sendMoney.
  ///
  /// In en, this message translates to:
  /// **'Send Money'**
  String get sendMoney;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the app?'**
  String get exitAppMessage;

  /// No description provided for @actionExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get actionExit;

  /// No description provided for @loginNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccountPrompt;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get loginOrContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @actionSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get actionSignUp;

  /// No description provided for @paymentScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentScreenTitle;

  /// No description provided for @paymentChooseMethodHeading.
  ///
  /// In en, this message translates to:
  /// **'Choose Payment Method'**
  String get paymentChooseMethodHeading;

  /// No description provided for @paymentEthiopianOptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred Ethiopian payment option'**
  String get paymentEthiopianOptionsSubtitle;

  /// No description provided for @paymentLoadMethodsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load payment methods'**
  String get paymentLoadMethodsError;

  /// No description provided for @paymentSelectMethodFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get paymentSelectMethodFirst;

  /// No description provided for @paymentMethodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Selected payment method is no longer available'**
  String get paymentMethodUnavailable;

  /// No description provided for @paymentFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {error}'**
  String paymentFailedWithError(String error);

  /// No description provided for @paymentPayAmountBr.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} Br'**
  String paymentPayAmountBr(String amount);

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentTransactionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID: {id}'**
  String paymentTransactionIdLabel(String id);

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @handymanServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Handyman Services'**
  String get handymanServicesTitle;

  /// No description provided for @handymanWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get handymanWhatToDo;

  /// No description provided for @handymanMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get handymanMyRequests;

  /// No description provided for @handymanNoRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No service requests yet'**
  String get handymanNoRequestsYet;

  /// No description provided for @handymanNoRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a request to get quotes from handymen'**
  String get handymanNoRequestsSubtitle;

  /// No description provided for @handymanCreateNewRequest.
  ///
  /// In en, this message translates to:
  /// **'Create New Request'**
  String get handymanCreateNewRequest;

  /// No description provided for @handymanCreateRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your repair or maintenance need and get quotes from handymen.'**
  String get handymanCreateRequestSubtitle;

  /// No description provided for @instantDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Delivery'**
  String get instantDeliveryTitle;

  /// No description provided for @tapToSelectPickup.
  ///
  /// In en, this message translates to:
  /// **'Tap to select pickup location'**
  String get tapToSelectPickup;

  /// No description provided for @tapToSelectDelivery.
  ///
  /// In en, this message translates to:
  /// **'Tap to select delivery location'**
  String get tapToSelectDelivery;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @selectPickupAndDelivery.
  ///
  /// In en, this message translates to:
  /// **'Please select both pickup and delivery locations'**
  String get selectPickupAndDelivery;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @errorGettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Error getting address: {error}'**
  String errorGettingAddress(String error);

  /// No description provided for @googleMapsIosMissingKey.
  ///
  /// In en, this message translates to:
  /// **'Google Maps is not configured on iOS. Add GOOGLE_MAPS_API_KEY and restart the app.'**
  String get googleMapsIosMissingKey;

  /// No description provided for @dealsModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Deals on deals'**
  String get dealsModalTitle;

  /// No description provided for @dealsModalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get upto 50% off on your first Courier delivery fee!'**
  String get dealsModalSubtitle;

  /// No description provided for @dealsModalClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get dealsModalClaim;

  /// No description provided for @dealsModalClose.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get dealsModalClose;

  /// No description provided for @orderHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get orderHistoryEmptyTitle;

  /// No description provided for @orderHistoryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse categories to place your first order.'**
  String get orderHistoryEmptySubtitle;

  /// No description provided for @orderHistoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here once you place an order'**
  String get orderHistoryEmptyHint;

  /// No description provided for @browseDelivery.
  ///
  /// In en, this message translates to:
  /// **'Browse Delivery'**
  String get browseDelivery;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse categories'**
  String get browseCategories;

  /// No description provided for @handymanQuoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count} quote(s)'**
  String handymanQuoteCount(int count);

  /// No description provided for @orderDetailsLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading order details...'**
  String get orderDetailsLoadingMessage;

  /// No description provided for @orderDetailsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error loading order details'**
  String get orderDetailsLoadErrorTitle;

  /// No description provided for @orderAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNumber}'**
  String orderAppBarTitle(String orderNumber);

  /// No description provided for @paymentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummaryTitle;

  /// No description provided for @paymentSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get paymentSubtotalLabel;

  /// No description provided for @paymentTotalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get paymentTotalAmountLabel;

  /// No description provided for @paymentProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing Payment'**
  String get paymentProcessingTitle;

  /// No description provided for @paymentProcessingMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we process your payment via {method}...'**
  String paymentProcessingMessage(String method);

  /// No description provided for @courierRecipientLine.
  ///
  /// In en, this message translates to:
  /// **'Recipient: {name}'**
  String courierRecipientLine(String name);

  /// No description provided for @courierTrackDeliveryCta.
  ///
  /// In en, this message translates to:
  /// **'Track delivery'**
  String get courierTrackDeliveryCta;

  /// No description provided for @courierDeliveryStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get courierDeliveryStatusInProgress;

  /// No description provided for @labelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @hintDateFormat.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get hintDateFormat;

  /// No description provided for @labelTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get labelTime;

  /// No description provided for @hintTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'HH:MM'**
  String get hintTimeFormat;

  /// No description provided for @meridiemAm.
  ///
  /// In en, this message translates to:
  /// **'am'**
  String get meridiemAm;

  /// No description provided for @meridiemPm.
  ///
  /// In en, this message translates to:
  /// **'pm'**
  String get meridiemPm;

  /// No description provided for @scheduleSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time for delivery'**
  String get scheduleSelectDateTime;

  /// No description provided for @scheduleInvalidDateTime.
  ///
  /// In en, this message translates to:
  /// **'Invalid date or time format'**
  String get scheduleInvalidDateTime;

  /// No description provided for @servicesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Services'**
  String get servicesScreenTitle;

  /// No description provided for @servicesWhatCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'What can we help you with?'**
  String get servicesWhatCanWeHelp;

  /// No description provided for @servicesAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} services available'**
  String servicesAvailableCount(int count);

  /// No description provided for @servicesErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get servicesErrorTitle;

  /// No description provided for @servicesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get servicesEmptyTitle;

  /// No description provided for @servicesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new services'**
  String get servicesEmptySubtitle;

  /// No description provided for @handymanNewRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New Service Request'**
  String get handymanNewRequestTitle;

  /// No description provided for @validationHandymanSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get validationHandymanSelectLocation;

  /// No description provided for @validationHandymanSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get validationHandymanSelectDateTime;

  /// No description provided for @validationHandymanSelectSkill.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one skill'**
  String get validationHandymanSelectSkill;

  /// No description provided for @handymanRequestCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Request created'**
  String get handymanRequestCreatedToast;

  /// No description provided for @handymanRequestCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create request'**
  String get handymanRequestCreateFailed;

  /// No description provided for @labelTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get labelTitle;

  /// No description provided for @hintTitleHandymanExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fix leaking faucet'**
  String get hintTitleHandymanExample;

  /// No description provided for @validationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get validationTitleRequired;

  /// No description provided for @validationDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get validationDescriptionRequired;

  /// No description provided for @hintDescribeRepair.
  ///
  /// In en, this message translates to:
  /// **'Describe the repair or maintenance needed'**
  String get hintDescribeRepair;

  /// No description provided for @handymanTapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to select location'**
  String get handymanTapToSelectLocation;

  /// No description provided for @labelScheduledDateTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Date & Time'**
  String get labelScheduledDateTime;

  /// No description provided for @selectDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Select date and time'**
  String get selectDateAndTime;

  /// No description provided for @labelEstimatedCostOptional.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost (optional)'**
  String get labelEstimatedCostOptional;

  /// No description provided for @hintCostExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100'**
  String get hintCostExample;

  /// No description provided for @handymanSkillsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Skills needed'**
  String get handymanSkillsNeeded;

  /// No description provided for @handymanSkillPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get handymanSkillPlumbing;

  /// No description provided for @handymanSkillElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get handymanSkillElectrical;

  /// No description provided for @handymanSkillCarpentry.
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get handymanSkillCarpentry;

  /// No description provided for @handymanSkillPainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get handymanSkillPainting;

  /// No description provided for @handymanSkillGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get handymanSkillGeneral;

  /// No description provided for @labelToolsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Tools needed (comma-separated)'**
  String get labelToolsCommaSeparated;

  /// No description provided for @hintToolsHandymanExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. wrench set, plumber\'s tape'**
  String get hintToolsHandymanExample;

  /// No description provided for @labelEstimatedHoursOptional.
  ///
  /// In en, this message translates to:
  /// **'Estimated hours (optional)'**
  String get labelEstimatedHoursOptional;

  /// No description provided for @hintHoursExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2'**
  String get hintHoursExample;

  /// No description provided for @handymanCreateRequestCta.
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get handymanCreateRequestCta;

  /// No description provided for @handymanDialogCancelRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get handymanDialogCancelRequestTitle;

  /// No description provided for @handymanDialogCancelRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this service request?'**
  String get handymanDialogCancelRequestMessage;

  /// No description provided for @actionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get actionNo;

  /// No description provided for @actionYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get actionYesCancel;

  /// No description provided for @handymanRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get handymanRequestCancelled;

  /// No description provided for @handymanCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel'**
  String get handymanCancelFailed;

  /// No description provided for @handymanLabelScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get handymanLabelScheduled;

  /// No description provided for @handymanSectionRequirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get handymanSectionRequirements;

  /// No description provided for @handymanToolsLine.
  ///
  /// In en, this message translates to:
  /// **'Tools: {tools}'**
  String handymanToolsLine(String tools);

  /// No description provided for @handymanEstHoursLine.
  ///
  /// In en, this message translates to:
  /// **'Est. hours: {hours}'**
  String handymanEstHoursLine(String hours);

  /// No description provided for @handymanViewQuotesCta.
  ///
  /// In en, this message translates to:
  /// **'View {count} quote(s)'**
  String handymanViewQuotesCta(int count);

  /// No description provided for @handymanCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get handymanCancelRequest;

  /// No description provided for @handymanRateServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Service'**
  String get handymanRateServiceTitle;

  /// No description provided for @handymanProviderFallback.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get handymanProviderFallback;

  /// No description provided for @handymanQuotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get handymanQuotesTitle;

  /// No description provided for @handymanAcceptQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept Quote'**
  String get handymanAcceptQuoteTitle;

  /// No description provided for @handymanAcceptQuoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Accept {amount} from {name}?'**
  String handymanAcceptQuoteMessage(String amount, String name);

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actionReject;

  /// No description provided for @handymanQuoteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Quote accepted'**
  String get handymanQuoteAccepted;

  /// No description provided for @handymanAcceptQuoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept'**
  String get handymanAcceptQuoteFailed;

  /// No description provided for @handymanRejectQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Quote'**
  String get handymanRejectQuoteTitle;

  /// No description provided for @handymanRejectQuoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Reject quote from {name}?'**
  String handymanRejectQuoteMessage(String name);

  /// No description provided for @handymanQuoteRejected.
  ///
  /// In en, this message translates to:
  /// **'Quote rejected'**
  String get handymanQuoteRejected;

  /// No description provided for @handymanRejectQuoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject'**
  String get handymanRejectQuoteFailed;

  /// No description provided for @handymanNoQuotesYet.
  ///
  /// In en, this message translates to:
  /// **'No quotes yet'**
  String get handymanNoQuotesYet;

  /// No description provided for @handymanNoQuotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Handymen will send quotes soon'**
  String get handymanNoQuotesSubtitle;

  /// No description provided for @handymanViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get handymanViewProfile;

  /// No description provided for @handymanHowWasService.
  ///
  /// In en, this message translates to:
  /// **'How was the service?'**
  String get handymanHowWasService;

  /// No description provided for @handymanRateTheHandyman.
  ///
  /// In en, this message translates to:
  /// **'Rate the handyman'**
  String get handymanRateTheHandyman;

  /// No description provided for @handymanCommentAboutOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment about handyman (optional)'**
  String get handymanCommentAboutOptional;

  /// No description provided for @handymanRatingPublic.
  ///
  /// In en, this message translates to:
  /// **'Make my rating public'**
  String get handymanRatingPublic;

  /// No description provided for @handymanSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get handymanSubmitRating;

  /// No description provided for @ratingThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your rating!'**
  String get ratingThankYou;

  /// No description provided for @ratingSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit rating'**
  String get ratingSubmitFailed;

  /// No description provided for @handymanNotFound.
  ///
  /// In en, this message translates to:
  /// **'Handyman not found'**
  String get handymanNotFound;

  /// No description provided for @handymanProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Handyman Profile'**
  String get handymanProfileTitle;

  /// No description provided for @handymanAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get handymanAbout;

  /// No description provided for @handymanSkillsHeading.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get handymanSkillsHeading;

  /// No description provided for @handymanHourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get handymanHourlyRateLabel;

  /// No description provided for @handymanExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get handymanExperienceLabel;

  /// No description provided for @handymanExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String handymanExperienceYears(String years);

  /// No description provided for @labelAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get labelAddress;

  /// No description provided for @handymanStatsHeading.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get handymanStatsHeading;

  /// No description provided for @handymanStatServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get handymanStatServices;

  /// No description provided for @handymanStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get handymanStatRating;

  /// No description provided for @handymanStatResponse.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get handymanStatResponse;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordRequestTitle;

  /// No description provided for @forgotPasswordRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number. We\'ll send a 6-digit verification code.'**
  String get forgotPasswordRequestSubtitle;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get forgotPasswordVerifyTitle;

  /// No description provided for @forgotPasswordVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {identifier}.'**
  String forgotPasswordVerifySubtitle(String identifier);

  /// No description provided for @forgotPasswordOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get forgotPasswordOtpLabel;

  /// No description provided for @forgotPasswordTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {time}'**
  String forgotPasswordTimeRemaining(String time);

  /// No description provided for @forgotPasswordCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Tap resend for a new code.'**
  String get forgotPasswordCodeExpired;

  /// No description provided for @forgotPasswordResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get forgotPasswordResend;

  /// No description provided for @forgotPasswordVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get forgotPasswordVerifyButton;

  /// No description provided for @forgotPasswordNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new password'**
  String get forgotPasswordNewTitle;

  /// No description provided for @forgotPasswordNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get forgotPasswordNewSubtitle;

  /// No description provided for @forgotPasswordLabelConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get forgotPasswordLabelConfirmPassword;

  /// No description provided for @forgotPasswordHintConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get forgotPasswordHintConfirmPassword;

  /// No description provided for @forgotPasswordSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get forgotPasswordSaveButton;

  /// No description provided for @forgotPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password updated. You can sign in now.'**
  String get forgotPasswordSuccessMessage;

  /// No description provided for @validationOtpLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get validationOtpLength;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @addressesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get addressesTitle;

  /// No description provided for @addressesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get addressesEmptyTitle;

  /// No description provided for @addressesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an address to speed up checkout and delivery.'**
  String get addressesEmptySubtitle;

  /// No description provided for @addressesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addressesAdd;

  /// No description provided for @addressesAddFromMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get addressesAddFromMap;

  /// No description provided for @addressesAddManual.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get addressesAddManual;

  /// No description provided for @addressesDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get addressesDefaultBadge;

  /// No description provided for @addressesSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get addressesSetDefault;

  /// No description provided for @addressesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get addressesEdit;

  /// No description provided for @addressesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete address?'**
  String get addressesDeleteTitle;

  /// No description provided for @addressesDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This address will be removed from your account.'**
  String get addressesDeleteMessage;

  /// No description provided for @addressesBulkDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected addresses?'**
  String get addressesBulkDeleteTitle;

  /// No description provided for @addressesBulkDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} address(es)?'**
  String addressesBulkDeleteMessage(int count);

  /// No description provided for @addressesBulkDeleteForce.
  ///
  /// In en, this message translates to:
  /// **'Also delete default address'**
  String get addressesBulkDeleteForce;

  /// No description provided for @addressesSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get addressesSelect;

  /// No description provided for @addressesDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get addressesDeleteSelected;

  /// No description provided for @addressesTypeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressesTypeHome;

  /// No description provided for @addressesTypeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addressesTypeWork;

  /// No description provided for @addressesTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressesTypeOther;

  /// No description provided for @addressFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addressFormAddTitle;

  /// No description provided for @addressFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get addressFormEditTitle;

  /// No description provided for @addressFormLine1.
  ///
  /// In en, this message translates to:
  /// **'Address line 1'**
  String get addressFormLine1;

  /// No description provided for @addressFormLine2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2 (optional)'**
  String get addressFormLine2;

  /// No description provided for @addressFormCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addressFormCity;

  /// No description provided for @addressFormState.
  ///
  /// In en, this message translates to:
  /// **'State / region'**
  String get addressFormState;

  /// No description provided for @addressFormPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get addressFormPostalCode;

  /// No description provided for @addressFormCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get addressFormCountry;

  /// No description provided for @addressFormLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressFormLabel;

  /// No description provided for @addressFormLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark (optional)'**
  String get addressFormLandmark;

  /// No description provided for @addressFormType.
  ///
  /// In en, this message translates to:
  /// **'Address type'**
  String get addressFormType;

  /// No description provided for @addressFormSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get addressFormSetDefault;

  /// No description provided for @addressFormPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick location on map'**
  String get addressFormPickOnMap;

  /// No description provided for @addressFormRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get addressFormRequired;

  /// No description provided for @addressMapPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick location'**
  String get addressMapPickerTitle;

  /// No description provided for @addressMapUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get addressMapUseLocation;

  /// No description provided for @deliveryAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddressTitle;

  /// No description provided for @deliveryAddressChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get deliveryAddressChange;

  /// No description provided for @deliveryAddressSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get deliveryAddressSaved;

  /// No description provided for @deliveryAddressPickMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get deliveryAddressPickMap;

  /// No description provided for @deliveryAddressAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add new address'**
  String get deliveryAddressAddNew;

  /// No description provided for @deliveryAddressSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select delivery address'**
  String get deliveryAddressSelectPrompt;

  /// No description provided for @addressesSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage addresses'**
  String get addressesSignInTitle;

  /// No description provided for @addressesSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save multiple delivery addresses and set a default.'**
  String get addressesSignInSubtitle;

  /// No description provided for @addressesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load addresses'**
  String get addressesLoadError;

  /// No description provided for @addressesCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get addressesCreatedSuccess;

  /// No description provided for @addressesUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Address updated'**
  String get addressesUpdatedSuccess;

  /// No description provided for @addressesDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressesDeletedSuccess;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatEmpty;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start chatting about an order or contact support.'**
  String get chatEmptySubtitle;

  /// No description provided for @chatContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get chatContactSupport;

  /// No description provided for @chatViewOrders.
  ///
  /// In en, this message translates to:
  /// **'View orders'**
  String get chatViewOrders;

  /// No description provided for @chatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get chatSearchHint;

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatTypeMessage;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatSupportSubject.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get chatSupportSubject;

  /// No description provided for @chatSupportSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Brief subject'**
  String get chatSupportSubjectHint;

  /// No description provided for @chatSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'New support chat'**
  String get chatSupportTitle;

  /// No description provided for @chatEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get chatEdited;

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get chatDeleted;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send message'**
  String get chatSendFailed;

  /// No description provided for @chatOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order chat'**
  String get chatOrderTitle;

  /// No description provided for @chatSupportChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatSupportChatTitle;

  /// No description provided for @chatRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride chat'**
  String get chatRideTitle;

  /// No description provided for @chatAttachImage.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get chatAttachImage;

  /// No description provided for @chatAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get chatAttachFile;

  /// No description provided for @chatAttachAudio.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get chatAttachAudio;

  /// No description provided for @chatShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatShareLocation;

  /// No description provided for @chatEditingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get chatEditingMessage;

  /// No description provided for @chatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  /// No description provided for @chatEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatEdit;

  /// No description provided for @chatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDelete;

  /// No description provided for @chatRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get chatRetry;

  /// No description provided for @chatOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get chatOpenMaps;

  /// No description provided for @chatNewSupport.
  ///
  /// In en, this message translates to:
  /// **'New support chat'**
  String get chatNewSupport;

  /// No description provided for @chatTypeOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get chatTypeOrder;

  /// No description provided for @chatTypeSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatTypeSupport;

  /// No description provided for @chatTypeRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get chatTypeRide;

  /// No description provided for @chatOpenOrder.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get chatOpenOrder;

  /// No description provided for @chatRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get chatRecording;

  /// No description provided for @chatSlideToCancel.
  ///
  /// In en, this message translates to:
  /// **'Slide up to cancel'**
  String get chatSlideToCancel;

  /// No description provided for @chatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// No description provided for @chatVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceMessage;

  /// No description provided for @chatLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatLocation;

  /// No description provided for @chatFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatFile;

  /// No description provided for @chatLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get chatLoadError;

  /// No description provided for @chatCreateSupport.
  ///
  /// In en, this message translates to:
  /// **'Start chat'**
  String get chatCreateSupport;

  /// No description provided for @sosSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety & SOS'**
  String get sosSettingsTitle;

  /// No description provided for @sosEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get sosEmergencyContacts;

  /// No description provided for @sosEmergencyContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People notified when you trigger SOS'**
  String get sosEmergencyContactsSubtitle;

  /// No description provided for @sosHistory.
  ///
  /// In en, this message translates to:
  /// **'SOS history'**
  String get sosHistory;

  /// No description provided for @sosHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View past alerts'**
  String get sosHistorySubtitle;

  /// No description provided for @sosTrigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger SOS'**
  String get sosTrigger;

  /// No description provided for @sosTriggerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send an emergency alert with your location'**
  String get sosTriggerSubtitle;

  /// No description provided for @sosTriggerConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send SOS alert?'**
  String get sosTriggerConfirmTitle;

  /// No description provided for @sosTriggerConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your emergency contacts will be notified with your current location. Only use in a real emergency.'**
  String get sosTriggerConfirmMessage;

  /// No description provided for @sosDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your situation (optional)'**
  String get sosDescriptionHint;

  /// No description provided for @sosLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required to send an SOS alert. Please enable location permissions.'**
  String get sosLocationRequired;

  /// No description provided for @sosContactAdded.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact added'**
  String get sosContactAdded;

  /// No description provided for @sosContactUpdated.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact updated'**
  String get sosContactUpdated;

  /// No description provided for @sosContactDeleted.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact deleted'**
  String get sosContactDeleted;

  /// No description provided for @sosTriggered.
  ///
  /// In en, this message translates to:
  /// **'SOS alert sent successfully'**
  String get sosTriggered;

  /// No description provided for @sosAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get sosAddContact;

  /// No description provided for @sosEditContact.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get sosEditContact;

  /// No description provided for @sosNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts yet'**
  String get sosNoContacts;

  /// No description provided for @sosNoContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add someone who should be notified in an emergency.'**
  String get sosNoContactsSubtitle;

  /// No description provided for @sosNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No SOS alerts yet'**
  String get sosNoHistory;

  /// No description provided for @sosName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get sosName;

  /// No description provided for @sosPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get sosPhone;

  /// No description provided for @sosEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get sosEmail;

  /// No description provided for @sosRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get sosRelationship;

  /// No description provided for @sosPrimaryContact.
  ///
  /// In en, this message translates to:
  /// **'Primary contact'**
  String get sosPrimaryContact;

  /// No description provided for @sosDeleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get sosDeleteContact;

  /// No description provided for @sosDeleteContactConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this emergency contact?'**
  String get sosDeleteContactConfirm;

  /// No description provided for @sosStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sosStatusActive;

  /// No description provided for @sosStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sosStatusAll;

  /// No description provided for @sosCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sosCancel;

  /// No description provided for @sosSendAlert.
  ///
  /// In en, this message translates to:
  /// **'Send alert'**
  String get sosSendAlert;

  /// No description provided for @sosSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get sosSaving;

  /// No description provided for @guestBrowseBanner.
  ///
  /// In en, this message translates to:
  /// **'Browsing as guest'**
  String get guestBrowseBanner;

  /// No description provided for @guestBrowseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get guestBrowseSignIn;

  /// No description provided for @guestSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get guestSignInRequiredTitle;

  /// No description provided for @guestSignInRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Create an account or sign in to use this feature.'**
  String get guestSignInRequiredMessage;

  /// No description provided for @guestSignInRequiredCheckout.
  ///
  /// In en, this message translates to:
  /// **'Sign in to place orders and complete checkout.'**
  String get guestSignInRequiredCheckout;

  /// No description provided for @guestOrdersSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your order history.'**
  String get guestOrdersSignIn;

  /// No description provided for @guestProfileSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your profile and settings.'**
  String get guestProfileSignIn;

  /// No description provided for @guestServiceSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use this service.'**
  String get guestServiceSignIn;

  /// No description provided for @wishlistNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get wishlistNotesHint;

  /// No description provided for @wishlistNotesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get wishlistNotesUpdated;

  /// No description provided for @wishlistShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share wishlist'**
  String get wishlistShareTitle;

  /// No description provided for @wishlistShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wishlist shared successfully'**
  String get wishlistShareSuccess;

  /// No description provided for @wishlistPriceDropsTitle.
  ///
  /// In en, this message translates to:
  /// **'Price drop'**
  String get wishlistPriceDropsTitle;

  /// No description provided for @wishlistPriceDropsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No price drops right now'**
  String get wishlistPriceDropsEmpty;

  /// No description provided for @wishlistMigrateError.
  ///
  /// In en, this message translates to:
  /// **'Could not sync saved items to your account'**
  String get wishlistMigrateError;

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tipsTitle;

  /// No description provided for @tipsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a tip'**
  String get tipsAddTitle;

  /// No description provided for @tipsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip history'**
  String get tipsHistoryTitle;

  /// No description provided for @tipsRecipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip recipient'**
  String get tipsRecipientLabel;

  /// No description provided for @tipsRecipientDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get tipsRecipientDriver;

  /// No description provided for @tipsRecipientVendor.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get tipsRecipientVendor;

  /// No description provided for @tipsRecipientBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get tipsRecipientBoth;

  /// No description provided for @tipsCalculatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Tip amount: ETB {amount}'**
  String tipsCalculatedAmount(String amount);

  /// No description provided for @tipsSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send tip'**
  String get tipsSubmit;

  /// No description provided for @tipsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tip sent successfully'**
  String get tipsSuccess;

  /// No description provided for @tipsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load tips'**
  String get tipsLoadError;

  /// No description provided for @tipsCardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Card payments coming soon'**
  String get tipsCardComingSoon;

  /// No description provided for @tipsAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Send anonymously'**
  String get tipsAnonymous;

  /// No description provided for @tipsMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Add a message (optional)'**
  String get tipsMessageHint;

  /// No description provided for @tipsStatsTotal.
  ///
  /// In en, this message translates to:
  /// **'Tips given'**
  String get tipsStatsTotal;

  /// No description provided for @tipsStatsAmount.
  ///
  /// In en, this message translates to:
  /// **'Total tipped'**
  String get tipsStatsAmount;

  /// No description provided for @tipsStatsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average tip'**
  String get tipsStatsAverage;

  /// No description provided for @tipsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tips yet'**
  String get tipsHistoryEmpty;

  /// No description provided for @tipsPaymentWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get tipsPaymentWallet;

  /// No description provided for @tipsPaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get tipsPaymentCard;

  /// No description provided for @tipsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tipsStatusCompleted;

  /// No description provided for @tipsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tipsStatusAll;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'ar', 'en', 'om', 'so'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
    case 'so':
      return AppLocalizationsSo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
