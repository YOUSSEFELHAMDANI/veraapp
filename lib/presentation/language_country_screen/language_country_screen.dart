import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../core/locale_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class LanguageCountryScreen extends ConsumerStatefulWidget {
  const LanguageCountryScreen({super.key});

  @override
  ConsumerState<LanguageCountryScreen> createState() =>
      _LanguageCountryScreenState();
}

class _LanguageCountryScreenState extends ConsumerState<LanguageCountryScreen>
    with SingleTickerProviderStateMixin {
  String _selectedLanguage = 'en';
  String? _selectedCountry;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _countries = [
    {
      'code': 'AE',
      'nameEn': 'United Arab Emirates',
      'nameAr': 'الإمارات العربية المتحدة',
      'flag': '🇦🇪',
      'active': true,
    },
    {
      'code': 'SA',
      'nameEn': 'Saudi Arabia',
      'nameAr': 'المملكة العربية السعودية',
      'flag': '🇸🇦',
      'active': false,
    },
    {
      'code': 'KW',
      'nameEn': 'Kuwait',
      'nameAr': 'الكويت',
      'flag': '🇰🇼',
      'active': false,
    },
    {
      'code': 'QA',
      'nameEn': 'Qatar',
      'nameAr': 'قطر',
      'flag': '🇶🇦',
      'active': false,
    },
    {
      'code': 'BH',
      'nameEn': 'Bahrain',
      'nameAr': 'البحرين',
      'flag': '🇧🇭',
      'active': false,
    },
    {
      'code': 'OM',
      'nameEn': 'Oman',
      'nameAr': 'عُمان',
      'flag': '🇴🇲',
      'active': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();

    // Sync with current locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = ref.read(localeProvider);
      setState(() {
        _selectedLanguage = currentLocale.languageCode;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isRtl => const {'ar', 'ur'}.contains(_selectedLanguage);

  AppLocalizations get l10n => AppLocalizations.of(context);

  String _nativeLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }

  Future<void> _onContinue() async {
    if (_selectedCountry == null) return;
    ref.read(localeProvider.notifier).setLocale(Locale(_selectedLanguage));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vera_country', _selectedCountry!);
    await VeraApiService.instance.setOnboardingDone();
    if (mounted) context.go(AppRoutes.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),
                    _buildHeader(),
                    SizedBox(height: 3.h),
                    _buildLanguageSection(),
                    SizedBox(height: 3.h),
                    _buildCountrySection(),
                    SizedBox(height: 4.h),
                    _buildContinueButton(),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14.w,
          height: 14.w,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withAlpha(77),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image.asset(
              'assets/images/icon-1785658212252.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          l10n.welcomeToVera,
          style: _isRtl
              ? GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalDark,
                )
              : GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalDark,
                  letterSpacing: -0.3,
                ),
        ),
        SizedBox(height: 0.6.h),
        Text(
          l10n.selectLanguageCountry,
          style: _isRtl
              ? GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                  height: 1.5,
                )
              : GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                  height: 1.5,
                ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n.language, Icons.language_rounded),
        SizedBox(height: 1.2.h),
        Row(
          children: [
            Expanded(
              child: _buildLanguageCard(
                code: 'en',
                emoji: '🇬🇧',
                selected: _selectedLanguage == 'en',
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildLanguageCard(
                code: 'ar',
                emoji: '🇦🇪',
                selected: _selectedLanguage == 'ar',
              ),
            ),
          ],
        ),
        SizedBox(height: 1.2.h),
        Row(
          children: [
            Expanded(
              child: _buildLanguageCard(
                code: 'fr',
                emoji: '🇫🇷',
                selected: _selectedLanguage == 'fr',
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildLanguageCard(
                code: 'ur',
                emoji: '🇵🇰',
                selected: _selectedLanguage == 'ur',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageCard({
    required String code,
    required String emoji,
    required bool selected,
  }) {
    final String label = _nativeLanguageName(code);
    final String subLabel = l10n.t(code == 'en'
        ? 'english'
        : code == 'ar'
            ? 'arabic'
            : code == 'fr'
                ? 'french'
                : 'urdu');
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryPink.withAlpha(20)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: selected ? AppTheme.primaryPink : AppTheme.borderLight,
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPink.withAlpha(38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 14.sp)),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryPinkDark
                          : AppTheme.charcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 9.sp,
                      color: AppTheme.grayText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 5.w,
                height: 5.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 10.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n.country, Icons.location_on_rounded),
        SizedBox(height: 1.2.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _countries.length,
          separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
          itemBuilder: (context, index) {
            final country = _countries[index];
            return _buildCountryCard(country);
          },
        ),
      ],
    );
  }

  Widget _buildCountryCard(Map<String, dynamic> country) {
    final bool active = country['active'] as bool;
    final bool selected = _selectedCountry == country['code'];
    final String name = _selectedLanguage == 'ar'
        ? country['nameAr'] as String
        : country['nameEn'] as String;

    return GestureDetector(
      onTap: active
          ? () => setState(() => _selectedCountry = country['code'])
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryPink.withAlpha(20)
              : active
              ? AppTheme.surfaceLight
              : AppTheme.ivoryLight,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: selected
                ? AppTheme.primaryPink
                : active
                ? AppTheme.borderLight
                : AppTheme.borderLight.withAlpha(128),
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPink.withAlpha(38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : active
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 11.w,
              height: 11.w,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primaryPinkLight.withAlpha(128)
                    : AppTheme.borderLight.withAlpha(102),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: Text(
                  country['flag'],
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: active ? null : null,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            // Name
            Expanded(
              child: Text(
                name,
                style: _isRtl
                    ? GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: active ? AppTheme.charcoal : AppTheme.grayLight,
                      )
                    : GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: active ? AppTheme.charcoal : AppTheme.grayLight,
                      ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Coming soon badge or check
            if (!active)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.5.w,
                  vertical: 0.5.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.goldLight.withAlpha(153),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: AppTheme.goldAccent.withAlpha(102),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  l10n.comingSoon,
                  style: GoogleFonts.cairo(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.goldAccent,
                  ),
                ),
              )
            else if (selected)
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 10.sp),
              )
            else
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderMedium, width: 1.5),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12.sp, color: AppTheme.primaryPinkDark),
        SizedBox(width: 1.5.w),
        Text(
          label,
          style: _isRtl
              ? GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalDark,
                )
              : GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalDark,
                ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final bool canContinue = _selectedCountry != null;
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: canContinue ? AppTheme.primaryGradient : null,
          color: canContinue ? null : AppTheme.borderLight,
          borderRadius: BorderRadius.circular(14.0),
          boxShadow: canContinue
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPink.withAlpha(89),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canContinue ? _onContinue : null,
            borderRadius: BorderRadius.circular(14.0),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              child: Center(
                child: Text(
                  l10n.continueText,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: canContinue ? Colors.white : AppTheme.grayText,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
