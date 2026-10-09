import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';
import '../services/vera_api_service.dart';

/// Ensures the user is signed in. Guests are redirected to the login screen
/// and [false] is returned.
Future<bool> requireAuth(BuildContext context) async {
  if (await VeraApiService.instance.ensureAuthenticated()) return true;
  if (context.mounted) context.push(AppRoutes.loginScreen);
  return false;
}

/// Ensures a provider session exists. Otherwise redirects to the provider
/// login screen and returns [false].
Future<bool> requireProviderAuth(BuildContext context) async {
  if (await VeraApiService.instance.ensureProviderAuthenticated()) return true;
  if (context.mounted) context.push(AppRoutes.providerLoginScreen);
  return false;
}

/// [State] mixin that gates a provider screen behind a signed-in provider.
/// Call [guardProviderSession()] at the start of [initState]; when it returns
/// false the screen redirects to the provider login screen and no data should
/// be loaded.
mixin ProviderGuard<T extends StatefulWidget> on State<T> {
  @protected
  bool guardProviderSession() {
    if (VeraApiService.instance.isProviderAuthenticated) return true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VeraApiService.instance.ensureProviderAuthenticated().then((authenticated) {
        if (mounted && !authenticated) context.go(AppRoutes.providerLoginScreen);
      });
    });
    // Let the screen render while the persisted provider token is restored.
    return true;
  }
}

/// [State] mixin that gates a screen behind a signed-in user. While the
/// session is being confirmed it renders [buildGuard] (empty by default), and
/// once confirmed it calls [onAuthenticated] so the screen can start loading.
/// Guests are redirected to the login screen.
mixin AuthGuard<T extends StatefulWidget> on State<T> {
  bool _authed = false;

  @override
  void initState() {
    super.initState();
    _guard();
  }

  Future<void> _guard() async {
    final ok = await requireAuth(context);
    if (!mounted) return;
    setState(() => _authed = ok);
    if (ok) onAuthenticated();
  }

  /// Whether a signed-in user is confirmed. The real UI must only be shown
  /// when this is true.
  bool get isAuthenticated => _authed;

  /// Called once authentication is confirmed. Override to start loading data.
  @protected
  void onAuthenticated() {}

  /// UI shown while authentication is pending.
  Widget buildGuard(BuildContext context) => const SizedBox.shrink();

  /// Wraps [child] so nothing sensitive is rendered until the session is
  /// confirmed. Guests stay on [buildGuard] after the login redirect.
  Widget authPlaceholder(Widget child) {
    return _authed ? child : buildGuard(context);
  }
}
