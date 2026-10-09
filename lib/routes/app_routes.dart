import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_session.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/language_country_screen/language_country_screen.dart';
import '../presentation/search_screen/search_screen.dart';
import '../presentation/offers_screen/offers_screen.dart';
import '../presentation/cart_and_checkout_screen/cart_and_checkout_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/category_screen/category_screen.dart';
import '../presentation/fashion_screen/fashion_screen.dart';
import '../presentation/booking_screen/booking_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/wishlist_screen/wishlist_screen.dart';
import '../presentation/my_bookings_screen/my_bookings_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/register_screen/register_screen.dart';
import '../presentation/forgot_password_screen/forgot_password_screen.dart';
import '../presentation/otp_screen/otp_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/provider_login_screen/provider_login_screen.dart';
import '../presentation/provider_dashboard_screen/provider_dashboard_screen.dart';
import '../presentation/provider_profile_screen/provider_profile_screen.dart';
import '../presentation/provider_services_screen/provider_services_screen.dart';
import '../presentation/provider_subscriptions_screen/provider_subscriptions_screen.dart';
import '../presentation/provider_plans_screen/provider_plans_screen.dart';
import '../presentation/order_tracking_screen/order_tracking_screen.dart';
import '../presentation/provider_orders_screen/provider_orders_screen.dart';
import '../presentation/provider_account_manager_chat_screen/provider_account_manager_chat_screen.dart';
import '../presentation/provider_register_screen/provider_register_screen.dart';
import '../presentation/upload_cv_screen/upload_cv_screen.dart';
import '../presentation/job_details_screen/job_details_screen.dart';
import '../presentation/apply_job_screen/apply_job_screen.dart';
import '../presentation/my_applications_screen/my_applications_screen.dart';
import '../presentation/favorites_screen/favorites_screen.dart';
import '../presentation/real_estate_details_screen/real_estate_details_screen.dart';
import '../presentation/real_estate_home_screen/real_estate_home_screen.dart';
import '../presentation/jobs_home_screen/jobs_home_screen.dart';
import '../presentation/book_property_screen/book_property_screen.dart';
import '../presentation/fashion_details_screen/fashion_details_screen.dart';
import '../presentation/my_orders_screen/my_orders_screen.dart';
import '../presentation/clinic_details_screen/clinic_details_screen.dart';
import '../presentation/my_appointments_screen/my_appointments_screen.dart';
import '../presentation/provider_add_new_screen/provider_add_new_screen.dart';
import '../presentation/provider_product_wizard_screen/provider_product_wizard_screen.dart';
import '../presentation/provider_service_wizard_screen/provider_service_wizard_screen.dart';
import '../presentation/provider_import_screen/provider_import_screen.dart';
import '../presentation/provider_catalog_screen/provider_catalog_screen.dart';
import '../presentation/gym_sports_details_screen/gym_sports_details_screen.dart';
import '../presentation/book_gym_screen/book_gym_screen.dart';
import '../presentation/ai_assistant_screen/ai_assistant_screen.dart';
import '../presentation/salon_details_screen/salon_details_screen.dart';
import '../presentation/book_salon_screen/book_salon_screen.dart';
import '../presentation/reviews_screen/reviews_screen.dart';
import '../presentation/payment_methods_screen/payment_methods_screen.dart';
import '../widgets/app_scaffold.dart';
import '../presentation/public_provider_profile_screen/public_provider_profile_screen.dart';
import '../presentation/all_providers_screen/all_providers_screen.dart';
import '../presentation/payment_result_screen/payment_result_screen.dart';
import '../presentation/wallet_screen/wallet_screen.dart';
import '../presentation/map_view_screen/map_view_screen.dart';
import '../presentation/loyalty_screen/loyalty_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String languageCountryScreen = '/language-country-screen';
  static const String onboardingScreen = '/onboarding-screen';
  static const String homeScreen = '/home-screen';
  static const String searchScreen = '/search-screen';
  static const String offersScreen = '/offers-screen';
  static const String cartAndCheckoutScreen = '/cart-and-checkout-screen';
  static const String profileScreen = '/profile-screen';
  static const String jobsScreen = '/jobs-screen';
  static const String jobsHomeScreen = '/jobs-home-screen';
  static const String jobsListingScreen = '/jobs-listing-screen';
  static const String fashionScreen = '/fashion-screen';
  static const String bookingScreen = '/booking-screen';
  static const String notificationsScreen = '/notifications-screen';
  static const String wishlistScreen = '/wishlist-screen';
  static const String myBookingsScreen = '/my-bookings-screen';
  static const String loginScreen = '/login-screen';
  static const String registerScreen = '/register-screen';
  static const String forgotPasswordScreen = '/forgot-password-screen';
  static const String otpScreen = '/otp-screen';
  static const String settingsScreen = '/settings-screen';
  static const String providerLoginScreen = '/provider-login-screen';
  static const String providerDashboardScreen = '/provider-dashboard-screen';
  static const String providerProfileScreen = '/provider-profile-screen';
  static const String providerServicesScreen = '/provider-services-screen';
  static const String providerSubscriptionsScreen =
      '/provider-subscriptions-screen';
  static const String providerPlansScreen = '/provider-plans-screen';
  static const String orderTrackingScreen = '/order-tracking-screen';
  static const String providerOrdersScreen = '/provider-orders-screen';
  static const String providerAccountManagerChatScreen =
      '/provider-account-manager-chat-screen';
  static const String providerAddNewScreen = '/provider-add-new-screen';
  static const String providerProductWizardScreen =
      '/provider-product-wizard-screen';
  static const String providerServiceWizardScreen =
      '/provider-service-wizard-screen';
  static const String providerImportScreen = '/provider-import-screen';
  static const String providerCatalogScreen = '/provider-catalog-screen';
  static const String providerRegisterScreen = '/provider-register-screen';
  static const String uploadCvScreen = '/upload-cv-screen';
  static const String jobDetailsScreen = '/job-details-screen';
  static const String applyJobScreen = '/apply-job-screen';
  static const String myApplicationsScreen = '/my-applications-screen';
  static const String favoritesScreen = '/favorites-screen';
  static const String realEstateScreen = '/real-estate-screen';
  static const String realEstateListingScreen = '/real-estate-listing-screen';
  static const String realEstateDetailsScreen = '/real-estate-details-screen';
  static const String bookPropertyScreen = '/book-property-screen';
  static const String fashionHubScreen = '/fashion-hub-screen';
  static const String fashionDetailsScreen = '/fashion-details-screen';
  static const String myOrdersScreen = '/my-orders-screen';
  static const String clinicsScreen = '/clinics-screen';
  static const String clinicDetailsScreen = '/clinic-details-screen';
  static const String myAppointmentsScreen = '/my-appointments-screen';
  static const String gymSportsScreen = '/gym-sports-screen';
  static const String gymSportsDetailsScreen = '/gym-sports-details-screen';
  static const String bookGymScreen = '/book-gym-screen';
  static const String aiAssistantScreen = '/ai-assistant-screen';
  static const String salonsScreen = '/salons-screen';
  static const String salonDetailsScreen = '/salon-details-screen';
  static const String bookSalonScreen = '/book-salon-screen';
  static const String reviewsScreen = '/reviews-screen';
  static const String paymentMethodsScreen = '/payment-methods-screen';
  static const String walletScreen = '/wallet-screen';
  static const String loyaltyScreen = '/loyalty-screen';
  static const String publicProviderProfileScreen =
      '/public-provider-profile-screen';
  static const String allProvidersScreen = '/all-providers-screen';
  static const String paymentResultScreen = '/payment-result';
  static const String mapViewScreen = '/map-view-screen';
  static const String trainingScreen = '/training-screen';
}

// ─── Shared category page builder ─────────────────────────────────────────────
//
// All six category routes (Fashion, Real Estate, Clinics, Jobs, Gym & Sports,
// Salons & Beauty) render the single API-driven [CategoryScreen], differing
// only by their [CategoryConfig]. Route paths stay stable so existing deep
// links and call-sites keep working.

Page<dynamic> _categoryPage(CategoryConfig config, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: CategoryScreen(config: config),
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

// ─── Global route protection ─────────────────────────────────────────────────
//
// Every route is evaluated through [authRedirect] before it is shown. The
// router listens to [AuthSession] so the guard also runs the moment a session
// is cleared (token expiry / revocation / logout) — no protected page can
// remain on screen.

final Set<String> _sharedProtectedRoutes = {AppRoutes.notificationsScreen};

final Set<String> _buyerProtectedRoutes = {
  AppRoutes.cartAndCheckoutScreen,
  AppRoutes.bookingScreen,
  AppRoutes.wishlistScreen,
  AppRoutes.myBookingsScreen,
  AppRoutes.settingsScreen,
  AppRoutes.uploadCvScreen,
  AppRoutes.applyJobScreen,
  AppRoutes.myApplicationsScreen,
  AppRoutes.favoritesScreen,
  AppRoutes.bookPropertyScreen,
  AppRoutes.myOrdersScreen,
  AppRoutes.myAppointmentsScreen,
  AppRoutes.bookGymScreen,
  AppRoutes.bookSalonScreen,
  AppRoutes.paymentMethodsScreen,
  AppRoutes.walletScreen,
  AppRoutes.loyaltyScreen,
  AppRoutes.profileScreen,
};

final Set<String> _providerProtectedRoutes = {
  AppRoutes.providerDashboardScreen,
  AppRoutes.providerAddNewScreen,
  AppRoutes.providerProductWizardScreen,
  AppRoutes.providerServiceWizardScreen,
  AppRoutes.providerImportScreen,
  AppRoutes.providerCatalogScreen,
  AppRoutes.providerProfileScreen,
  AppRoutes.providerServicesScreen,
  AppRoutes.providerSubscriptionsScreen,
  AppRoutes.providerPlansScreen,
  AppRoutes.providerOrdersScreen,
};

String? authRedirect(BuildContext context, GoRouterState state) {
  final location = state.matchedLocation;
  final session = AuthSession.instance;

  if (_sharedProtectedRoutes.contains(location) && !session.isLoggedIn) {
    return AppRoutes.loginScreen;
  }
  if (_buyerProtectedRoutes.contains(location) && !session.isBuyer) {
    if (session.isProvider) return null;
    return AppRoutes.loginScreen;
  }
  if (_providerProtectedRoutes.contains(location) && !session.isProvider) {
    return AppRoutes.providerLoginScreen;
  }
  return null;
}

final GoRouter _appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  refreshListenable: AuthSession.instance,
  redirect: authRedirect,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.languageCountryScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LanguageCountryScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.cartAndCheckoutScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CartAndCheckoutScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.jobsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const JobsHomeScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.jobsListingScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final initialTopTab = extra['initialTopTab'] as int? ?? -1;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CategoryScreen(
            config: CategoryConfig.jobs,
            initialTopTab: initialTopTab,
          ),
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.trainingScreen,
      pageBuilder: (context, state) {
        final config =
            state.extra as CategoryConfig? ?? CategoryConfig.training;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CategoryScreen(config: config),
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.fashionScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FashionScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BookingScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.notificationsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationsScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.wishlistScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WishlistScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.myBookingsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MyBookingsScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.loginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.registerScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPasswordScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ForgotPasswordScreen(
          role:
              (state.extra as Map<String, dynamic>?)?['role']?.toString() ??
              'buyer',
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.otpScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: OtpScreen(
          args: (state.extra as Map<String, dynamic>?) ?? const {},
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.providerLoginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderLoginScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.providerDashboardScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderDashboardScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.providerProfileScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderProfileScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.providerAddNewScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderAddNewScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: AppRoutes.providerProductWizardScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ProviderProductWizardScreen(
          initialData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: AppRoutes.providerServiceWizardScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ProviderServiceWizardScreen(
          initialData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: AppRoutes.providerImportScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderImportScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: AppRoutes.providerCatalogScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderCatalogScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: AppRoutes.providerServicesScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderServicesScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.providerSubscriptionsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderSubscriptionsScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.providerPlansScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderPlansScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.orderTrackingScreen,
      builder: (context, state) => OrderTrackingScreen(
        orderId: state.uri.queryParameters['orderId'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.providerAccountManagerChatScreen,
      builder: (context, state) => const ProviderAccountManagerChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.providerOrdersScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderOrdersScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.providerRegisterScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderRegisterScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.uploadCvScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const UploadCvScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.jobDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: JobDetailsScreen(jobData: state.extra as Map<String, dynamic>?),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.applyJobScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ApplyJobScreen(jobData: state.extra as Map<String, dynamic>?),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.myApplicationsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MyApplicationsScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.favoritesScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FavoritesScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.realEstateScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RealEstateHomeScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.realEstateListingScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final initialTopTab = extra['initialTopTab'] as int? ?? -1;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CategoryScreen(
            config: CategoryConfig.realEstate,
            initialTopTab: initialTopTab,
          ),
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.realEstateDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: RealEstateDetailsScreen(
          propertyData: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.bookPropertyScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BookPropertyScreen(
          propertyData: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.fashionHubScreen,
      pageBuilder: (context, state) =>
          _categoryPage(CategoryConfig.fashion, state),
    ),
    GoRoute(
      path: AppRoutes.fashionDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: FashionDetailsScreen(
          productData: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.myOrdersScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MyOrdersScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.clinicsScreen,
      pageBuilder: (context, state) =>
          _categoryPage(CategoryConfig.clinics, state),
    ),
    GoRoute(
      path: AppRoutes.clinicDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ClinicDetailsScreen(
          clinicData: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.myAppointmentsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MyAppointmentsScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.gymSportsScreen,
      pageBuilder: (context, state) => _categoryPage(CategoryConfig.gym, state),
    ),
    GoRoute(
      path: AppRoutes.gymSportsDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: GymSportsDetailsScreen(
          gymData: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.bookGymScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BookGymScreen(gymData: state.extra as Map<String, dynamic>?),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.aiAssistantScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiAssistantScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.salonsScreen,
      pageBuilder: (context, state) =>
          _categoryPage(CategoryConfig.salons, state),
    ),
    GoRoute(
      path: AppRoutes.salonDetailsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: SalonDetailsScreen(
          salonData: state.extra as Map<String, dynamic>?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.bookSalonScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: BookSalonScreen(salonData: state.extra as Map<String, dynamic>?),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.reviewsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ReviewsScreen(
          serviceName:
              (state.extra as Map<String, dynamic>?)?['serviceName'] as String?,
          serviceType:
              (state.extra as Map<String, dynamic>?)?['serviceType'] as String?,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.paymentMethodsScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PaymentMethodsScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.walletScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WalletScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.loyaltyScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoyaltyScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.allProvidersScreen,
      builder: (context, state) => const AllProvidersScreen(),
    ),
    GoRoute(
      path: AppRoutes.publicProviderProfileScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PublicProviderProfileScreen(
            providerId: extra?['id'] as String?,
            providerName: extra?['name'] as String?,
            providerCategory: extra?['category'] as String?,
            providerCity: extra?['city'] as String?,
            providerRating: extra?['rating'] as double?,
            providerReviews: extra?['reviews'] as int?,
            providerImageUrl: extra?['imageUrl'] as String?,
            isVerified: extra?['isVerified'] as bool?,
            providerEmail: extra?['email'] as String?,
            providerFollowers: extra?['followers'] as int?,
          ),
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.paymentResultScreen,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return PaymentResultScreen(
          kind: q['kind'] ?? 'order',
          status: q['status'] ?? 'success',
          orderId: q['orderId'],
          planId: q['planId'],
          provider: q['provider'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.mapViewScreen,
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'services';
        return MapViewScreen(mode: mode);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.searchScreen,
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.offersScreen,
              builder: (context, state) => const OffersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppRouter {
  static GoRouter get appRouter => _appRouter;
}
