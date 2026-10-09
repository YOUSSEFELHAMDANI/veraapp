import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app theme mode controller (light / dark / system / auto).
///
/// The "auto" mode uses the user's selected country to determine local time
/// and switches between light (6 AM – 6 PM) and dark (6 PM – 6 AM) based on
/// that timezone. A periodic timer re-checks every 30 minutes.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'vera_theme_mode';
  static const String _autoKey = 'vera_auto_theme';
  static const String _countryKey = 'vera_country';

  ThemeMode _mode = ThemeMode.system;
  bool _systemDark = false;
  bool _autoByCountry = true;
  Timer? _autoTimer;

  ThemeMode get mode => _autoByCountry
      ? (_isAutoDark ? ThemeMode.dark : ThemeMode.light)
      : _mode;
  bool get isAutoByCountry => _autoByCountry;

  bool get isDark {
    if (_autoByCountry) return _isAutoDark;
    switch (_mode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return _systemDark;
    }
  }

  static const Map<String, int> _countryUtcOffset = {
    'AE': 4, 'SA': 3, 'KW': 3, 'QA': 3, 'BH': 3, 'OM': 4,
    'EG': 2, 'JO': 2, 'IQ': 3, 'LB': 2, 'PS': 2,
    'MA': 1, 'TN': 1, 'DZ': 1, 'LY': 2, 'SD': 2,
    'TR': 3, 'SY': 2, 'YE': 3,
    'IN': 5, 'PK': 5, 'BD': 6, 'LK': 5, 'NP': 5, 'AF': 4, 'IR': 3,
    'US': -5, 'CA': -5, 'GB': 0, 'FR': 1, 'DE': 1, 'IT': 1, 'ES': 1,
    'RU': 3, 'CN': 8, 'JP': 9, 'KR': 9, 'TH': 7, 'VN': 7,
    'ID': 7, 'MY': 8, 'PH': 8, 'SG': 8, 'AU': 10, 'NZ': 12,
    'BR': -3, 'MX': -6, 'AR': -3, 'CL': -4,
  };

  bool _isAutoDark = false;

  int _getUtcOffset(String countryCode) {
    return _countryUtcOffset[countryCode.toUpperCase()] ?? 4;
  }

  void _updateAutoTheme() {
    if (!_autoByCountry) return;
    final country = _currentCountry;
    if (country == null || country.isEmpty) return;
    final offset = _getUtcOffset(country);
    final utcNow = DateTime.now().toUtc();
    final localHour = (utcNow.hour + offset) % 24;
    _isAutoDark = localHour < 6 || localHour >= 18;
    notifyListeners();
  }

  String? _currentCountry;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _systemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _autoByCountry = prefs.getBool(_autoKey) ?? true;
    _currentCountry = prefs.getString(_countryKey) ?? 'AE';
    switch (saved) {
      case 'dark':
        _mode = ThemeMode.dark;
      case 'light':
        _mode = ThemeMode.light;
      default:
        _mode = ThemeMode.system;
    }
    if (_autoByCountry) {
      _updateAutoTheme();
      _startAutoTimer();
    }
    notifyListeners();
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _updateAutoTheme();
    });
  }

  void setAutoByCountry(bool enabled, {String? country}) {
    _autoByCountry = enabled;
    if (country != null) _currentCountry = country;
    if (enabled) {
      _updateAutoTheme();
      _startAutoTimer();
    } else {
      _autoTimer?.cancel();
    }
    _savePrefs();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_autoByCountry) {
      _autoByCountry = false;
      _autoTimer?.cancel();
    }
    if (_mode == mode) return;
    _mode = mode;
    _savePrefs();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _mode.name);
    await prefs.setBool(_autoKey, _autoByCountry);
  }

  @override
  void didChangePlatformBrightness() {
    _systemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    if (_mode == ThemeMode.system && !_autoByCountry) notifyListeners();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
