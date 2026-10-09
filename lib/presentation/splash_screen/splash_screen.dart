import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_session.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    final service = VeraApiService.instance;
    await service.ensureBooted();
    final session = AuthSession.instance;
    if (!mounted) return;

    // Validate persisted tokens against the server before allowing any
    // authenticated navigation. Expired / revoked / invalid sessions are
    // cleared immediately — the app never trusts locally cached tokens.
    final hadProvider = service.isProviderAuthenticated;
    final providerValid = hadProvider
        ? await session.validateProviderOnStartup()
        : false;
    if (hadProvider && !providerValid) {
      await service.clearProviderToken();
    }

    final hadBuyer = service.isAuthenticated;
    final buyerValid = hadBuyer ? await session.validateBuyerOnStartup() : false;
    if (hadBuyer && !buyerValid) {
      await service.clearToken();
    }
    if (!mounted) return;

    if (!service.isOnboardingDone) {
      context.go(AppRoutes.onboardingScreen);
    } else if (hadProvider && providerValid && service.isProviderAuthenticated) {
      context.go(AppRoutes.providerDashboardScreen);
    } else if (hadBuyer && buyerValid && service.isAuthenticated) {
      context.go(AppRoutes.homeScreen);
    } else if (hadBuyer || hadProvider) {
      // A session existed but is no longer valid → force the user to log in.
      context.go(AppRoutes.loginScreen);
    } else {
      context.go(AppRoutes.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/Green_Modern_Food_Delivery_Order_Mobile_Design__1_-1785624074273.png',
          fit: BoxFit.cover,
          semanticLabel:
              AppLocalizations.of(context).t('splashBackgroundLabel'),
        ),
      ),
    );
  }
}
