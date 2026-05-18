// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HudHud Delivery';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOk => 'OK';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionVerify => 'Verify';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionDone => 'Done';

  @override
  String get actionResend => 'Resend Code';

  @override
  String get actionUndo => 'UNDO';

  @override
  String get actionOpenSettings => 'Open Settings';

  @override
  String get actionViewAll => 'View all';

  @override
  String get actionTrackDelivery => 'Track delivery';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionAddToCart => 'Add to cart';

  @override
  String get actionSeeAll => 'see all';

  @override
  String get actionSending => 'Sending...';

  @override
  String get actionSignIn => 'Sign In';

  @override
  String get actionLogOut => 'Logout';

  @override
  String get navHome => 'Home';

  @override
  String get navCourier => 'Courier';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navTaxi => 'Taxi';

  @override
  String get navProfile => 'Profile';

  @override
  String get navOrderHistory => 'Order History';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsContactEmail => 'Email support';

  @override
  String get offlineNoConnection => 'No internet connection';

  @override
  String get orderIdCopied => 'Order ID copied';

  @override
  String get orderShareSubject => 'HudHud order';

  @override
  String get settingsPersonalDetails => 'Personal Details';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceChooseTheme => 'Choose your preferred theme';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsSmsNotifications => 'SMS Notifications';

  @override
  String get settingsWishlist => 'Wishlist';

  @override
  String get wishlistEmptyTitle => 'No saved items yet';

  @override
  String get wishlistEmptySubtitle =>
      'Save products you love — tap the heart on a product to add it here.';

  @override
  String get wishlistAddedSnack => 'Added to wishlist';

  @override
  String get wishlistRemovedSnack => 'Removed from wishlist';

  @override
  String get wishlistSignInTitle => 'Sign in to use your wishlist';

  @override
  String get wishlistSignInSubtitle =>
      'Your saved items are stored on this device when you are logged in.';

  @override
  String get wishlistLoadError => 'Could not load wishlist';

  @override
  String get wishlistTooltipAdd => 'Add to wishlist';

  @override
  String get wishlistTooltipRemove => 'Remove from wishlist';

  @override
  String get settingsTermsConditions => 'Terms & Conditions';

  @override
  String get settingsFaqs => 'FAQs';

  @override
  String get settingsHelpDesk => 'Help Desk';

  @override
  String get settingsLogOut => 'Log Out';

  @override
  String get settingsVersion => 'Version 1.0';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileCoupons => 'Coupons';

  @override
  String get profileWallet => 'Wallet';

  @override
  String get profileMenuProfile => 'Profile';

  @override
  String get profileMenuAddresses => 'Addresses';

  @override
  String get profileMenuFavorites => 'Favorites';

  @override
  String get profileMenuAccountSettings => 'Account Settings';

  @override
  String get settingsGeneralPreferences => 'General Preferences';

  @override
  String get settingsDeliveryPreferences => 'Delivery Preferences';

  @override
  String get settingsAppSettings => 'App Settings';

  @override
  String get profileCouponsComingSoon => 'Coupons are not available yet.';

  @override
  String get profileTermsOfUse => 'Terms of Use';

  @override
  String get profilePrivacyPolicy => 'Privacy Policy';

  @override
  String profileCopyright(String year) {
    return '© $year HudHud Delivery. All Rights Reserved.';
  }

  @override
  String profileVersionFormatted(String version, String buildNumber) {
    return 'Version $version (Build $buildNumber)';
  }

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutMessage => 'Are you sure you want to logout?';

  @override
  String logoutError(String error) {
    return 'Error during logout: $error';
  }

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSubtitleLight => 'Always use light theme';

  @override
  String get themeSubtitleDark => 'Always use dark theme';

  @override
  String get themeSubtitleSystem => 'Follow device theme';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ (Amharic)';

  @override
  String get languageOromo => 'Afaan Oromo';

  @override
  String get languageSomali => 'Somali';

  @override
  String get languageArabic => 'العربية (Arabic)';

  @override
  String get greetingGoodMorning => 'Good Morning';

  @override
  String get greetingGoodAfternoon => 'Good Afternoon';

  @override
  String get greetingGoodEvening => 'Good Evening';

  @override
  String get greetingGoodNight => 'Good Night';

  @override
  String get userDefault => 'User';

  @override
  String get emDash => '—';

  @override
  String get locationGetting => 'Getting location...';

  @override
  String get locationAccessDenied => 'Location access denied';

  @override
  String get locationDisabledSnackbar =>
      'Location access is disabled. Enable it in Settings to see your position.';

  @override
  String get locationUnable => 'Unable to get location';

  @override
  String get yourLocation => 'Your Location';

  @override
  String get selectLocationTitle => 'Select Location';

  @override
  String get refreshLocationTooltip => 'Refresh current location';

  @override
  String get searchPlacesHint => 'Search for places...';

  @override
  String get searchLocationHint => 'Search for a location...';

  @override
  String get locationSearchScreenTitle => 'Search location';

  @override
  String get locationSelectedHeading => 'Selected location';

  @override
  String locationCoordinatesFormat(String lat, String lng) {
    return 'Coordinates: $lat, $lng';
  }

  @override
  String get locationConfirmButton => 'Confirm location';

  @override
  String get locationSearchNoResults => 'No locations found';

  @override
  String get locationCurrentPositionFailed => 'Could not get current location';

  @override
  String get currentLocationMap => 'Current location';

  @override
  String get verificationStatus => 'Verification status';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verifyPhone => 'Verify Phone';

  @override
  String get verifyEmailDialogTitle => 'Verify Email';

  @override
  String get verifyPhoneDialogTitle => 'Verify Phone';

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get verificationCodeHintExample => 'e.g. 111248';

  @override
  String get verificationCodeHintSms => 'e.g. 056869';

  @override
  String verifyEmailBody(String email) {
    return 'We sent a verification code to $email. Enter it below.';
  }

  @override
  String verifyPhoneBody(String phone) {
    return 'We sent a verification code to $phone. Enter it below.';
  }

  @override
  String get enterVerificationCodeError => 'Enter the verification code';

  @override
  String get codeSentEmailDefault => 'Code sent to your email.';

  @override
  String get codeSentPhoneDefault => 'Code sent to your phone.';

  @override
  String get emailVerifiedSuccess => 'Email verified successfully!';

  @override
  String get phoneVerifiedSuccess => 'Phone number verified successfully!';

  @override
  String get accountVerificationBannerTitle => 'Secure your account';

  @override
  String get accountVerificationEmailSubtitle =>
      'Confirm your email for receipts and updates.';

  @override
  String get accountVerificationPhoneSubtitle =>
      'Verify your phone for security and support.';

  @override
  String failedToLoadOrders(String error) {
    return 'Failed to load orders: $error';
  }

  @override
  String get homeWhatToDo => 'What would you like to do?';

  @override
  String get homeFood => 'Food';

  @override
  String get homeFoodSubtitle => 'Order groceries from your favourite vendors.';

  @override
  String get homeCourierSubtitle =>
      'Order courier services for pickup and drop off.';

  @override
  String get homeTaxi => 'Taxi';

  @override
  String get homeTaxiSubtitle =>
      'Request taxi at affordable rates from anywhere.';

  @override
  String get homeHandyman => 'Handyman';

  @override
  String get homeHandymanSubtitle =>
      'Request handy men for casual services at home.';

  @override
  String get history => 'History';

  @override
  String get featuresSectionTitle => 'What you can do with HudHud';

  @override
  String get featureFoodGroceries => 'Food & groceries';

  @override
  String get featureFoodGroceriesDesc => 'Order from your favourite vendors.';

  @override
  String get featureCourierTitle => 'Courier';

  @override
  String get featureCourierDesc => 'Pickup and drop-off.';

  @override
  String get featureTaxiTitle => 'Taxi';

  @override
  String get featureTaxiDesc => 'Request a ride anywhere.';

  @override
  String get featureHandymanTitle => 'Handyman';

  @override
  String get featureHandymanDesc => 'Home services on demand.';

  @override
  String get featureTrackOrders => 'Track orders';

  @override
  String get featureTrackOrdersDesc => 'Real-time delivery status.';

  @override
  String get courierWhatToDo => 'What would you like to do?';

  @override
  String get courierActiveDelivery => 'Active Delivery';

  @override
  String get courierNoHistory => 'No delivery history';

  @override
  String get courierHistoryEmptySubtitle =>
      'Your past deliveries will appear here';

  @override
  String get courierInstantTitle => 'Instant Delivery';

  @override
  String get courierInstantSubtitle =>
      'Courier takes only your package and delivers instantly.';

  @override
  String get courierScheduleTitle => 'Schedule Delivery';

  @override
  String get courierScheduleSubtitle =>
      'Courier comes to pick up on your specified date and time.';

  @override
  String get failedToLoadHistory => 'Failed to load history';

  @override
  String recipientLabel(String name) {
    return 'Recipient: $name';
  }

  @override
  String get inProgress => 'In progress';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle =>
      'Please enter your credentials to access your account and all available services';

  @override
  String get loginContinueAsGuest => 'Continue as guest';

  @override
  String get labelEmailOrPhone => 'Email address or Phone number';

  @override
  String get hintEmailPhone => 'Eg. JohnDoe@gmail.com';

  @override
  String get labelPassword => 'Password';

  @override
  String get hintPassword => 'Enter password';

  @override
  String get validationEmailOrPhoneRequired =>
      'Please enter your email or phone number';

  @override
  String get validationEmailOrPhoneInvalid =>
      'Please enter a valid email or phone number';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get validationPasswordMin => 'Password must be at least 8 characters';

  @override
  String get validationPasswordComplexity =>
      'Password must include uppercase, lowercase, a number, and a special character';

  @override
  String get validationEmailRequired => 'Please enter your email';

  @override
  String get validationEmailInvalid => 'Please enter a valid email address';

  @override
  String get mainDemoTitle => 'HudHud Delivery Demo';

  @override
  String get toggleThemeTooltip => 'Toggle Theme';

  @override
  String themeSwitched(String mode) {
    return 'Theme switched to $mode';
  }

  @override
  String themeModeSet(String mode) {
    return 'Theme mode set to $mode';
  }

  @override
  String get welcomeTitle => 'Welcome to HudHud Delivery!';

  @override
  String get welcomeBody =>
      'This is a demo showcasing the clean architecture with custom buttons, snackbars, and theme switching.';

  @override
  String currentThemeLabel(String mode) {
    return 'Current theme: $mode';
  }

  @override
  String get counterDemo => 'Counter Demo';

  @override
  String counterDecreased(int count) {
    return 'Counter decreased to $count';
  }

  @override
  String counterIncreased(int count) {
    return 'Counter increased to $count';
  }

  @override
  String get buttonShowcase => 'Button Showcase';

  @override
  String get primaryButton => 'Primary Button';

  @override
  String get primaryButtonPressed => 'Primary button pressed!';

  @override
  String get largePrimaryButton => 'Large Primary Button';

  @override
  String get largePrimaryPressed => 'Large primary button with icon pressed!';

  @override
  String get smallButton => 'Small';

  @override
  String get smallButtonPressed => 'Small button pressed!';

  @override
  String get iconButtonPressed => 'Icon button pressed!';

  @override
  String get secondaryButton => 'Secondary Button';

  @override
  String get secondaryPressed => 'Secondary button pressed!';

  @override
  String get largeSecondaryButton => 'Large Secondary Button';

  @override
  String get largeSecondaryPressed => 'Large secondary button pressed!';

  @override
  String get smallSecondary => 'Small Secondary';

  @override
  String get smallSecondaryPressed => 'Small secondary button pressed!';

  @override
  String get ghostButton => 'Ghost Button';

  @override
  String get ghostPressed => 'Ghost button pressed!';

  @override
  String get snackbarShowcase => 'Snackbar Showcase';

  @override
  String get snackbarSuccess => 'This is a success message!';

  @override
  String get snackbarSuccessLabel => 'Success';

  @override
  String get snackbarError => 'This is an error message!';

  @override
  String get snackbarErrorLabel => 'Error';

  @override
  String get snackbarWarning => 'This is a warning message!';

  @override
  String get snackbarWarningLabel => 'Warning';

  @override
  String get snackbarInfo => 'This is an info message!';

  @override
  String get snackbarInfoLabel => 'Info';

  @override
  String get undoActionPressed => 'Undo action pressed';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get showLoadingButton => 'Show Loading';

  @override
  String get dataLoadedSuccess => 'Data loaded successfully!';

  @override
  String get hideSnackbar => 'Hide Snackbar';

  @override
  String get apiDemo => 'API Demo';

  @override
  String get sampleLogin => 'Sample Login';

  @override
  String loginSuccessWelcome(String name) {
    return 'Login successful! Welcome $name';
  }

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get getUserProfile => 'Get User Profile';

  @override
  String get profileRefreshed => 'Profile refreshed successfully!';

  @override
  String profileRefreshFailed(String error) {
    return 'Failed to refresh profile: $error';
  }

  @override
  String get currentUser => 'Current User:';

  @override
  String get nameLabel => 'Name:';

  @override
  String get emailLabel => 'Email:';

  @override
  String get roleLabel => 'Role:';

  @override
  String get logoutSuccess => 'Logged out successfully!';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get utilityButtonsDemo => 'Utility Buttons Demo';

  @override
  String get utilityPrimary => 'Utility Primary Button';

  @override
  String get utilityPrimaryPressed => 'Utility primary button pressed!';

  @override
  String get utilitySecondary => 'Utility Secondary Button';

  @override
  String get utilitySecondaryPressed => 'Utility secondary button pressed!';

  @override
  String get textButton => 'Text Button';

  @override
  String get textButtonPressed => 'Text button pressed!';

  @override
  String get sharePressed => 'Share button pressed!';

  @override
  String get gradientButton => 'Gradient Button';

  @override
  String get gradientPressed => 'Gradient button pressed!';

  @override
  String get counterReset => 'Counter reset!';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusPreparing => 'Preparing';

  @override
  String get orderStatusReadyForPickup => 'Ready for Pickup';

  @override
  String get orderStatusOutForDelivery => 'Out for Delivery';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusTextPending => 'Order Pending';

  @override
  String get orderStatusTextAccepted => 'Order Accepted';

  @override
  String get orderStatusTextPreparing => 'Preparing Order';

  @override
  String get orderStatusTextReadyPickup => 'Ready for Pickup';

  @override
  String get orderStatusTextPickedUp => 'Order Picked Up';

  @override
  String get orderStatusTextDelivered => 'Order Delivered';

  @override
  String get orderStatusTextCancelled => 'Order Cancelled';

  @override
  String get paymentCashOnDelivery => 'Cash on Delivery';

  @override
  String get paymentPaidOnline => 'Paid Online';

  @override
  String get estimatedDeliveryPlaceholder => '30-45 mins';

  @override
  String get searchRestaurantsHint => 'Search restaurants by name';

  @override
  String get enterPromoCode => 'Enter Promo Code';

  @override
  String get additionalNote => 'Additional note';

  @override
  String get enterCustomTip => 'Enter custom tip amount';

  @override
  String get hintFirstName => 'Eg. John';

  @override
  String get hintLastName => 'Eg. Doe';

  @override
  String get hintEmailExample => 'Eg. JohnDoe@gmail.com';

  @override
  String get hintPhoneExample => 'Eg. 0712345678';

  @override
  String get hintEnterPassword => 'Enter password';

  @override
  String get pickupLocation => 'Pickup location';

  @override
  String get dropOff => 'Drop off';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get wallet => 'Wallet';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get transactionIdHint => 'From payment gateway';

  @override
  String get cardLast4 => 'Card last 4 digits';

  @override
  String get cardLast4Hint => '4242';

  @override
  String get cardBrand => 'Card brand';

  @override
  String get cardBrandHint => 'visa, mastercard';

  @override
  String get addFundsTitle => 'Add Funds';

  @override
  String get selectPaymentMethod => 'Select a payment method';

  @override
  String get searchCountry => 'Search country';

  @override
  String get categoryGrocery => 'Grocery';

  @override
  String get categoryAmerican => 'American';

  @override
  String get categoryConvenience => 'Convenience';

  @override
  String get categoryAlcohol => 'Alcohol';

  @override
  String get categoryPetSupplies => 'Pet Supplies';

  @override
  String get categoryMore => 'More';

  @override
  String get pickupLocationLabel => 'Pickup Location';

  @override
  String get deliveryLocationLabel => 'Delivery Location';

  @override
  String get vehicleMotorcycle => 'Motorcycle';

  @override
  String get vehicleCar => 'Car';

  @override
  String get vehicleVan => 'Van';

  @override
  String get fromWallet => 'From Wallet';

  @override
  String get enterWithdrawAmount => 'Enter amount to withdraw';

  @override
  String get withdrawalMethod => 'Withdrawal Method';

  @override
  String get requestTitle => 'Title';

  @override
  String get requestTitleHint => 'e.g. Fix leaking faucet';

  @override
  String get requestDescription => 'Description';

  @override
  String get requestDescriptionHint =>
      'Describe the repair or maintenance needed';

  @override
  String get requestLocation => 'Location';

  @override
  String get requestLocationHint => 'Tap to select location';

  @override
  String get scheduledDateTime => 'Scheduled Date & Time';

  @override
  String get estimatedCostOptional => 'Estimated Cost (optional)';

  @override
  String get estimatedCostHint => 'e.g. 100';

  @override
  String get toolsNeeded => 'Tools needed (comma-separated)';

  @override
  String get toolsNeededHint => 'e.g. wrench set, plumber\'s tape';

  @override
  String get estimatedHoursOptional => 'Estimated hours (optional)';

  @override
  String get estimatedHoursHint => 'e.g. 2';

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get commentExperienceHint => 'Share your experience...';

  @override
  String get commentHandymanHint => 'e.g. Very professional and courteous';

  @override
  String get whatSending => 'What you are sending';

  @override
  String get recipient => 'Recipient';

  @override
  String get recipientContactNumber => 'Recipient contact number';

  @override
  String get payment => 'Payment';

  @override
  String get commentsIfAny => 'Your Comments if any....';

  @override
  String get walletNotFound => 'Wallet not found';

  @override
  String get quantity => 'Quantity';

  @override
  String get packageWeightKg => 'Package Weight (kg)';

  @override
  String get packageDescriptionOptional => 'Package Description (optional)';

  @override
  String get me => 'Me';

  @override
  String get recipientNames => 'Recipient Names';

  @override
  String get imagePickerTodo => 'Image picker will be implemented';

  @override
  String get pleaseSelectItemType => 'Please select item type';

  @override
  String get pleaseEnterQuantity => 'Please enter quantity';

  @override
  String get pleaseEnterValidWeight =>
      'Please enter a valid package weight (kg)';

  @override
  String get pleaseSelectPaymentType => 'Please select payment type';

  @override
  String get pleaseEnterRecipientName => 'Please enter recipient name';

  @override
  String get pleaseEnterRecipientPhone => 'Please enter recipient phone number';

  @override
  String get walletDetailName => 'Name';

  @override
  String get walletDetailType => 'Type';

  @override
  String get walletDetailScreenTitle => 'Wallet Details';

  @override
  String get walletInformation => 'Wallet Information';

  @override
  String get walletDetailCurrencyLabel => 'Currency';

  @override
  String get walletMyBalanceLabel => 'My balance';

  @override
  String get walletMyWalletsSection => 'My Wallets';

  @override
  String get walletRecentTransactions => 'Recent Transactions';

  @override
  String get walletSeeAll => 'See All';

  @override
  String get walletNoTransactionsYet => 'No transactions yet';

  @override
  String get walletAddMoney => 'Add Money';

  @override
  String get walletSendMoney => 'Send Money';

  @override
  String get withdrawFundsTitle => 'Withdraw Funds';

  @override
  String get walletNoWalletsForWithdraw =>
      'No wallets available to withdraw from';

  @override
  String get walletNoPaymentMethods => 'No payment methods available';

  @override
  String get validationEnterValidAmount => 'Enter a valid amount';

  @override
  String get validationAmountExceedsWalletBalance =>
      'Amount exceeds wallet balance';

  @override
  String get withdrawAction => 'Withdraw';

  @override
  String get selectWalletPrompt => 'Select a wallet';

  @override
  String get selectWithdrawalMethodPrompt => 'Select a withdrawal method';

  @override
  String get walletDefaultTransactionLabel => 'Transaction';

  @override
  String walletTypeCurrency(String type, String currency) {
    return '$type • $currency';
  }

  @override
  String get currencyEtb => 'ETB';

  @override
  String get balance => 'Balance';

  @override
  String get created => 'Created';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get featured => 'Featured';

  @override
  String get categories => 'Categories';

  @override
  String get orders => 'Orders';

  @override
  String get fruitsVegetables => 'Fruits & Vegetables';

  @override
  String get beverages => 'Beverages';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get noProducts => 'No products';

  @override
  String get searchStoresHint => 'Search stores and produ...';

  @override
  String get failedToAddFunds => 'Failed to add funds';

  @override
  String get failedToWithdrawFunds => 'Failed to withdraw funds';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get email => 'Email';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get emailAddress => 'Email address';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get referralCode => 'Referral code';

  @override
  String get searchQuestions => 'Search question';

  @override
  String get whereTo => 'Where to?';

  @override
  String get taxiCurrentLocation => 'Current location';

  @override
  String get taxiCouldNotGetLocationDetails => 'Could not get location details';

  @override
  String get taxiTimeNow => 'Now';

  @override
  String get taxiScheduleForLater => 'Schedule for later';

  @override
  String get taxiActiveRide => 'Active ride';

  @override
  String get taxiEstFare => 'Est. fare';

  @override
  String get taxiTrackRide => 'Track ride';

  @override
  String get taxiRefreshStatus => 'Refresh status';

  @override
  String taxiCarsNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cars nearby',
      one: '1 car nearby',
    );
    return '$_temp0';
  }

  @override
  String taxiMinutesWait(int minutes) {
    return '~$minutes min';
  }

  @override
  String get taxiBrandHudHud => 'HUDHUD';

  @override
  String get taxiBrandDelivery => ' delivery';

  @override
  String taxiDistanceKm(String distance) {
    return '$distance KM';
  }

  @override
  String get taxiGoogleMapsNotConfigured =>
      'Google Maps is not configured. Add GOOGLE_MAPS_API_KEY and restart the app.';

  @override
  String get taxiStatusFindingDriver => 'Finding a driver…';

  @override
  String get taxiStatusDriverOnTheWay => 'Driver on the way';

  @override
  String get taxiStatusDriverArrived => 'Driver has arrived';

  @override
  String get taxiStatusTripInProgress => 'Trip in progress';

  @override
  String get taxiStatusActiveRide => 'Active ride';

  @override
  String get taxiPickup => 'Pickup';

  @override
  String get taxiDestination => 'Destination';

  @override
  String taxiFareAmount(String amount) {
    return 'ETB $amount';
  }

  @override
  String taxiErrorWithDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String profileUpdateFailed(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String profileLoadFailed(String error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get servicesTryAgain => 'Try again';

  @override
  String unexpectedCheckoutError(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String failedOrderHistory(String error) {
    return 'Failed to load order history: $error';
  }

  @override
  String get timelineOrderPlaced => 'Order Placed';

  @override
  String get timelineOrderConfirmed => 'Order Confirmed';

  @override
  String get timelinePreparing => 'Preparing';

  @override
  String get timelineReadyPickup => 'Ready for Pickup';

  @override
  String get timelineOutDelivery => 'Out for Delivery';

  @override
  String get timelineDelivered => 'Delivered';

  @override
  String get addReviewOptional => 'Add a review (optional)';

  @override
  String get pleaseSpecify => 'Please specify...';

  @override
  String get courierNumber => 'Courier Number';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get deliveryDetailsStatus => 'Status';

  @override
  String get deliveryDetailsPickup => 'Pickup';

  @override
  String get deliveryDetailsDropoff => 'Dropoff';

  @override
  String get labelLocation => 'Location';

  @override
  String get labelInstructions => 'Instructions';

  @override
  String get labelReceiver => 'Receiver';

  @override
  String get labelPhone => 'Phone';

  @override
  String get labelPackage => 'Package';

  @override
  String get labelType => 'Type';

  @override
  String get labelDescription => 'Description';

  @override
  String get labelWeight => 'Weight';

  @override
  String get labelSpecialInstructions => 'Special instructions';

  @override
  String get paymentAndCost => 'Payment & Cost';

  @override
  String get labelPaymentMethod => 'Payment method';

  @override
  String get labelEstimatedCost => 'Estimated cost';

  @override
  String get labelPaymentStatus => 'Payment status';

  @override
  String get timeline => 'Timeline';

  @override
  String get labelScheduledPickup => 'Scheduled pickup';

  @override
  String get labelScheduledDelivery => 'Scheduled delivery';

  @override
  String get labelDelivered => 'Delivered';

  @override
  String get noEmailAvailable => 'No email available';

  @override
  String get noPhoneAvailable => 'No phone number available';

  @override
  String get emailVerificationTitle => 'Email Verification';

  @override
  String get phoneVerificationTitle => 'Phone Verification';

  @override
  String get enterEmailCode => 'Enter email code';

  @override
  String get enterSmsCode => 'Enter SMS code';

  @override
  String get noEmailAvailableShort => 'No email available';

  @override
  String get addMoney => 'Add Money';

  @override
  String get sendMoney => 'Send Money';

  @override
  String get exitAppTitle => 'Exit App';

  @override
  String get exitAppMessage => 'Are you sure you want to exit the app?';

  @override
  String get actionExit => 'Exit';

  @override
  String get loginNoAccountPrompt => 'Don\'t have an account? ';

  @override
  String get loginOrContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get actionSignUp => 'Sign Up';

  @override
  String get paymentScreenTitle => 'Payment';

  @override
  String get paymentChooseMethodHeading => 'Choose Payment Method';

  @override
  String get paymentEthiopianOptionsSubtitle =>
      'Select your preferred Ethiopian payment option';

  @override
  String get paymentLoadMethodsError => 'Failed to load payment methods';

  @override
  String get paymentSelectMethodFirst => 'Please select a payment method';

  @override
  String get paymentMethodUnavailable =>
      'Selected payment method is no longer available';

  @override
  String paymentFailedWithError(String error) {
    return 'Payment failed: $error';
  }

  @override
  String paymentPayAmountBr(String amount) {
    return 'Pay $amount Br';
  }

  @override
  String get paymentSuccessTitle => 'Payment Successful!';

  @override
  String paymentTransactionIdLabel(String id) {
    return 'Transaction ID: $id';
  }

  @override
  String get continueShopping => 'Continue Shopping';

  @override
  String get viewOrder => 'View Order';

  @override
  String get handymanServicesTitle => 'Handyman Services';

  @override
  String get handymanWhatToDo => 'What would you like to do?';

  @override
  String get handymanMyRequests => 'My Requests';

  @override
  String get handymanNoRequestsYet => 'No service requests yet';

  @override
  String get handymanNoRequestsSubtitle =>
      'Create a request to get quotes from handymen';

  @override
  String get handymanCreateNewRequest => 'Create New Request';

  @override
  String get handymanCreateRequestSubtitle =>
      'Describe your repair or maintenance need and get quotes from handymen.';

  @override
  String get instantDeliveryTitle => 'Instant Delivery';

  @override
  String get tapToSelectPickup => 'Tap to select pickup location';

  @override
  String get tapToSelectDelivery => 'Tap to select delivery location';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get selectPickupAndDelivery =>
      'Please select both pickup and delivery locations';

  @override
  String get actionContinue => 'Continue';

  @override
  String errorGettingAddress(String error) {
    return 'Error getting address: $error';
  }

  @override
  String get googleMapsIosMissingKey =>
      'Google Maps is not configured on iOS. Add GOOGLE_MAPS_API_KEY and restart the app.';

  @override
  String get dealsModalTitle => 'Deals on deals';

  @override
  String get dealsModalSubtitle =>
      'Get upto 50% off on your first Courier delivery fee!';

  @override
  String get dealsModalClaim => 'Claim';

  @override
  String get dealsModalClose => 'Maybe later';

  @override
  String get orderHistoryEmptyTitle => 'No orders yet';

  @override
  String get orderHistoryEmptySubtitle =>
      'Browse categories to place your first order.';

  @override
  String get orderHistoryEmptyHint =>
      'Your order history will appear here once you place an order';

  @override
  String get browseDelivery => 'Browse Delivery';

  @override
  String get browseCategories => 'Browse categories';

  @override
  String handymanQuoteCount(int count) {
    return '$count quote(s)';
  }

  @override
  String get orderDetailsLoadingMessage => 'Loading order details...';

  @override
  String get orderDetailsLoadErrorTitle => 'Error loading order details';

  @override
  String orderAppBarTitle(String orderNumber) {
    return 'Order #$orderNumber';
  }

  @override
  String get paymentSummaryTitle => 'Payment Summary';

  @override
  String get paymentSubtotalLabel => 'Subtotal';

  @override
  String get paymentTotalAmountLabel => 'Total Amount';

  @override
  String get paymentProcessingTitle => 'Processing Payment';

  @override
  String paymentProcessingMessage(String method) {
    return 'Please wait while we process your payment via $method...';
  }

  @override
  String courierRecipientLine(String name) {
    return 'Recipient: $name';
  }

  @override
  String get courierTrackDeliveryCta => 'Track delivery';

  @override
  String get courierDeliveryStatusInProgress => 'In progress';

  @override
  String get labelDate => 'Date';

  @override
  String get hintDateFormat => 'DD/MM/YYYY';

  @override
  String get labelTime => 'Time';

  @override
  String get hintTimeFormat => 'HH:MM';

  @override
  String get meridiemAm => 'am';

  @override
  String get meridiemPm => 'pm';

  @override
  String get scheduleSelectDateTime =>
      'Please select date and time for delivery';

  @override
  String get scheduleInvalidDateTime => 'Invalid date or time format';

  @override
  String get servicesScreenTitle => 'Our Services';

  @override
  String get servicesWhatCanWeHelp => 'What can we help you with?';

  @override
  String servicesAvailableCount(int count) {
    return '$count services available';
  }

  @override
  String get servicesErrorTitle => 'Something went wrong';

  @override
  String get servicesEmptyTitle => 'No services yet';

  @override
  String get servicesEmptySubtitle => 'Check back later for new services';

  @override
  String get handymanNewRequestTitle => 'New Service Request';

  @override
  String get validationHandymanSelectLocation => 'Please select a location';

  @override
  String get validationHandymanSelectDateTime => 'Please select date and time';

  @override
  String get validationHandymanSelectSkill =>
      'Please select at least one skill';

  @override
  String get handymanRequestCreatedToast => 'Request created';

  @override
  String get handymanRequestCreateFailed => 'Failed to create request';

  @override
  String get labelTitle => 'Title';

  @override
  String get hintTitleHandymanExample => 'e.g. Fix leaking faucet';

  @override
  String get validationTitleRequired => 'Title is required';

  @override
  String get validationDescriptionRequired => 'Description is required';

  @override
  String get hintDescribeRepair => 'Describe the repair or maintenance needed';

  @override
  String get handymanTapToSelectLocation => 'Tap to select location';

  @override
  String get labelScheduledDateTime => 'Scheduled Date & Time';

  @override
  String get selectDateAndTime => 'Select date and time';

  @override
  String get labelEstimatedCostOptional => 'Estimated Cost (optional)';

  @override
  String get hintCostExample => 'e.g. 100';

  @override
  String get handymanSkillsNeeded => 'Skills needed';

  @override
  String get handymanSkillPlumbing => 'Plumbing';

  @override
  String get handymanSkillElectrical => 'Electrical';

  @override
  String get handymanSkillCarpentry => 'Carpentry';

  @override
  String get handymanSkillPainting => 'Painting';

  @override
  String get handymanSkillGeneral => 'General';

  @override
  String get labelToolsCommaSeparated => 'Tools needed (comma-separated)';

  @override
  String get hintToolsHandymanExample => 'e.g. wrench set, plumber\'s tape';

  @override
  String get labelEstimatedHoursOptional => 'Estimated hours (optional)';

  @override
  String get hintHoursExample => 'e.g. 2';

  @override
  String get handymanCreateRequestCta => 'Create Request';

  @override
  String get handymanDialogCancelRequestTitle => 'Cancel Request';

  @override
  String get handymanDialogCancelRequestMessage =>
      'Are you sure you want to cancel this service request?';

  @override
  String get actionNo => 'No';

  @override
  String get actionYesCancel => 'Yes, Cancel';

  @override
  String get handymanRequestCancelled => 'Request cancelled';

  @override
  String get handymanCancelFailed => 'Failed to cancel';

  @override
  String get handymanLabelScheduled => 'Scheduled';

  @override
  String get handymanSectionRequirements => 'Requirements';

  @override
  String handymanToolsLine(String tools) {
    return 'Tools: $tools';
  }

  @override
  String handymanEstHoursLine(String hours) {
    return 'Est. hours: $hours';
  }

  @override
  String handymanViewQuotesCta(int count) {
    return 'View $count quote(s)';
  }

  @override
  String get handymanCancelRequest => 'Cancel Request';

  @override
  String get handymanRateServiceTitle => 'Rate Service';

  @override
  String get handymanProviderFallback => 'Provider';

  @override
  String get handymanQuotesTitle => 'Quotes';

  @override
  String get handymanAcceptQuoteTitle => 'Accept Quote';

  @override
  String handymanAcceptQuoteMessage(String amount, String name) {
    return 'Accept $amount from $name?';
  }

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionReject => 'Reject';

  @override
  String get handymanQuoteAccepted => 'Quote accepted';

  @override
  String get handymanAcceptQuoteFailed => 'Failed to accept';

  @override
  String get handymanRejectQuoteTitle => 'Reject Quote';

  @override
  String handymanRejectQuoteMessage(String name) {
    return 'Reject quote from $name?';
  }

  @override
  String get handymanQuoteRejected => 'Quote rejected';

  @override
  String get handymanRejectQuoteFailed => 'Failed to reject';

  @override
  String get handymanNoQuotesYet => 'No quotes yet';

  @override
  String get handymanNoQuotesSubtitle => 'Handymen will send quotes soon';

  @override
  String get handymanViewProfile => 'View Profile';

  @override
  String get handymanHowWasService => 'How was the service?';

  @override
  String get handymanRateTheHandyman => 'Rate the handyman';

  @override
  String get handymanCommentAboutOptional =>
      'Comment about handyman (optional)';

  @override
  String get handymanRatingPublic => 'Make my rating public';

  @override
  String get handymanSubmitRating => 'Submit Rating';

  @override
  String get ratingThankYou => 'Thank you for your rating!';

  @override
  String get ratingSubmitFailed => 'Failed to submit rating';

  @override
  String get handymanNotFound => 'Handyman not found';

  @override
  String get handymanProfileTitle => 'Handyman Profile';

  @override
  String get handymanAbout => 'About';

  @override
  String get handymanSkillsHeading => 'Skills';

  @override
  String get handymanHourlyRateLabel => 'Hourly Rate';

  @override
  String get handymanExperienceLabel => 'Experience';

  @override
  String handymanExperienceYears(String years) {
    return '$years years';
  }

  @override
  String get labelAddress => 'Address';

  @override
  String get handymanStatsHeading => 'Stats';

  @override
  String get handymanStatServices => 'Services';

  @override
  String get handymanStatRating => 'Rating';

  @override
  String get handymanStatResponse => 'Response';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordRequestTitle => 'Reset password';

  @override
  String get forgotPasswordRequestSubtitle =>
      'Enter your email or phone number. We\'ll send a 6-digit verification code.';

  @override
  String get forgotPasswordSendCode => 'Send code';

  @override
  String get forgotPasswordVerifyTitle => 'Enter verification code';

  @override
  String forgotPasswordVerifySubtitle(String identifier) {
    return 'We sent a code to $identifier.';
  }

  @override
  String get forgotPasswordOtpLabel => '6-digit code';

  @override
  String forgotPasswordTimeRemaining(String time) {
    return 'Time remaining: $time';
  }

  @override
  String get forgotPasswordCodeExpired =>
      'This code has expired. Tap resend for a new code.';

  @override
  String get forgotPasswordResend => 'Resend code';

  @override
  String get forgotPasswordVerifyButton => 'Verify';

  @override
  String get forgotPasswordNewTitle => 'Create new password';

  @override
  String get forgotPasswordNewSubtitle => 'Use at least 8 characters.';

  @override
  String get forgotPasswordLabelConfirmPassword => 'Confirm password';

  @override
  String get forgotPasswordHintConfirmPassword => 'Re-enter new password';

  @override
  String get forgotPasswordSaveButton => 'Save password';

  @override
  String get forgotPasswordSuccessMessage =>
      'Password updated. You can sign in now.';

  @override
  String get validationOtpLength => 'Enter the 6-digit code';

  @override
  String get validationConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';
}
