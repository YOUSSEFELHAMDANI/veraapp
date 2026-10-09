import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static String _sanitize(String? code) {
    if (code != null &&
        AppLocalizations.supportedLanguageCodes.contains(code)) {
      return code;
    }
    return 'en';
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    state = Locale(_sanitize(prefs.getString('app_locale')));
  }

  Future<void> setLocale(Locale locale) async {
    final code = _sanitize(locale.languageCode);
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', code);
  }
}
