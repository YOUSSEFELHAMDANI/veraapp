import 'package:shared_preferences/shared_preferences.dart';

class ProviderDashboardTourState {
  static const replayRouteExtra = 'replay_provider_dashboard_tour';

  static String pendingKey(String email) =>
      'provider_dashboard_tour_pending_${email.trim().toLowerCase()}';

  static Future<void> markPendingForEmail(String email) async {
    if (email.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pendingKey(email), true);
  }

  static Future<bool> isPendingForEmail(String email) async {
    if (email.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(pendingKey(email)) ?? false;
  }

  static Future<bool> consumePendingForEmail(String email) async {
    if (email.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = pendingKey(email);
    final pending = prefs.getBool(key) ?? false;
    if (pending) await prefs.remove(key);
    return pending;
  }
}
