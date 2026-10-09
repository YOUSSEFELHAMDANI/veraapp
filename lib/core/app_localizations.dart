import 'package:flutter/material.dart';

import 'l10n/strings_ar.dart';
import 'l10n/strings_en.dart';
import 'l10n/strings_fr.dart';
import 'l10n/strings_ur.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  bool get isArabic => locale.languageCode == 'ar';
  bool get isRtl => const {'ar', 'ur'}.contains(locale.languageCode);

  static const List<String> supportedLanguageCodes = ['en', 'ar', 'fr', 'ur'];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String t(String key, {Map<String, String>? args}) {
    String text;
    switch (locale.languageCode) {
      case 'ar':
        text = stringsAr[key] ?? stringsEn[key] ?? key;
        break;
      case 'fr':
        text = stringsFr[key] ?? stringsEn[key] ?? key;
        break;
      case 'ur':
        text = stringsUr[key] ?? stringsEn[key] ?? key;
        break;
      default:
        text = stringsEn[key] ?? key;
    }
    if (args != null) {
      args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }

  String get localeCode => locale.languageCode;

  // ── General ──────────────────────────────────────────────────
  String get appName => t('appName');
  String get continueText => t('continueText');
  String get cancel => t('cancel');
  String get save => t('save');
  String get edit => t('edit');
  String get delete => t('delete');
  String get confirm => t('confirm');
  String get back => t('back');
  String get done => t('done');
  String get search => t('search');
  String get filter => t('filter');
  String get seeAll => t('seeAll');
  String get loading => t('loading');
  String get error => t('error');
  String get retry => t('retry');
  String get noResults => t('noResults');
  String get submit => t('submit');
  String get close => t('close');
  String get yes => t('yes');
  String get no => t('no');
  String get or => t('or');
  String get optional => t('optional');
  String get required => t('required');
  String get success => t('success');
  String get warning => t('warning');
  String get info => t('info');

  // ── Auth ──────────────────────────────────────────────────────
  String get login => t('login');
  String get logout => t('logout');
  String get register => t('register');
  String get createAccount => t('createAccount');
  String get email => t('email');
  String get call => t('call');
  String get password => t('password');
  String get confirmPassword => t('confirmPassword');
  String get forgotPassword => t('forgotPassword');
  String get resetPassword => t('resetPassword');
  String get fullName => t('fullName');
  String get phoneNumber => t('phoneNumber');
  String get signInWithGoogle => t('signInWithGoogle');
  String get signInWithApple => t('signInWithApple');
  String get appleSignInFailed => t('appleSignInFailed');
  String get alreadyHaveAccount => t('alreadyHaveAccount');
  String get signIn => t('signIn');
  String get signUp => t('signUp');
  String get welcomeBack => t('welcomeBack');
  String get enterEmail => t('enterEmail');
  String get enterPassword => t('enterPassword');
  String get rememberMe => t('rememberMe');

  // ── Navigation ────────────────────────────────────────────────
  String get home => t('home');
  String get profile => t('profile');
  String get favorites => t('favorites');
  String get notifications => t('notifications');
  String get settings => t('settings');
  String get cart => t('cart');
  String get wishlist => t('wishlist');

  // ── Home ──────────────────────────────────────────────────────
  String get goodMorning => t('goodMorning');
  String get goodAfternoon => t('goodAfternoon');
  String get goodEvening => t('goodEvening');
  String get featuredServices => t('featuredServices');
  String get topProviders => t('topProviders');
  String get categories => t('categories');
  String get searchHint => t('searchHint');
  String get exploreAll => t('exploreAll');
  String get toVera => t('toVera');
  String get aiAssistantTitle => t('aiAssistantTitle');
  String get aiAssistantSubtitle => t('aiAssistantSubtitle');
  String get searchHintHome => t('searchHintHome');
  String get bestSellers => t('bestSellers');
  String get bestSeller => t('bestSeller');
  String get mostViewed => t('mostViewed');
  String get ourRecommendations => t('ourRecommendations');
  String get forYou => t('forYou');
  String get view => t('view');
  String get priceOnRequest => t('priceOnRequest');
  String get free => t('free');
  String get services => t('services');
  String currencyAed(String value) => t('currencyAed', args: {'value': value});
  String profilePhotoOf(String name) =>
      t('profilePhotoOf', args: {'name': name});
  String serviceImageLabel(String name) =>
      t('serviceImageLabel', args: {'name': name});
  String providerLogoLabel(String name) =>
      t('providerLogoLabel', args: {'name': name});
  String bannerSemanticLabel(String title) =>
      t('bannerSemanticLabel', args: {'title': title});

  // ── Category / Splash ─────────────────────────────────────────
  String get allLabel => t('allLabel');
  String get clinicsAndSalons => t('clinicsAndSalons');
  String get findJobs => t('findJobs');
  String get salonsAndBeauty => t('salonsAndBeauty');
  String get catDiscoverYourStyle => t('catDiscoverYourStyle');
  String get catFindYourDreamHome => t('catFindYourDreamHome');
  String get catBookYourWellness => t('catBookYourWellness');
  String get catFindTheRightJob => t('catFindTheRightJob');
  String get gymFitness => t('gymFitness');
  String get beautyServices => t('beautyServices');
  String productsAvailable(String count) =>
      t('productsAvailable', args: {'count': count});
  String propertiesAvailable(String count) =>
      t('propertiesAvailable', args: {'count': count});
  String servicesAvailable(String count) =>
      t('servicesAvailable', args: {'count': count});
  String jobsAvailableToday(String count) =>
      t('jobsAvailableToday', args: {'count': count});
  String facilitiesClassesAvailable(String count) =>
      t('facilitiesClassesAvailable', args: {'count': count});
  String salonsServicesAvailable(String count) =>
      t('salonsServicesAvailable', args: {'count': count});
  String get shopNow => t('shopNow');
  String get browseNow => t('browseNow');
  String get exploreJobs => t('exploreJobs');
  String get searchFashionBrands => t('searchFashionBrands');
  String get searchPropertiesAreas => t('searchPropertiesAreas');
  String get searchClinicsSalonsServices => t('searchClinicsSalonsServices');
  String get searchJobsCompaniesSkills => t('searchJobsCompaniesSkills');
  String get searchGymsSportsTrainers => t('searchGymsSportsTrainers');
  String get searchSalonsServicesStylists => t('searchSalonsServicesStylists');
  String get propertyTypes => t('propertyTypes');
  String get serviceTypes => t('serviceTypes');
  String get popularCategories => t('popularCategories');
  String get recommendedForYou => t('recommendedForYou');
  String get featuredProperties => t('featuredProperties');
  String get topProvidersNearYou => t('topProvidersNearYou');
  String resultsCountText(String count) =>
      t('resultsCountText', args: {'count': count});
  String salonsFound(String count) => t('salonsFound', args: {'count': count});
  String get noProductsFound => t('noProductsFound');
  String get noPropertiesFound => t('noPropertiesFound');
  String get noServicesFound => t('noServicesFound');
  String get noJobsFound => t('noJobsFound');
  String get noFacilitiesFound => t('noFacilitiesFound');
  String get noSalonsFound => t('noSalonsFound');
  String get tryAdjustingFilters => t('tryAdjustingFilters');
  String get errorLoadProducts => t('errorLoadProducts');
  String get errorLoadProperties => t('errorLoadProperties');
  String get errorLoadServices => t('errorLoadServices');
  String get errorLoadJobs => t('errorLoadJobs');
  String get errorLoadFacilities => t('errorLoadFacilities');
  String get errorLoadSalons => t('errorLoadSalons');
  String get allJobsLabel => t('allJobsLabel');
  String get topRated => t('topRated');
  String get statusOpen => t('statusOpen');
  String get statusClosed => t('statusClosed');
  String get openNow => t('openNow');
  String get beds => t('beds');
  String get baths => t('baths');
  String heroImageLabel(String title) =>
      t('heroImageLabel', args: {'title': title});
  String rowCardLabel(String name, String category) =>
      t('rowCardLabel', args: {'name': name, 'category': category});
  String productPhotoLabel(String title) =>
      t('productPhotoLabel', args: {'title': title});
  String propertyExteriorLabel(String title) =>
      t('propertyExteriorLabel', args: {'title': title});
  String salonInteriorLabel(String name) =>
      t('salonInteriorLabel', args: {'name': name});
  String companyLogoLabel(String company) =>
      t('companyLogoLabel', args: {'company': company});
  String get sort => t('sort');

  // ── Real Estate ───────────────────────────────────────────────
  String get realEstate => t('realEstate');
  String get fashion => t('fashion');
  String get clinics => t('clinics');
  String get gym => t('gym');
  String get jobs => t('jobs');
  String get salons => t('salons');
  String get properties => t('properties');
  String get propertyDetails => t('propertyDetails');
  String get bedrooms => t('bedrooms');
  String get bathrooms => t('bathrooms');
  String get area => t('area');
  String get price => t('price');
  String get location => t('location');
  String get bookViewing => t('bookViewing');
  String get contact => t('contact');
  String get amenities => t('amenities');
  String get description => t('description');
  String get forSale => t('forSale');
  String get forRent => t('forRent');
  String get perMonth => t('perMonth');
  String get perYear => t('perYear');

  // ── Fashion ───────────────────────────────────────────────────
  String get fashionHub => t('fashionHub');
  String get newArrivals => t('newArrivals');
  String get trending => t('trending');
  String get addToCart => t('addToCart');
  String get buyNow => t('buyNow');
  String get size => t('size');
  String get color => t('color');
  String get quantity => t('quantity');
  String get inStock => t('inStock');
  String get outOfStock => t('outOfStock');

  // ── Clinics ───────────────────────────────────────────────────
  String get doctors => t('doctors');
  String get bookAppointment => t('bookAppointment');
  String get myAppointments => t('myAppointments');
  String get specialization => t('specialization');
  String get experience => t('experience');
  String get rating => t('rating');
  String get reviews => t('reviews');
  String get available => t('available');
  String get unavailable => t('unavailable');

  // ── Gym ───────────────────────────────────────────────────────
  String get gymSports => t('gymSports');
  String get membership => t('membership');
  String get classes => t('classes');
  String get trainer => t('trainer');
  String get schedule => t('schedule');
  String get bookClass => t('bookClass');

  // ── Jobs ──────────────────────────────────────────────────────
  String get jobListings => t('jobListings');
  String get jobDetails => t('jobDetails');
  String get applyNow => t('applyNow');
  String get salary => t('salary');
  String get jobType => t('jobType');
  String get company => t('company');
  String get uploadCv => t('uploadCv');
  String get myApplications => t('myApplications');
  String get fullTime => t('fullTime');
  String get partTime => t('partTime');
  String get remote => t('remote');

  // ── Salons ────────────────────────────────────────────────────
  String get salonServices => t('salonServices');
  String get bookSalon => t('bookSalon');
  String get hairCare => t('hairCare');
  String get skinCare => t('skinCare');
  String get nailCare => t('nailCare');
  String get makeUp => t('makeUp');

  // ── Booking ───────────────────────────────────────────────────
  String get booking => t('booking');
  String get myBookings => t('myBookings');
  String get bookNow => t('bookNow');
  String get date => t('date');
  String get time => t('time');
  String get duration => t('duration');
  String get upcoming => t('upcoming');
  String get past => t('past');
  String get cancelled => t('cancelled');
  String get confirmed => t('confirmed');
  String get pending => t('pending');
  String get completed => t('completed');

  // ── Checkout / Orders ─────────────────────────────────────────
  String get checkout => t('checkout');
  String get orderSummary => t('orderSummary');
  String get subtotal => t('subtotal');
  String get total => t('total');
  String get discount => t('discount');
  String get promoCode => t('promoCode');
  String get applyPromo => t('applyPromo');
  String get paymentMethod => t('paymentMethod');
  String get placeOrder => t('placeOrder');
  String get myOrders => t('myOrders');
  String get orderDetails => t('orderDetails');
  String get deliveryAddress => t('deliveryAddress');

  // ── Profile / Settings ────────────────────────────────────────
  String get editProfile => t('editProfile');
  String get personalInfo => t('personalInfo');
  String get language => t('language');
  String get country => t('country');
  String get currency => t('currency');
  String get helpSupport => t('helpSupport');
  String get privacyPolicy => t('privacyPolicy');
  String get termsConditions => t('termsConditions');
  String get aboutUs => t('aboutUs');

  // ── Profile / Settings extras ─────────────────────────────────
  String get settingsLanguageRegion => t('settingsLanguageRegion');
  String get settingsPrivacyLegal => t('settingsPrivacyLegal');
  String get settingsDangerZone => t('settingsDangerZone');
  String get appearance => t('appearance');
  String get themeSystem => t('themeSystem');
  String get themeLight => t('themeLight');
  String get themeDark => t('themeDark');
  String get pushNotifications => t('pushNotifications');
  String get pushNotificationsSubtitle => t('pushNotificationsSubtitle');
  String get emailNotifications => t('emailNotifications');
  String get emailNotificationsSubtitle => t('emailNotificationsSubtitle');
  String get smsNotifications => t('smsNotifications');
  String get smsNotificationsSubtitle => t('smsNotificationsSubtitle');
  String get orderUpdates => t('orderUpdates');
  String get orderUpdatesSubtitle => t('orderUpdatesSubtitle');
  String get promotionsOffers => t('promotionsOffers');
  String get promotionsOffersSubtitle => t('promotionsOffersSubtitle');
  String get bookingReminders => t('bookingReminders');
  String get bookingRemindersSubtitle => t('bookingRemindersSubtitle');
  String get noPaymentMethods => t('noPaymentMethods');
  String get defaultLabel => t('defaultLabel');
  String expiresLabel(String date) => t('expiresLabel', args: {'date': date});
  String get addPaymentMethod => t('addPaymentMethod');
  String get removeCard => t('removeCard');
  String get removeCardConfirm => t('removeCardConfirm');
  String get remove => t('remove');
  String get cookiePolicy => t('cookiePolicy');
  String get deleteAccount => t('deleteAccount');
  String get deleteAccountSubtitle => t('deleteAccountSubtitle');
  String get deleteAccountWarning => t('deleteAccountWarning');
  String get typeDeleteConfirm => t('typeDeleteConfirm');
  String openingUrl(String url) => t('openingUrl', args: {'url': url});
  String get cardAdded => t('cardAdded');
  String get cardRemoved => t('cardRemoved');
  String get myProfile => t('myProfile');
  String get myActivity => t('myActivity');
  String get myFavorites => t('myFavorites');
  String get finance => t('finance');
  String get account => t('account');
  String get walletBnpl => t('walletBnpl');
  String get loyaltyPoints => t('loyaltyPoints');
  String get privacySettings => t('privacySettings');
  String get customerSupport => t('customerSupport');
  String get signOut => t('signOut');
  String get signOutConfirm => t('signOutConfirm');
  String get veraMember => t('veraMember');
  String get avatarUpdateFailed => t('avatarUpdateFailed');
  String get pointsAbbr => t('pointsAbbr');
  String get loyaltyTitle => t('loyaltyTitle');
  String get loyaltyBalance => t('loyaltyBalance');
  String get yourLevel => t('yourLevel');
  String get redeemTitle => t('redeemTitle');
  String get redeemSubtitle => t('redeemSubtitle');
  String get redeemNow => t('redeemNow');
  String get redeemSuccess => t('redeemSuccess');
  String get redeemMinError => t('redeemMinError');
  String get redeemBalanceError => t('redeemBalanceError');
  String get noLoyaltyHistory => t('noLoyaltyHistory');
  String get activityHistory => t('activityHistory');
  String get earned => t('earned');
  String get redeemed => t('redeemed');
  String get bronzeLevel => t('bronzeLevel');
  String get silverLevel => t('silverLevel');
  String get goldLevel => t('goldLevel');
  String get walletTitle => t('walletTitle');
  String get walletBalanceTitle => t('walletBalanceTitle');
  String get topUp => t('topUp');
  String get topUpAmount => t('topUpAmount');
  String get topUpSuccess => t('topUpSuccess');
  String get topUpFailed => t('topUpFailed');
  String get topUpMinError => t('topUpMinError');
  String get walletNoTransactions => t('walletNoTransactions');
  String get payWithWalletTitle => t('payWithWalletTitle');
  String get walletInsufficient => t('walletInsufficient');
  String get onLabel => t('onLabel');
  String get offLabel => t('offLabel');
  String get orders => t('orders');
  String get bookings => t('bookings');
  String get points => t('points');

  // ── AI Assistant ──────────────────────────────────────────────
  String get aiAssistant => t('aiAssistant');
  String get typeMessage => t('typeMessage');
  String get send => t('send');
  String get voiceSearch => t('voiceSearch');
  String get imageSearch => t('imageSearch');

  // ── Onboarding ────────────────────────────────────────────────
  String get getStarted => t('getStarted');
  String get skip => t('skip');
  String get next => t('next');
  String get welcomeToVera => t('welcomeToVera');
  String get selectLanguageCountry => t('selectLanguageCountry');
  String get selectLanguage => t('selectLanguage');
  String get selectCountry => t('selectCountry');
  String get searchCountry => t('searchCountry');
  String get popularCountries => t('popularCountries');
  String get allCountries => t('allCountries');
  String get comingSoon => t('comingSoon');
  String get arabic => t('arabic');
  String get english => t('english');
  String get french => t('french');
  String get urdu => t('urdu');

  // ── Provider ──────────────────────────────────────────────────
  String get providerLogin => t('providerLogin');
  String get providerDashboard => t('providerDashboard');
  String get providerProfile => t('providerProfile');
  String get providerServices => t('providerServices');
  String get providerOrders => t('providerOrders');
  String get subscriptions => t('subscriptions');
  String get addService => t('addService');
  String get manageServices => t('manageServices');
  String get mapView => t('mapView');
  String get nearbyServices => t('nearbyServices');
  String get directions => t('directions');
  String get accountManager => t('accountManager');
  String get accountManagerNotAssigned => t('accountManagerNotAssigned');
  String get accountManagerSubtitle => t('accountManagerSubtitle');
  String get whatsApp => t('whatsApp');

  // ── Payments ──────────────────────────────────────────────────
  String get paymentMethods => t('paymentMethods');
  String get addCard => t('addCard');
  String get cardNumber => t('cardNumber');
  String get expiryDate => t('expiryDate');
  String get cvv => t('cvv');
  String get cardHolder => t('cardHolder');
  String get creditCard => t('creditCard');
  String get debitCard => t('debitCard');
  String get cash => t('cash');

  // ── Notifications ─────────────────────────────────────────────
  String get allNotifications => t('allNotifications');
  String get markAllRead => t('markAllRead');
  String get noNotifications => t('noNotifications');

  // ── Search ────────────────────────────────────────────────────
  String get searchResults => t('searchResults');
  String get recentSearches => t('recentSearches');
  String get popularSearches => t('popularSearches');
  String get noSearchResults => t('noSearchResults');
  String get tryDifferentKeyword => t('tryDifferentKeyword');

  // ── Reviews ───────────────────────────────────────────────────
  String get writeReview => t('writeReview');
  String get yourReview => t('yourReview');
  String get submitReview => t('submitReview');
  String get reviewsCount => t('reviewsCount');

  // ── Auth flow (login / register / OTP / forgot password) ──────
  String get verifyLogin => t('verifyLogin');
  String get loginFailed => t('loginFailed');
  String get somethingWentWrong => t('somethingWentWrong');
  String get googleSignInFailed => t('googleSignInFailed');
  String get googleSignInUnavailable => t('googleSignInUnavailable');
  String get signInToVeraAccount => t('signInToVeraAccount');
  String get emailExample => t('emailExample');
  String get emailRequired => t('emailRequired');
  String get emailInvalid => t('emailInvalid');
  String get passwordRequired => t('passwordRequired');
  String get minCharacters6 => t('minCharacters6');
  String get continueAsGuest => t('continueAsGuest');
  String get dontHaveAccount => t('dontHaveAccount');
  String get createOne => t('createOne');
  String get signInAsProvider => t('signInAsProvider');
  String get createProviderAccount => t('createProviderAccount');
  String get verifyEmail => t('verifyEmail');
  String get accountCreatedSignIn => t('accountCreatedSignIn');
  String get registrationFailed => t('registrationFailed');
  String get joinVeraDiscover => t('joinVeraDiscover');
  String get yourFullName => t('yourFullName');
  String get nameRequired => t('nameRequired');
  String get nameTooShort => t('nameTooShort');
  String get phoneExample => t('phoneExample');
  String get phoneNumberHint => t('phoneNumberHint');
  String get phoneCountryCode => t('phoneCountryCode');
  String get phoneInvalidForCountry => t('phoneInvalidForCountry');
  String get emailAlreadyRegistered => t('emailAlreadyRegistered');
  String get otpIncorrectCode => t('otpIncorrectCode');
  String get otpCodeExpired => t('otpCodeExpired');
  String get otpMaxAttempts => t('otpMaxAttempts');
  String get otpRegistrationSessionExpired => t('otpRegistrationSessionExpired');
  String get pwMinLength => t('pwMinLength');
  String get pwUppercase => t('pwUppercase');
  String get pwLowercase => t('pwLowercase');
  String get pwNumber => t('pwNumber');
  String get pwSpecial => t('pwSpecial');
  String get pwInvalidMessage => t('pwInvalidMessage');
  String get tapToStop => t('tapToStop');
  String get processingVoice => t('processingVoice');
  String get micPermissionDenied => t('micPermissionDenied');
  String get voiceSearchFailed => t('voiceSearchFailed');
  String get chooseImageSource => t('chooseImageSource');
  String get takePhoto => t('takePhoto');
  String get chooseFromGallery => t('chooseFromGallery');
  String get searchingWithImage => t('searchingWithImage');
  String get smartSearch => t('smartSearch');
  String get smartSearchSubtitle => t('smartSearchSubtitle');
  String get searchWithVoice => t('searchWithVoice');
  String get searchWithImage => t('searchWithImage');
  String get priceFrom => t('priceFrom');
  String get inProgress => t('inProgress');

  /// Translates system-generated order/booking/appointment status labels
  /// (produced by the API service layer) into the current UI language.
  String localizeStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'upcoming') return upcoming;
    if (s == 'completed' || s == 'done' || s == 'fulfilled') return completed;
    if (s == 'cancelled' || s == 'canceled' || s == 'rejected') return cancelled;
    if (s == 'pending') return pending;
    if (s == 'confirmed' || s == 'booked' || s == 'reserved') return confirmed;
    if (s == 'in progress' || s == 'inprogress') return inProgress;
    return raw;
  }

  /// Translates system-generated price/salary labels (produced by the API
  /// service layer) into the current UI language.
  String localizePrice(String raw) {
    final value = raw.trim();
    if (value == 'Price on request' ||
        value == 'On request' ||
        value == 'price on request') {
      return priceOnRequest;
    }
    if (value == 'Free') return free;
    if (value.startsWith('From ')) {
      return priceFrom.replaceFirst('{price}', value.substring(5).trim());
    }
    return value;
  }

  /// Translates system-generated listing badge labels into the current UI
  /// language.
  String localizeBadge(String raw) {
    if (raw == 'For Sale') return t('forSale');
    if (raw == 'For Rent') return t('forRent');
    return raw;
  }

  String get phoneRequired => t('phoneRequired');
  String get phoneInvalid => t('phoneInvalid');
  String get min8Characters => t('min8Characters');
  String get minCharacters8 => t('minCharacters8');
  String get reEnterPassword => t('reEnterPassword');
  String get pleaseConfirmPassword => t('pleaseConfirmPassword');
  String get passwordsDoNotMatch => t('passwordsDoNotMatch');
  String get signUpWithGoogle => t('signUpWithGoogle');
  String get pleaseEnter6DigitCode => t('pleaseEnter6DigitCode');
  String get passwordMin8Chars => t('passwordMin8Chars');
  String get unableResetPassword => t('unableResetPassword');
  String get unableUpdatePassword => t('unableUpdatePassword');
  String get passwordUpdatedSignIn => t('passwordUpdatedSignIn');
  String get emailVerified => t('emailVerified');
  String get providerApprovalPending => t('providerApprovalPending');
  String get goToSignIn => t('goToSignIn');
  String get codeExpired => t('codeExpired');
  String get newPassword => t('newPassword');
  String get verify => t('verify');
  String get resendCode => t('resendCode');
  String get forgotPasswordInstructions => t('forgotPasswordInstructions');
  String get sendCode => t('sendCode');
  String get rememberYourPassword => t('rememberYourPassword');
  String get checkYourEmail => t('checkYourEmail');
  String get resetEmailInstructions => t('resetEmailInstructions');
  String get backToSignIn => t('backToSignIn');
  String get didntReceiveTryAgain => t('didntReceiveTryAgain');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
