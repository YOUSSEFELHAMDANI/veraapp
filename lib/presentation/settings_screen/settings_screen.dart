import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../core/auth_session.dart';
import '../../core/locale_provider.dart';
import '../../core/theme_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with AuthGuard {
  // Notification toggles
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _bookingReminders = true;

  // Language
  String _selectedLanguage = 'English';
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'key': 'english'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية', 'key': 'arabic'},
    {'code': 'fr', 'name': 'French', 'native': 'Français', 'key': 'french'},
    {'code': 'ur', 'name': 'Urdu', 'native': 'اردو', 'key': 'urdu'},
  ];

  // Payment methods
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoadingPaymentMethods = true;

  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadPaymentMethods();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('app_locale') ??
        _languages
            .where((language) => language['name'] == prefs.getString('pref_language'))
            .map((language) => language['code'])
            .firstOrNull ??
        'en';
    final selectedLanguage = _languages.firstWhere(
      (language) => language['code'] == savedCode,
      orElse: () => _languages.first,
    )['name']!;
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool('pref_push') ?? true;
      _emailNotifications = prefs.getBool('pref_email') ?? true;
       _smsNotifications = true;
      _orderUpdates = prefs.getBool('pref_orders') ?? true;
       _promotions = true;
      _bookingReminders = prefs.getBool('pref_bookings') ?? true;
      _selectedLanguage = selectedLanguage;
    });
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await VeraApiService.instance.fetchPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = methods.map(_normalizePaymentMethod).toList();
        _isLoadingPaymentMethods = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPaymentMethods = false);
    }
  }

  Map<String, dynamic> _normalizePaymentMethod(Map<String, dynamic> m) {
    final rawType =
        (m['type'] ?? m['brand'] ?? m['card_type'] ?? m['method'] ?? '')
            .toString()
            .toLowerCase();
    final type = rawType.contains('visa')
        ? 'visa'
        : rawType.contains('master')
            ? 'mastercard'
            : rawType.contains('amex')
                ? 'amex'
                : rawType.isEmpty
                    ? 'card'
                    : rawType;
    return {
      'id': (m['id'] ?? m['payment_method_id'] ?? '').toString(),
      'type': type,
      'last4': _last4Of(m),
      'expiry': m['expiry']?.toString() ?? m['expiration']?.toString() ?? '',
      'isDefault': _asBool(m['is_default'] ?? m['default'] ?? m['isDefault']),
    };
  }

  String _last4Of(Map<String, dynamic> m) {
    final l4 = m['last4'] ?? m['last_four'] ?? m['last_four_digits'];
    if (l4 != null) return '$l4';
    final number =
        (m['number'] ?? m['card_number'] ?? m['pan'] ?? '').toString();
    final digits = number.replaceAll(' ', '');
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return '';
  }

  bool _asBool(Object? v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v != 0;
    return false;
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _selectLanguage(Map<String, String> language) async {
    final code = language['code']!;
    final name = language['name']!;
    setState(() => _selectedLanguage = name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_language', name);
    if (!mounted) return;
    await ref.read(localeProvider.notifier).setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(l10n.settingsLanguageRegion),
                    _buildLanguageSection(),
                    _buildSectionHeader(l10n.appearance),
                    _buildAppearanceSection(),
                    _buildSectionHeader(l10n.notifications),
                    _buildNotificationsSection(),
                    _buildSectionHeader(l10n.paymentMethods),
                    _buildPaymentMethodsSection(),
                    _buildSectionHeader(l10n.settingsPrivacyLegal),
                    _buildPrivacySection(),
                    _buildSectionHeader(l10n.settingsDangerZone),
                    _buildDangerSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            l10n.settings,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.grayText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildLanguageSection() {
    final l10n = AppLocalizations.of(context);
    return _buildCard(
      children: List.generate(_languages.length, (i) {
        final lang = _languages[i];
        final isSelected = _selectedLanguage == lang['name'];
        final isLast = i == _languages.length - 1;
        return Column(
          children: [
            InkWell(
              onTap: () => _selectLanguage(lang),
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              splashColor: AppTheme.primaryPinkLight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryPinkLight
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primaryPinkDark
                            : AppTheme.grayText,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t(lang['key']!),
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          Text(
                            lang['native']!,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppTheme.grayText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    else
                      const SizedBox(width: 22),
                  ],
                ),
              ),
            ),
            if (!isLast)
              Divider(height: 1, color: AppTheme.borderLight, indent: 70),
          ],
        );
      }),
    );
  }

  Widget _buildAppearanceSection() {
    final l10n = AppLocalizations.of(context);
    final autoByCountry = ThemeController.instance.isAutoByCountry;
    final options = [
      {
        'type': 'auto_country',
        'icon': Icons.language_rounded,
        'label': 'Auto (Day/Night by Country)',
        'labelAr': 'تلقائي (ليل/نهار حسب البلد)',
      },
      {
        'type': 'mode',
        'mode': ThemeMode.system,
        'icon': Icons.brightness_auto_rounded,
        'label': l10n.themeSystem,
      },
      {
        'type': 'mode',
        'mode': ThemeMode.light,
        'icon': Icons.light_mode_rounded,
        'label': l10n.themeLight,
      },
      {
        'type': 'mode',
        'mode': ThemeMode.dark,
        'icon': Icons.dark_mode_rounded,
        'label': l10n.themeDark,
      },
    ];

    return _buildCard(
      children: List.generate(options.length, (i) {
        final opt = options[i];
        final isAutoOption = opt['type'] == 'auto_country';
        final isSelected = isAutoOption
            ? autoByCountry
            : (!autoByCountry && ThemeController.instance.mode == opt['mode']);
        final isLast = i == options.length - 1;
        return Column(
          children: [
            InkWell(
              onTap: () async {
                if (isAutoOption) {
                  final prefs = await SharedPreferences.getInstance();
                  final country = prefs.getString('vera_country') ?? 'AE';
                  ThemeController.instance.setAutoByCountry(true, country: country);
                } else {
                  ThemeController.instance.setMode(opt['mode'] as ThemeMode);
                }
                setState(() {});
              },
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              splashColor: AppTheme.primaryPinkLight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryPinkLight
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        opt['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primaryPinkDark
                            : AppTheme.grayText,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.isArabic
                            ? (opt['labelAr'] as String? ?? opt['label'] as String)
                            : opt['label'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    else
                      const SizedBox(width: 22),
                  ],
                ),
              ),
            ),
            if (!isLast)
              Divider(height: 1, color: AppTheme.borderLight, indent: 70),
          ],
        );
      }),
    );
  }

  Widget _buildNotificationsSection() {
    final l10n = AppLocalizations.of(context);
    final toggles = [
      {
        'key': 'pref_push',
        'icon': Icons.notifications_outlined,
        'label': l10n.pushNotifications,
        'subtitle': l10n.pushNotificationsSubtitle,
        'value': _pushNotifications,
        'setter': (v) => setState(() {
          _pushNotifications = v;
          _saveToggle('pref_push', v);
        }),
      },
      {
        'key': 'pref_email',
        'icon': Icons.email_outlined,
        'label': l10n.emailNotifications,
        'subtitle': l10n.emailNotificationsSubtitle,
        'value': _emailNotifications,
        'setter': (v) => setState(() {
          _emailNotifications = v;
          _saveToggle('pref_email', v);
        }),
      },
      {
        'key': 'pref_sms',
        'icon': Icons.sms_outlined,
        'label': l10n.smsNotifications,
        'subtitle': l10n.smsNotificationsSubtitle,
        'value': _smsNotifications,
        'locked': true,
        'setter': (v) => setState(() {
          _smsNotifications = v;
          _saveToggle('pref_sms', v);
        }),
      },
      {
        'key': 'pref_orders',
        'icon': Icons.shopping_bag_outlined,
        'label': l10n.orderUpdates,
        'subtitle': l10n.orderUpdatesSubtitle,
        'value': _orderUpdates,
        'setter': (v) => setState(() {
          _orderUpdates = v;
          _saveToggle('pref_orders', v);
        }),
      },
      {
        'key': 'pref_promos',
        'icon': Icons.local_offer_outlined,
        'label': l10n.promotionsOffers,
        'subtitle': l10n.promotionsOffersSubtitle,
        'value': _promotions,
        'locked': true,
        'setter': (v) => setState(() {
          _promotions = v;
          _saveToggle('pref_promos', v);
        }),
      },
      {
        'key': 'pref_bookings',
        'icon': Icons.calendar_today_outlined,
        'label': l10n.bookingReminders,
        'subtitle': l10n.bookingRemindersSubtitle,
        'value': _bookingReminders,
        'setter': (v) => setState(() {
          _bookingReminders = v;
          _saveToggle('pref_bookings', v);
        }),
      },
    ];

    return _buildCard(
      children: List.generate(toggles.length, (i) {
        final t = toggles[i];
        final isLast = i == toggles.length - 1;
        final value = t['value'] as bool;
        final setter = t['setter'] as Function(bool);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                      decoration: BoxDecoration(
                      color: value
                          ? AppTheme.primaryPinkLight
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      t['icon'] as IconData,
                      size: 20,
                      color: value
                          ? AppTheme.primaryPinkDark
                          : AppTheme.grayText,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['label'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        Text(
                          t['subtitle'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: value,
                    onChanged: t['locked'] == true ? null : setter,
                    activeColor: AppTheme.primaryPinkDark,
                    activeTrackColor: AppTheme.primaryPinkLight,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(height: 1, color: AppTheme.borderLight, indent: 70),
          ],
        );
      }),
    );
  }

  Widget _buildPaymentMethodsSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_isLoadingPaymentMethods)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_paymentMethods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.noPaymentMethods,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ),
                  )
                else
                  ..._paymentMethods.asMap().entries.map((entry) {
                    final i = entry.key;
                    final method = entry.value;
                    final isLast = i == _paymentMethods.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                child: Icon(
                                  method['type'] == 'visa'
                                      ? Icons.credit_card_rounded
                                      : Icons.credit_card_outlined,
                                  size: 20,
                                  color: method['type'] == 'visa'
                                      ? const Color(0xFF1A1F71)
                                      : const Color(0xFFEB001B),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${method['type'].toString().toUpperCase()} •••• ${method['last4']}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.charcoal,
                                          ),
                                        ),
                                        if (method['isDefault'] == true) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.primaryPinkLight,
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: Text(
                                              l10n.defaultLabel,
                                              style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryPinkDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      l10n.expiresLabel(
                                          method['expiry'].toString()),
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppTheme.grayText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _showRemoveCardDialog(method['id']),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: AppTheme.borderLight,
                            indent: 70,
                          ),
                      ],
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showAddCardSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryPinkLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryPink.withAlpha(100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_card_rounded,
                    size: 20,
                    color: AppTheme.primaryPinkDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.addPaymentMethod,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPinkDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    final l10n = AppLocalizations.of(context);
    final items = [
      {
        'icon': Icons.privacy_tip_outlined,
        'label': l10n.privacyPolicy,
        'onTap': () => _openUrl('https://veraapp.app/public/privacy'),
      },
      {
        'icon': Icons.gavel_rounded,
        'label': l10n.termsConditions,
        'onTap': () => _openUrl('https://veraapp.app/public/terms'),
      },
      {
        'icon': Icons.cookie_outlined,
        'label': l10n.cookiePolicy,
        'onTap': () => _openUrl('https://veraapp.app/public/cookies'),
      },
      {
        'icon': Icons.info_outline_rounded,
        'label': l10n.aboutUs,
        'trailing': 'v2.4.1',
        'onTap': () => _openUrl('https://veraapp.app/public/about'),
      },
    ];

    return _buildCard(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isLast = i == items.length - 1;
        return Column(
          children: [
            InkWell(
              onTap: item['onTap'] as VoidCallback,
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              splashColor: AppTheme.primaryPinkLight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPinkLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: AppTheme.primaryPinkDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ),
                    if (item.containsKey('trailing'))
                      Text(
                        item['trailing'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppTheme.grayText,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.grayLight,
                    ),
                  ],
                ),
              ),
            ),
            if (!isLast)
              Divider(height: 1, color: AppTheme.borderLight, indent: 70),
          ],
        );
      }),
    );
  }

  Widget _buildDangerSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _showDeleteAccountDialog,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.error.withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.error.withAlpha(51)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isDeletingAccount
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.error,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.delete_forever_rounded,
                        size: 20,
                        color: AppTheme.error,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deleteAccount,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.error,
                      ),
                    ),
                    Text(
                      l10n.deleteAccountSubtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.error.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error)),
      );
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'VÉRA',
      applicationVersion: 'v2.4.1',
      applicationLegalese: '© VÉRA',
    );
  }

  void _showRemoveCardDialog(String cardId) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card_off_rounded,
                  size: 28,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.removeCard,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.removeCardConfirm,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppTheme.grayText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.charcoal,
                        side: BorderSide(color: AppTheme.borderMedium),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _paymentMethods.removeWhere((m) => m['id'] == cardId);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.cardRemoved,
                              style: GoogleFonts.cairo(fontSize: 13),
                            ),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.remove,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCardSheet() {
    final l10n = AppLocalizations.of(context);
    final cardNumberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.addPaymentMethod,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.cardHolder,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardNumberCtrl,
                keyboardType: TextInputType.number,
                maxLength: 19,
                decoration: InputDecoration(
                  labelText: l10n.cardNumber,
                  counterText: '',
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        counterText: '',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.borderLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.cvv,
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.borderLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (cardNumberCtrl.text.length >= 4) {
                    setState(() {
                      _paymentMethods.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'type': 'visa',
                        'last4': cardNumberCtrl.text
                            .replaceAll(' ', '')
                            .substring(
                              (cardNumberCtrl.text.replaceAll(' ', '').length -
                                      4)
                                  .clamp(0, 9999),
                            ),
                        'expiry': expiryCtrl.text,
                        'isDefault': false,
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.cardAdded,
                          style: GoogleFonts.cairo(fontSize: 13),
                        ),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.addCard,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context);
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 32,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.deleteAccount,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deleteAccountWarning,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.grayText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmCtrl,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.typeDeleteConfirm,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.error,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.charcoal,
                          side: BorderSide(color: AppTheme.borderMedium),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: confirmCtrl.text == 'DELETE'
                            ? () async {
                                Navigator.pop(ctx);
                                setState(() => _isDeletingAccount = true);
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                await AuthSession.instance.clearSession(
                                  clearBuyer: true,
                                  clearProvider: true,
                                );
                                if (mounted) {
                                  context.go(AppRoutes.loginScreen);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.error.withAlpha(80),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.delete,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
