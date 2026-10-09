import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../routes/app_routes.dart';
import '../services/vera_api_service.dart';

/// Central reactive authentication state.
///
/// This is the single source of truth that the router listens to
/// (`refreshListenable`) so that every navigation is guarded globally, and it
/// is the only place allowed to wipe the session when the server rejects a
/// token (401/403 / expired / revoked). Screens must never decide "logged in"
/// on their own; they rely on this state.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  /// Bound to the global [ProviderContainer] in [main] so that logout can
  /// purge every cached user/order/cart object held in memory.
  ProviderContainer? _container;

  bool _handlingExpiry = false;

  void bind(ProviderContainer container) => _container = container;

  VeraApiService get _api => VeraApiService.instance;

  // ─── Current auth state (always derived from the service tokens) ──────────

  bool get isBuyer => _api.isAuthenticated;

  bool get isProvider => _api.isProviderAuthenticated;

  bool get isLoggedIn => isBuyer || isProvider;

  /// Called by the API service whenever a token slot changes so the router
  /// re-evaluates redirects immediately.
  void refresh() => notifyListeners();

  // ─── Cached state cleanup ─────────────────────────────────────────────────

  /// Purges every piece of in-memory authenticated state (user object, cart,
  /// ...). Providers are re-created empty on their next read.
  Future<void> clearCachedState() async {
    final container = _container;
    if (container == null) return;
    try {
      container.read(currentUserProvider.notifier).setUser(null);
    } catch (_) {}
    try {
      container.read(cartProvider.notifier).clearCart();
    } catch (_) {}
  }

  /// Wipes tokens + cached state without any network call.
  Future<void> clearSession({
    bool clearBuyer = true,
    bool clearProvider = false,
  }) async {
    await clearCachedState();
    if (clearBuyer) await _api.clearToken();
    if (clearProvider) await _api.clearProviderToken();
    refresh();
  }

  /// Force logout: cancel in-flight requests, purge everything and send the
  /// user to the login screen with a cleared navigation stack (Back button
  /// cannot return to protected pages).
  Future<void> forceLogout({required bool isProvider}) async {
    if (_handlingExpiry) return;
    _handlingExpiry = true;
    try {
      _api.cancelActiveRequests();
      await clearSession(
        clearBuyer: true,
        clearProvider: isProvider || _api.isProviderAuthenticated,
      );
      final route = isProvider
          ? AppRoutes.providerLoginScreen
          : AppRoutes.loginScreen;
      try {
        AppRouter.appRouter.go(route);
      } catch (_) {}
    } finally {
      _handlingExpiry = false;
    }
  }

  /// Re-validates every existing session against the server. Called on app
  /// resume and inactivity. A 401/403 bubbles through the Dio interceptor
  /// which triggers [forceLogout] automatically.
  Future<void> validateNow() async {
    if (!isLoggedIn) return;
    if (isBuyer) {
      await _api.validateBuyerSession();
    }
    if (isProvider) {
      await _api.validateProviderSession();
    }
  }

  /// Server-side validation used during startup. Returns whether the buyer
  /// session is still accepted by the server without triggering the automatic
  /// logout flow (the caller decides what to do).
  Future<bool> validateBuyerOnStartup() async {
    return _api.validateBuyerSession(suppressAutoLogout: true);
  }

  Future<bool> validateProviderOnStartup() async {
    return _api.validateProviderSession(suppressAutoLogout: true);
  }
}
