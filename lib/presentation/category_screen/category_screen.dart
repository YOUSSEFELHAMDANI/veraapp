import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/user_interest_tracker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/custom_image_widget.dart';
import '../../routes/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../services/vera_api_service.dart';

enum CategoryLayout { row, grid, stack, salon, job }

enum SubSectionStyle { grid, chips }

class TopTab {
  final String labelKey;
  final String filterField;
  final String filterValue;
  const TopTab({required this.labelKey, required this.filterField, required this.filterValue});
}

enum HeroMode { dark, gradient }

/// Single shared category page. Every category tile in the app routes here
/// with its own [CategoryConfig], so all categories follow the same
/// navigation, API, UI and data structure. Sub-categories are always loaded
/// from the backend API (never hardcoded or derived client-side).
class CategoryConfig {
  final String slug;
  final String title;
  final CategoryLayout layout;
  final SubSectionStyle subStyle;
  final HeroMode heroMode;
  final String heroImageKey;
  final String heroTitle;
  final String Function(int count, AppLocalizations l10n) heroSubtitle;
  final String? heroCta;
  final String heroCtaRoute;
  final String seeAllRoute;
  final Gradient heroGradient;
  final bool showTopRatedFilter;
  final List<String> searchKeys;
  final String searchHint;
  final String sectionTitle;
  final String? resultsCount;
  final String? resultsTitle;
  final bool resultsSeeAll;
  final String? emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final String errorText;
  final Color accentColor;
  final Color accentBg;
  final String allLabel;
  final IconData allIcon;
  final Color allColor;
  final Color allBg;
  final List<Color> subColors;
  final List<Color> subBgs;
  final IconData secondaryIcon;
  final String secondaryRoute;
  final String detailRoute;
  final IconData Function(String label) iconFor;
  final List<TopTab>? topTabs;

  const CategoryConfig({
    required this.slug,
    required this.title,
    required this.layout,
    required this.subStyle,
    required this.heroMode,
    required this.heroImageKey,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroGradient,
    required this.searchKeys,
    required this.searchHint,
    required this.sectionTitle,
    required this.emptyTitle,
    required this.errorText,
    required this.accentColor,
    required this.accentBg,
    required this.allLabel,
    required this.allIcon,
    required this.allColor,
    required this.allBg,
    required this.subColors,
    required this.subBgs,
    required this.secondaryIcon,
    required this.secondaryRoute,
    required this.detailRoute,
    required this.iconFor,
    this.heroCta,
    this.heroCtaRoute = '',
    this.seeAllRoute = '',
    this.showTopRatedFilter = true,
    this.resultsCount,
    this.resultsTitle,
    this.resultsSeeAll = false,
    this.emptyIcon,
        this.emptySubtitle,
        this.topTabs,
  });

  static final CategoryConfig fashion = CategoryConfig(
    slug: 'fashion',
    title: 'fashion',
    layout: CategoryLayout.grid,
    subStyle: SubSectionStyle.grid,
    heroMode: HeroMode.gradient,
    showTopRatedFilter: false,
    heroImageKey: 'image',
    heroTitle: 'catDiscoverYourStyle',
    heroSubtitle: _countSubtitle('productsAvailable'),
    heroCta: 'shopNow',
    heroCtaRoute: AppRoutes.fashionHubScreen,
    seeAllRoute: AppRoutes.fashionHubScreen,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEFA9B8), Color(0xFFE787C9)],
    ),
    searchKeys: ['title', 'brand'],
    searchHint: 'searchFashionBrands',
    sectionTitle: 'categories',
    resultsTitle: 'recommendedForYou',
    resultsSeeAll: true,
    emptyTitle: 'noProductsFound',
    errorText: 'errorLoadProducts',
    accentColor: AppTheme.primaryPinkDark,
    accentBg: AppTheme.primaryPinkLight,
    allLabel: 'allLabel',
    allIcon: Icons.diamond_rounded,
    allColor: Color(0xFFEFA9B8),
    allBg: AppTheme.tintPink,
    subColors: [
      Color(0xFFEFA9B8),
      Color(0xFFE787C9),
      Color(0xFFC8A96A),
      Color(0xFF5DADE2),
      Color(0xFF34C759),
      Color(0xFFDCCFE8),
      Color(0xFFD898AA),
    ],
    subBgs: [
      AppTheme.tintPink,
      AppTheme.tintPinkLight,
      AppTheme.tintPeach,
      AppTheme.tintBlue,
      AppTheme.tintGreen,
      AppTheme.tintLavender,
      AppTheme.tintPeach,
    ],
    secondaryIcon: Icons.receipt_long_outlined,
    secondaryRoute: AppRoutes.myOrdersScreen,
    detailRoute: AppRoutes.fashionDetailsScreen,
    iconFor: _fashionIcon,
  );

  static final CategoryConfig realEstate = CategoryConfig(
    slug: 'real-estate',
    title: 'realEstate',
    layout: CategoryLayout.stack,
    subStyle: SubSectionStyle.grid,
    heroMode: HeroMode.gradient,
    showTopRatedFilter: false,
    heroImageKey: 'image',
    heroTitle: 'catFindYourDreamHome',
    heroSubtitle: _countSubtitle('propertiesAvailable'),
    heroCta: 'browseNow',
    heroCtaRoute: AppRoutes.realEstateScreen,
    seeAllRoute: AppRoutes.realEstateScreen,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD898AA), Color(0xFFC8A96A)],
    ),
    searchKeys: ['title', 'location'],
    searchHint: 'searchPropertiesAreas',
    sectionTitle: 'propertyTypes',
    resultsTitle: 'featuredProperties',
    resultsSeeAll: true,
    emptyTitle: 'noPropertiesFound',
    errorText: 'errorLoadProperties',
    accentColor: AppTheme.primaryPinkDark,
    accentBg: AppTheme.primaryPinkLight,
    allLabel: 'allLabel',
    allIcon: Icons.apartment_rounded,
    allColor: Color(0xFFD898AA),
    allBg: AppTheme.tintPeach,
    subColors: [
      Color(0xFF5DADE2),
      Color(0xFF34C759),
      Color(0xFFC8A96A),
      Color(0xFF8FD9F7),
      Color(0xFFDCCFE8),
      Color(0xFFE787C9),
      Color(0xFFD898AA),
    ],
    subBgs: [
      AppTheme.tintBlue,
      AppTheme.tintGreen,
      AppTheme.tintPeach,
      Color(0xFFE0F7FF),
      AppTheme.tintLavender,
      AppTheme.tintPinkLight,
      AppTheme.tintPeach,
    ],
    secondaryIcon: Icons.bookmark_border_rounded,
    secondaryRoute: AppRoutes.myBookingsScreen,
    detailRoute: AppRoutes.realEstateDetailsScreen,
    iconFor: _realEstateIcon,
  );

  static final CategoryConfig clinics = CategoryConfig(
    slug: 'clinics',
    title: 'clinicsAndSalons',
    layout: CategoryLayout.row,
    subStyle: SubSectionStyle.grid,
    heroMode: HeroMode.gradient,
    showTopRatedFilter: false,
    heroImageKey: 'image',
    heroTitle: 'catBookYourWellness',
    heroSubtitle: _countSubtitle('servicesAvailable'),
    heroCta: 'bookNow',
    heroCtaRoute: AppRoutes.clinicsScreen,
    seeAllRoute: AppRoutes.clinicsScreen,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE787C9), Color(0xFFDCCFE8)],
    ),
    searchKeys: ['name', 'category', 'location'],
    searchHint: 'searchClinicsSalonsServices',
    sectionTitle: 'serviceTypes',
    resultsTitle: 'topProvidersNearYou',
    resultsSeeAll: true,
    emptyTitle: 'noServicesFound',
    errorText: 'errorLoadServices',
    accentColor: AppTheme.primaryPinkDark,
    accentBg: AppTheme.primaryPinkLight,
    allLabel: 'allLabel',
    allIcon: Icons.health_and_safety_rounded,
    allColor: Color(0xFF2563EB),
    allBg: Color(0xFFEFF6FF),
    subColors: [
      Color(0xFFE787C9),
      Color(0xFF5DADE2),
      Color(0xFF34C759),
      Color(0xFFEFA9B8),
      Color(0xFFC8A96A),
      Color(0xFF8FD9F7),
      Color(0xFFDCCFE8),
    ],
    subBgs: [
      AppTheme.tintPinkLight,
      AppTheme.tintBlue,
      AppTheme.tintGreen,
      AppTheme.tintPink,
      AppTheme.tintPeach,
      Color(0xFFE0F7FF),
      AppTheme.tintLavender,
    ],
    secondaryIcon: Icons.calendar_month_outlined,
    secondaryRoute: AppRoutes.myAppointmentsScreen,
    detailRoute: AppRoutes.clinicDetailsScreen,
    iconFor: _clinicsIcon,
  );

  static final CategoryConfig jobs = CategoryConfig(
    slug: 'jobs',
    title: 'findJobs',
    layout: CategoryLayout.job,
    subStyle: SubSectionStyle.grid,
    heroMode: HeroMode.gradient,
    showTopRatedFilter: false,
    heroImageKey: 'logo',
    heroTitle: 'catFindTheRightJob',
    heroSubtitle: _countSubtitle('jobsAvailableToday'),
    heroCta: 'exploreJobs',
    heroCtaRoute: AppRoutes.jobsScreen,
    seeAllRoute: AppRoutes.jobsScreen,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEFA9B8), Color(0xFFC8A96A)],
    ),
    searchKeys: ['title', 'company', 'location'],
    searchHint: 'searchJobsCompaniesSkills',
    sectionTitle: 'popularCategories',
    resultsTitle: 'recommendedForYou',
    resultsSeeAll: false,
    emptyTitle: 'noJobsFound',
    errorText: 'errorLoadJobs',
    accentColor: AppTheme.primaryPinkDark,
    accentBg: AppTheme.primaryPinkLight,
    allLabel: 'allJobsLabel',
    allIcon: Icons.work_outline_rounded,
    allColor: Color(0xFFEFA9B8),
    allBg: AppTheme.tintPink,
    subColors: [
      Color(0xFFEFA9B8),
      Color(0xFF5DADE2),
      Color(0xFF34C759),
      Color(0xFFC8A96A),
      Color(0xFF8FD9F7),
      Color(0xFFDCCFE8),
      Color(0xFFE787C9),
    ],
    subBgs: [
      AppTheme.tintPink,
      AppTheme.tintBlue,
      AppTheme.tintGreen,
      AppTheme.tintPeach,
      Color(0xFFE0F7FF),
      AppTheme.tintLavender,
      AppTheme.tintPinkLight,
    ],
    secondaryIcon: Icons.description_outlined,
    secondaryRoute: AppRoutes.myApplicationsScreen,
    detailRoute: AppRoutes.jobDetailsScreen,
    iconFor: _jobsIcon,
  );

  static final CategoryConfig gym = CategoryConfig(
    slug: 'fitness',
    title: 'gym',
    layout: CategoryLayout.row,
    subStyle: SubSectionStyle.grid,
    heroMode: HeroMode.dark,
    showTopRatedFilter: false,
    heroImageKey: 'image',
    heroTitle: 'gymFitness',
    heroSubtitle: _countSubtitle('facilitiesClassesAvailable'),
    seeAllRoute: AppRoutes.gymSportsScreen,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    ),
    searchKeys: ['name', 'category', 'location'],
    searchHint: 'searchGymsSportsTrainers',
    sectionTitle: 'categories',
    resultsCount: 'resultsCountText',
    emptyTitle: 'noFacilitiesFound',
    errorText: 'errorLoadFacilities',
    accentColor: Color(0xFF5DADE2),
    accentBg: AppTheme.gymBg,
    allLabel: 'allLabel',
    allIcon: Icons.fitness_center_rounded,
    allColor: Color(0xFF5DADE2),
    allBg: AppTheme.tintBlue,
    subColors: [
      Color(0xFFFF6B35),
      Color(0xFF5DADE2),
      Color(0xFF9B59B6),
      Color(0xFFE74C3C),
      Color(0xFF2ECC71),
      Color(0xFFC8A96A),
      Color(0xFFDCCFE8),
    ],
    subBgs: [
      AppTheme.tintPeachLight,
      AppTheme.tintBlue,
      AppTheme.tintPurpleLight,
      AppTheme.tintRose,
      AppTheme.tintGreen,
      AppTheme.tintPeach,
      AppTheme.tintSalon,
    ],
    secondaryIcon: Icons.calendar_month_outlined,
    secondaryRoute: AppRoutes.myAppointmentsScreen,
    detailRoute: AppRoutes.gymSportsDetailsScreen,
    iconFor: _gymIcon,
  );

  static final CategoryConfig training = CategoryConfig(
    slug: 'training',
    title: 'Training & Courses',
    layout: CategoryLayout.row,
    subStyle: SubSectionStyle.grid,
    heroMode: HeroMode.gradient,
    showTopRatedFilter: false,
    heroImageKey: 'image',
    heroTitle: 'Expand Your Skills',
    heroSubtitle: _countSubtitle('coursesAvailable'),
    heroCta: 'Browse Courses',
    heroCtaRoute: AppRoutes.trainingScreen,
    seeAllRoute: AppRoutes.trainingScreen,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4A90D9), Color(0xFF5DADE2)],
    ),
    searchKeys: ['title', 'category', 'location'],
    searchHint: 'searchCoursesTraining',
    sectionTitle: 'categories',
    resultsCount: 'resultsCountText',
    emptyTitle: 'noCoursesFound',
    errorText: 'errorLoadCourses',
    accentColor: Color(0xFF5DADE2),
    accentBg: AppTheme.tintBlue,
    allLabel: 'allLabel',
    allIcon: Icons.school_rounded,
    allColor: Color(0xFF5DADE2),
    allBg: AppTheme.tintBlue,
    subColors: [
      Color(0xFF5DADE2),
      Color(0xFF34C759),
      Color(0xFFC8A96A),
      Color(0xFFE787C9),
      Color(0xFFFF6B35),
      Color(0xFF9B59B6),
      Color(0xFFDCCFE8),
    ],
    subBgs: [
      AppTheme.tintBlue,
      AppTheme.tintGreen,
      AppTheme.tintPeach,
      AppTheme.tintPinkLight,
      AppTheme.tintPeachLight,
      AppTheme.tintPurpleLight,
      AppTheme.tintSalon,
    ],
    secondaryIcon: Icons.school_outlined,
    secondaryRoute: AppRoutes.trainingScreen,
    detailRoute: AppRoutes.jobDetailsScreen,
    iconFor: _trainingIcon,
  );

  static final CategoryConfig salons = CategoryConfig(
    slug: 'beauty-salons',
    title: 'salonsAndBeauty',
    layout: CategoryLayout.salon,
    subStyle: SubSectionStyle.grid,
    heroMode: HeroMode.dark,
    showTopRatedFilter: false,
    heroImageKey: 'image',
    heroTitle: 'beautyServices',
    heroSubtitle: _countSubtitle('salonsServicesAvailable'),
    seeAllRoute: AppRoutes.salonsScreen,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2D1B3D), Color(0xFF4A2060)],
    ),
    searchKeys: ['name', 'category', 'location'],
    searchHint: 'searchSalonsServicesStylists',
    sectionTitle: 'categories',
    resultsCount: 'salonsFound',
    emptyIcon: 'search_off',
    emptyTitle: 'noSalonsFound',
    emptySubtitle: 'tryAdjustingFilters',
    errorText: 'errorLoadSalons',
    accentColor: AppTheme.salons,
    accentBg: AppTheme.salonsBg,
    allLabel: 'allLabel',
    allIcon: Icons.auto_awesome_rounded,
    allColor: Color(0xFFDCCFE8),
    allBg: AppTheme.tintSalon,
    subColors: [
      Color(0xFFEFA9B8),
      Color(0xFFE787C9),
      Color(0xFF5DADE2),
      Color(0xFFC8A96A),
      Color(0xFF34C759),
      Color(0xFFFF6B35),
      Color(0xFFDCCFE8),
    ],
    subBgs: [
      AppTheme.tintPink,
      AppTheme.tintPinkLight,
      AppTheme.tintBlue,
      AppTheme.tintPeach,
      AppTheme.tintGreen,
      AppTheme.tintPeachLight,
      AppTheme.tintSalon,
    ],
    secondaryIcon: Icons.calendar_month_outlined,
    secondaryRoute: AppRoutes.myAppointmentsScreen,
    detailRoute: AppRoutes.salonDetailsScreen,
    iconFor: _salonsIcon,
  );
}

String Function(int count, AppLocalizations l10n) _countSubtitle(
    String nounKey) {
  return (count, l10n) => l10n.t(nounKey, args: {'count': '$count'});
}

class CategoryScreen extends ConsumerStatefulWidget {
  final CategoryConfig config;
  final int initialTopTab;

  const CategoryScreen({super.key, required this.config, this.initialTopTab = -1});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _Sub {
  final String slug;
  final String label;
  final String enLabel;
  final IconData icon;
  final Color color;
  final Color bg;

  const _Sub({
    required this.slug,
    required this.label,
    required this.enLabel,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

class _FilterGroup {
  final String id;
  final String titleKey;
  final List<_FilterOption> options;

  const _FilterGroup({
    required this.id,
    required this.titleKey,
    required this.options,
  });
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSlug = '';
  int _selectedTopTab = -1;
  bool _topRated = false;
  final Map<String, String> _groupSelection = {};
  List<_Sub> _subs = const [];
  List<Map<String, dynamic>> _cards = const [];
  bool _loading = true;
  String? _error;

  CategoryConfig get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _selectedTopTab = widget.initialTopTab;
    UserInterestTracker.instance.recordCategoryView(_cfg.slug);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await VeraApiService.instance
          .fetchCategoryWithSubs(_cfg.slug);
      final services = await VeraApiService.instance
          .fetchServices(category: _cfg.slug);
      final subs = <_Sub>[];
      if (result != null && result.subs.isNotEmpty) {
        final apiSubs = result.subs;
        for (var i = 0; i < apiSubs.length; i++) {
          final sub = apiSubs[i];
          subs.add(
            _Sub(
              slug: sub.slug,
              label: sub.name,
              enLabel: sub.enName,
              icon: _cfg.iconFor(sub.name),
              color: _cfg.subColors[i % _cfg.subColors.length],
              bg: _cfg.subBgs[i % _cfg.subBgs.length],
            ),
          );
        }
      } else {
        final seen = <String>{};
        for (final s in services) {
          final sub = s.subcategory.trim();
          if (sub.isNotEmpty && seen.add(sub)) {
            subs.add(
              _Sub(
                slug: sub,
                label: _labelFor(sub),
                enLabel: _labelFor(sub),
                icon: _cfg.iconFor(sub),
                color: _cfg.subColors[subs.length % _cfg.subColors.length],
                bg: _cfg.subBgs[subs.length % _cfg.subBgs.length],
              ),
            );
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _cards = services.map((s) => s.toCardMap()).toList();
        _subs = subs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _cfg.errorText;
      });
    }
  }

  String _labelFor(String slug) {
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  /// Matches a card's raw subcategory value against a subcategory's slug
  /// and English label. Backend data mixes raw slugs (`womens-fashion`) with
  /// human labels (`Women Fashion`) and full phrases (`Residential
  /// Apartments`), so we compare normalized forms in both directions.
  static bool _matchesSub(String cardRaw, String slug, String enLabel) {
    final c = _norm(cardRaw);
    if (c.isEmpty) return false;
    final s = _norm(slug);
    if (s.isNotEmpty && (c == s || c.contains(s) || s.contains(c))) {
      return true;
    }
    final l = _norm(enLabel);
    if (l.isNotEmpty && (c == l || c.contains(l) || l.contains(c))) {
      return true;
    }
    return false;
  }

  static bool _normContains(String a, String b) {
    final na = _norm(a);
    final nb = _norm(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  bool _matchesGroupFilter(
      Map<String, dynamic> card, String groupId, String value) {
    switch (groupId) {
      case 'location':
        return _normContains(card['location'] as String? ?? '', value);
      case 'brand':
        return _normContains(card['brand'] as String? ?? '', value);
      case 'jobType':
        return _normContains(card['jobType'] as String? ?? '', value);
      case 'rating':
        final min = double.tryParse(value) ?? 0;
        return ((card['rating'] as num?)?.toDouble() ?? 0) >= min;
      case 'beds':
        final minBeds = int.tryParse(value) ?? 0;
        return ((card['beds'] as num?)?.toInt() ?? 0) >= minBeds;
    }
    return true;
  }

  List<_FilterGroup> get _sectionGroups {
    final l10n = AppLocalizations.of(context);
    switch (_cfg.slug) {
      case 'real-estate':
        return [
          _group('location', 'location', _locationOptions),
          _group('beds', 'bedrooms', _bedOptions),
          _group('rating', 'rating', _ratingOptions(l10n)),
        ];
      case 'fashion':
        return [
          _group('brand', 'brandLabel', _brandOptions),
          _group('rating', 'rating', _ratingOptions(l10n)),
        ];
      case 'clinics':
        return [
          _group('location', 'location', _locationOptions),
          _group('rating', 'rating', _ratingOptions(l10n)),
        ];
      case 'jobs':
        return [
          _group('location', 'location', _locationOptions),
          _group('jobType', 'jobType', _jobTypeOptions(l10n)),
        ];
      case 'fitness':
        return [
          _group('location', 'location', _locationOptions),
          _group('rating', 'rating', _ratingOptions(l10n)),
        ];
      case 'beauty-salons':
        return [
          _group('location', 'location', _locationOptions),
          _group('rating', 'rating', _ratingOptions(l10n)),
        ];
    }
    return const [];
  }

  _FilterGroup _group(
      String id, String titleKey, List<_FilterOption> options) {
    return _FilterGroup(id: id, titleKey: titleKey, options: options);
  }

  List<_FilterOption> get _locationOptions {
    final seen = <String>{};
    final options = <_FilterOption>[];
    for (final c in _cards) {
      final loc = (c['location'] as String? ?? '').trim();
      if (loc.isEmpty) continue;
      if (seen.add(loc.toLowerCase())) {
        options.add(_FilterOption(value: loc, label: loc));
      }
    }
    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  List<_FilterOption> get _brandOptions {
    final seen = <String>{};
    final options = <_FilterOption>[];
    for (final c in _cards) {
      final brand = (c['brand'] as String? ?? '').trim();
      if (brand.isEmpty) continue;
      if (seen.add(brand.toLowerCase())) {
        options.add(_FilterOption(value: brand, label: brand));
      }
    }
    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  List<_FilterOption> get _bedOptions {
    var maxBeds = 0;
    for (final c in _cards) {
      final b = (c['beds'] as num?)?.toInt() ?? 0;
      if (b > maxBeds) maxBeds = b;
    }
    return [
      for (var n = 1; n <= maxBeds; n++)
        _FilterOption(value: '$n', label: '$n+'),
    ];
  }

  List<_FilterOption> _ratingOptions(AppLocalizations l10n) {
    return [
      for (final v in ['4.0', '4.5', '4.8'])
        _FilterOption(
          value: v,
          label: l10n.t('ratingAtLeast', args: {'value': v}),
        ),
    ];
  }

  List<_FilterOption> _jobTypeOptions(AppLocalizations l10n) {
    final seen = <String>{};
    final options = <_FilterOption>[];
    for (final c in _cards) {
      final jt = (c['jobType'] as String? ?? '').trim();
      if (jt.isEmpty) continue;
      if (seen.add(jt.toLowerCase())) {
        options.add(_FilterOption(value: jt, label: _jobTypeLabel(jt, l10n)));
      }
    }
    return options;
  }

  String _jobTypeLabel(String raw, AppLocalizations l10n) {
    final n = raw.toLowerCase();
    if (n.contains('full')) return l10n.t('fullTime');
    if (n.contains('part')) return l10n.t('partTime');
    if (n.contains('remote')) return l10n.t('remote');
    if (n.contains('contract')) return l10n.t('contract');
    if (n.contains('intern')) return l10n.t('internship');
    if (n.contains('freelanc')) return l10n.t('freelance');
    if (n.contains('on site') || n.contains('onsite')) {
      return l10n.t('onSite');
    }
    return raw;
  }

  List<Map<String, dynamic>> get _filteredCards {
    final query = _searchController.text.toLowerCase();
    return _cards.where((card) {
      // Top tab filter
      if (_selectedTopTab >= 0 && _cfg.topTabs != null) {
        final tab = _cfg.topTabs![_selectedTopTab];
        final cardVal = (card[tab.filterField] ?? '').toString().toLowerCase();
        if (!cardVal.contains(tab.filterValue.toLowerCase())) return false;
      }
      if (_selectedSlug.isNotEmpty) {
        final selected = _subs.where((s) => s.slug == _selectedSlug);
        if (selected.isEmpty) {
          final rawSlug = card['subcategorySlug'] as String? ?? '';
          final displaySub = card['subcategory'] as String? ?? '';
          if (rawSlug != _selectedSlug && displaySub != _selectedSlug) {
            return false;
          }
        } else {
          final sub = selected.first;
          final cardSub = card['subcategorySlug'] as String? ?? '';
          if (!_matchesSub(cardSub, sub.slug, sub.enLabel)) {
            return false;
          }
        }
      }
      if (_topRated && (card['rating'] as num).toDouble() < 4.8) {
        return false;
      }
      for (final entry in _groupSelection.entries) {
        if (!_matchesGroupFilter(card, entry.key, entry.value)) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final found = _cfg.searchKeys.any((key) {
          final value = card[key] as String?;
          return value != null && value.toLowerCase().contains(query);
        });
        if (!found) return false;
      }
      return true;
    }).toList();
  }

  List<String> _filters(AppLocalizations l10n) {
    return <String>{
      l10n.t(_cfg.allLabel),
      if (_cfg.showTopRatedFilter) l10n.topRated,
      for (final s in _subs) s.label,
    }.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverToBoxAdapter(child: _buildHeroBanner()),
                      if (_cfg.topTabs != null)
                        SliverToBoxAdapter(child: _buildTopTabs()),
                      if (_subs.isNotEmpty)
                        SliverToBoxAdapter(child: _buildSubcategories()),
                      if (_cfg.layout != CategoryLayout.job)
                        SliverToBoxAdapter(child: _buildFilterChips()),
                      SliverToBoxAdapter(child: _buildSectionFilters()),
                      SliverToBoxAdapter(child: _buildResults()),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.grayText,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t(_error!),
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                color: AppTheme.grayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _cfg.accentColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  l10n.retry,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(cartCountProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppBackButton(),
          Expanded(
            child: Text(
              l10n.t(_cfg.title),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.cairo(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push(AppRoutes.cartAndCheckoutScreen),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 22,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    if (cartCount > 0)
                      PositionedDirectional(
                        top: 2,
                        end: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPinkDark,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              cartCount > 9 ? '9+' : '$cartCount',
                              style: GoogleFonts.cairo(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(_cfg.secondaryRoute),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Icon(
                    _cfg.secondaryIcon,
                    size: 22,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search_rounded,
              color: AppTheme.grayText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  color: AppTheme.charcoal,
                ),
                decoration: InputDecoration(
                  hintText: l10n.t(_cfg.searchHint),
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppTheme.grayText,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _cfg.accentBg,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: _cfg.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    if (_cfg.heroMode == HeroMode.dark) return _buildHeroDark();
    return _buildHeroGradient();
  }

  Widget _buildHeroDark() {
    final l10n = AppLocalizations.of(context);
    final heroImage =
        _cards.isNotEmpty ? _cards.first[_cfg.heroImageKey] as String : '';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        height: 16.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: _cfg.heroGradient,
        ),
        child: Stack(
          children: [
            if (heroImage.isNotEmpty)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadiusDirectional.only(
                    topEnd: Radius.circular(16),
                    bottomEnd: Radius.circular(16),
                  ),
                  child: CustomImageWidget(
                    imageUrl: heroImage,
                    width: 40.w,
                    height: 16.h,
                    fit: BoxFit.cover,
                    semanticLabel:
                        l10n.heroImageLabel(l10n.t(_cfg.title)),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF1A1A2E).withAlpha(200),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.t(_cfg.heroTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cfg.heroSubtitle(_cards.length, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGradient() {
    final l10n = AppLocalizations.of(context);
    final heroImage =
        _cards.isNotEmpty ? _cards.first[_cfg.heroImageKey] as String : '';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        height: 16.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: _cfg.heroGradient,
        ),
        child: Stack(
          children: [
            if (heroImage.isNotEmpty)
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadiusDirectional.only(
                    topEnd: Radius.circular(16),
                    bottomEnd: Radius.circular(16),
                  ),
                  child: CustomImageWidget(
                    imageUrl: heroImage,
                    width: 35.w,
                    height: 16.h,
                    fit: BoxFit.cover,
                    semanticLabel:
                        l10n.heroImageLabel(l10n.t(_cfg.title)),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _heroStartColor(),
                    _heroStartColor().withAlpha(180),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.t(_cfg.heroTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cfg.heroSubtitle(_cards.length, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                  if (_cfg.heroCta != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => context.push(_cfg.heroCtaRoute),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          l10n.t(_cfg.heroCta!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _heroStartColor() {
    return _cfg.heroGradient.colors.isNotEmpty
        ? _cfg.heroGradient.colors.first
        : AppTheme.primaryPinkDark;
  }

  Widget _buildTopTabs() {
    final l10n = AppLocalizations.of(context);
    final tabs = _cfg.topTabs!;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTopTab = -1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTopTab == -1
                      ? AppTheme.primaryPink
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    l10n.t(_cfg.allLabel),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _selectedTopTab == -1
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedTopTab = i;
                  _selectedSlug = '';
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTopTab == i
                        ? AppTheme.primaryPink
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      l10n.t(tabs[i].labelKey),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _selectedTopTab == i
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategories() {
    if (_cfg.subStyle == SubSectionStyle.chips) {
      return _buildSubcategoryChips();
    }
    return _buildSubcategoryGrid();
  }

  Widget _buildSubcategoryChips() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
          child: Text(
            l10n.t(_cfg.sectionTitle),
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _subs.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final sub = isAll ? null : _subs[index - 1];
              final isSelected = isAll
                  ? (_selectedSlug.isEmpty && !_topRated)
                  : (_selectedSlug == sub!.slug);
              final color = isAll ? _cfg.allColor : sub!.color;
              final bg = isAll ? _cfg.allBg : sub!.bg;
              final icon = isAll ? _cfg.allIcon : sub!.icon;
              return GestureDetector(
                onTap: () => setState(() {
                  if (isAll) {
                    _selectedSlug = '';
                    _topRated = false;
                  } else {
                    _selectedSlug = sub!.slug;
                  }
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected ? color : bg,
                          borderRadius: BorderRadius.circular(14.0),
                          border: isSelected
                              ? Border.all(color: color, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(60),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: 24,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAll ? l10n.t(_cfg.allLabel) : sub!.label,
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.charcoal
                              : AppTheme.grayText,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryGrid() {
    final l10n = AppLocalizations.of(context);
    final entries = <_Sub>[
      _Sub(
        slug: '',
        label: l10n.t(_cfg.allLabel),
        enLabel: l10n.t(_cfg.allLabel),
        icon: _cfg.allIcon,
        color: _cfg.allColor,
        bg: _cfg.allBg,
      ),
      ..._subs,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.t(_cfg.sectionTitle),
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(_cfg.seeAllRoute),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppTheme.primaryPinkDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final cat = entries[index];
              return GestureDetector(
                onTap: () => setState(() => _selectedSlug = cat.slug),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cat.bg,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.label,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.charcoal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context);
    final filters = _filters(l10n);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _isFilterSelected(filter, l10n);
            return GestureDetector(
              onTap: () => _selectFilter(filter, l10n),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _cfg.accentColor : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? _cfg.accentColor
                        : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.grayText,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isFilterSelected(String filter, AppLocalizations l10n) {
    if (filter == l10n.t(_cfg.allLabel)) {
      return _selectedSlug.isEmpty && !_topRated && _groupSelection.isEmpty;
    }
    if (filter == l10n.topRated) return _topRated;
    final sub = _subs.where((s) => s.label == filter);
    return sub.isNotEmpty && sub.first.slug == _selectedSlug;
  }

  void _selectFilter(String filter, AppLocalizations l10n) {
    setState(() {
      if (filter == l10n.t(_cfg.allLabel)) {
        _selectedSlug = '';
        _topRated = false;
        _groupSelection.clear();
      } else if (filter == l10n.topRated) {
        _topRated = true;
      } else {
        final sub = _subs.where((s) => s.label == filter);
        if (sub.isNotEmpty) {
          _selectedSlug = sub.first.slug;
          _topRated = false;
        }
      }
    });
  }

  Widget _buildSectionFilters() {
    final groups = _sectionGroups;
    if (groups.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final hasActive = _groupSelection.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups) ...[
            if (group.options.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.t(group.titleKey),
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.grayText,
                    ),
                  ),
                  if (hasActive)
                    GestureDetector(
                      onTap: () => setState(_groupSelection.clear),
                      child: Text(
                        l10n.t('clearFilters'),
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: _cfg.accentColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: AppTheme.chipHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: group.options.length,
                  itemBuilder: (context, i) {
                    final option = group.options[i];
                    final isSelected =
                        _groupSelection[group.id] == option.value;
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          _groupSelection.remove(group.id);
                        } else {
                          _groupSelection[group.id] = option.value;
                        }
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _cfg.accentColor
                              : AppTheme.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(
                            color: isSelected
                                ? _cfg.accentColor
                                : AppTheme.borderLight,
                          ),
                        ),
                        child: Text(
                          option.label,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppTheme.grayText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final items = _filteredCards;
    if (_cfg.resultsCount != null) return _buildResultsCount(items);
    return _buildResultsTitle(items);
  }

  Widget _buildResultsCount(List<Map<String, dynamic>> items) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.t(_cfg.resultsCount!, args: {'count': '${items.length}'}),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 16,
                      color: AppTheme.grayText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.sort,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            _buildEmptyState()
          else
            ..._buildCards(items),
        ],
      ),
    );
  }

  Widget _buildResultsTitle(List<Map<String, dynamic>> items) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.t(_cfg.resultsTitle!),
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                  maxLines: 2,
                ),
              ),
              if (_cfg.resultsSeeAll)
                GestureDetector(
                  onTap: () => context.push(_cfg.seeAllRoute),
                  child: Text(
                    l10n.seeAll,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppTheme.primaryPinkDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _buildEmptyState()
          else
            ..._buildCards(items),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedSlug.isNotEmpty ||
      _topRated ||
      _groupSelection.isNotEmpty ||
      _searchController.text.trim().isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _selectedSlug = '';
      _topRated = false;
      _groupSelection.clear();
      _searchController.clear();
    });
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: primary ? _cfg.accentColor : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? _cfg.accentColor : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: primary ? Colors.white : _cfg.accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: primary ? Colors.white : AppTheme.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final canPop = context.canPop();
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _cfg.allBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _cfg.allIcon,
                size: 38,
                color: _cfg.allColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.t(_cfg.emptyTitle),
              style: GoogleFonts.cairo(
                fontSize: 15.sp,
                color: AppTheme.charcoal,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('emptyStateSubtitle'),
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppTheme.grayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  if (_hasActiveFilters)
                    _actionButton(
                      icon: Icons.filter_alt_off_outlined,
                      label: l10n.t('clearFilters'),
                      onTap: _clearAllFilters,
                      primary: true,
                    ),
                  _actionButton(
                    icon: Icons.explore_outlined,
                    label: l10n.t('exploreOtherCategories'),
                    onTap: () => context.go(AppRoutes.homeScreen),
                  ),
                  if (canPop)
                    _actionButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: l10n.back,
                      onTap: () => context.pop(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCards(List<Map<String, dynamic>> items) {
    switch (_cfg.layout) {
      case CategoryLayout.grid:
        return [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildGridCard(items[index]),
          ),
        ];
      case CategoryLayout.stack:
        return items.asMap().entries
            .map(
              (entry) => _buildStackCard(entry.value, entry.key),
            )
            .toList();
      case CategoryLayout.salon:
        return items.map(_buildSalonCard).toList();
      case CategoryLayout.job:
        return items.asMap().entries
            .map(
              (entry) => _buildJobCard(entry.value, entry.key),
            )
            .toList();
      case CategoryLayout.row:
        return items.map(_buildRowCard).toList();
    }
  }

  Widget _buildRowCard(Map<String, dynamic> item) {
    final cfg = _cfg;
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(cfg.detailRoute, extra: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(16),
                bottomStart: Radius.circular(16),
              ),
              child: CustomImageWidget(
                imageUrl: item['image'] as String,
                width: 28.w,
                height: 12.h,
                fit: BoxFit.cover,
                semanticLabel: l10n.rowCardLabel(
                  item['name'] as String,
                  item['category'] as String? ?? l10n.services,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Color(item['badgeColor'] as int),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              item['badge'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (item['isOpen'] as bool)
                                ? AppTheme.success.withAlpha(30)
                                : AppTheme.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            (item['isOpen'] as bool)
                                ? l10n.statusOpen
                                : l10n.statusClosed,
                            style: GoogleFonts.cairo(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: (item['isOpen'] as bool)
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['name'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['category'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppTheme.grayText,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item['location'] as String,
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: AppTheme.grayText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${item['rating']} (${item['reviews']})',
                              style: GoogleFonts.cairo(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          l10n.localizePrice(item['price'] as String),
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> p) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(_cfg.detailRoute, extra: p),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomImageWidget(
                      imageUrl: p['image'] as String,
                      fit: BoxFit.cover,
                      semanticLabel:
                          l10n.productPhotoLabel(p['title'] as String),
                    ),
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Color(p['badgeColor'] as int),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          p['badge'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: GestureDetector(
                        onTap: () => setState(
                          () => p['isSaved'] = !(p['isSaved'] as bool),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(230),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            (p['isSaved'] as bool)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: (p['isSaved'] as bool)
                                ? AppTheme.primaryPinkDark
                                : AppTheme.grayText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p['brand'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: AppTheme.grayText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.localizePrice(p['price'] as String),
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (p['price'] != p['originalPrice'])
                        Flexible(
                          child: Text(
                            l10n.localizePrice(p['originalPrice'] as String),
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: AppTheme.grayText,
                              decoration: TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFB547),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${p['rating']}',
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          ' (${p['reviews']})',
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: AppTheme.grayText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackCard(Map<String, dynamic> p, int index) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(_cfg.detailRoute, extra: p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CustomImageWidget(
                    imageUrl: p['image'] as String,
                    width: double.infinity,
                    height: 18.h,
                    fit: BoxFit.cover,
                    semanticLabel:
                        l10n.propertyExteriorLabel(p['title'] as String),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(p['badgeColor'] as int),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      p['badge'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => p['isSaved'] = !(p['isSaved'] as bool)),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (p['isSaved'] as bool)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 18,
                        color: (p['isSaved'] as bool)
                            ? AppTheme.primaryPinkDark
                            : AppTheme.grayText,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 10,
                  end: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      p['type'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.grayText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p['location'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: AppTheme.grayText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((p['beds'] as int? ?? 0) > 0) ...[
                        _buildMetaChip(
                            Icons.bed_rounded, '${p['beds']} ${l10n.beds}'),
                        const SizedBox(width: 6),
                      ],
                      if ((p['baths'] as int? ?? 0) > 0) ...[
                        _buildMetaChip(
                          Icons.bathtub_outlined,
                          '${p['baths']} ${l10n.baths}',
                        ),
                        const SizedBox(width: 6),
                      ],
                      if ((p['area'] as String? ?? '').isNotEmpty) ...[
                        _buildMetaChip(
                          Icons.square_foot_rounded,
                          p['area'] as String,
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Spacer(),
                      Text(
                        l10n.localizePrice(p['price'] as String),
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.grayText),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              color: AppTheme.grayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonCard(Map<String, dynamic> salon) {
    final l10n = AppLocalizations.of(context);
    final isSaved = salon['isSaved'] as bool;
    return GestureDetector(
      onTap: () => context.push(_cfg.detailRoute, extra: salon),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CustomImageWidget(
                    imageUrl: salon['image'] as String,
                    width: double.infinity,
                    height: 16.h,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.salonInteriorLabel(
                        salon['name'] as String),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(salon['badgeColor'] as int),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      salon['badge'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: GestureDetector(
                    onTap: () => setState(() => salon['isSaved'] = !isSaved),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 18,
                        color: isSaved
                            ? AppTheme.primaryPinkDark
                            : AppTheme.charcoal,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.openNow,
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          salon['name'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${salon['rating']}',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      Text(
                        ' (${salon['reviews']})',
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    salon['category'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: _cfg.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppTheme.grayText,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          salon['location'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: AppTheme.grayText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        l10n.localizePrice(salon['price'] as String),
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push(_cfg.detailRoute, extra: salon),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cfg.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        l10n.bookNow,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, int index) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(_cfg.detailRoute, extra: job),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: CustomImageWidget(
                imageUrl: job['logo'] as String,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                semanticLabel:
                    l10n.companyLogoLabel(job['company'] as String),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${job['company']} – ${job['location']}',
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppTheme.grayText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.localizePrice(job['salary'] as String),
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPinkLight,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      job['type'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryPinkDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  job['isSaved'] = !(job['isSaved'] as bool);
                });
              },
              child: Icon(
                (job['isSaved'] as bool)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: (job['isSaved'] as bool)
                    ? AppTheme.primaryPinkDark
                    : AppTheme.grayText,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _fashionIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('women') || l.contains('نساء') || l.contains('نسائية') || l.contains('حجاب')) return Icons.woman_rounded;
  if (l.contains('men') || l.contains('رجال') || l.contains('رجالية') || l.contains('بدلة')) return Icons.man_rounded;
  if (l.contains('kid') || l.contains('أطفال') || l.contains('婴')) return Icons.child_care_rounded;
  if (l.contains('shoe') || l.contains('حذاء') || l.contains('bag') || l.contains('حقيبة') || l.contains('أحذية')) return Icons.shopping_bag_rounded;
  if (l.contains('watch') || l.contains('jewel') || l.contains('ساعة') || l.contains('مجوهرات')) return Icons.diamond_outlined;
  if (l.contains('sport') || l.contains('رياضي') || l.contains('gym')) return Icons.sports_gymnastics_rounded;
  if (l.contains('perfume') || l.contains('oud') || l.contains('عطر') || l.contains('عود') || l.contains('عطور')) return Icons.spa_rounded;
  if (l.contains('evening') || l.contains('سهرة') || l.contains('حفل') || l.contains('ملابسية')) return Icons.dry_cleaning_rounded;
  if (l.contains('abaya') || l.contains('عبا')) return Icons.woman_rounded;
  if (l.contains('dress') || l.contains('فستان') || l.contains('khal')) return Icons.dry_cleaning_rounded;
  if (l.contains('modest') || l.contains('محتشم')) return Icons.checkroom_rounded;
  return Icons.checkroom_rounded;
}

IconData _realEstateIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('apartment') || l.contains('flat') || l.contains('شقة')) return Icons.domain_rounded;
  if (l.contains('villa') || l.contains('فيلا')) return Icons.villa_rounded;
  if (l.contains('office') || l.contains('مكتب')) return Icons.business_center_rounded;
  if (l.contains('studio') || l.contains('ستوديو')) return Icons.bed_rounded;
  if (l.contains('townhouse') || l.contains('تاون')) return Icons.holiday_village_rounded;
  if (l.contains('retail') || l.contains('shop') || l.contains('محل')) return Icons.storefront_rounded;
  if (l.contains('chalet') || l.contains('شاليه')) return Icons.beach_access_rounded;
  if (l.contains('residential') || l.contains('سكني')) return Icons.home_rounded;
  if (l.contains('luxury') || l.contains('فاخر')) return Icons.auto_awesome_rounded;
  return Icons.apartment_rounded;
}

IconData _clinicsIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('dental') || l.contains('أسنان') || l.contains('dent')) return Icons.health_and_safety_rounded;
  if (l.contains('skin') || l.contains('derma') || l.contains('بشرة') || l.contains('جلدية')) return Icons.face_retouching_natural_rounded;
  if (l.contains('spa') || l.contains('massage') || l.contains('مساج')) return Icons.spa_rounded;
  if (l.contains('gym') || l.contains('fit') || l.contains('لياقة')) return Icons.fitness_center_rounded;
  if (l.contains('hair') || l.contains('salon') || l.contains('nail') || l.contains('شعر') || l.contains('أظافر')) return Icons.content_cut_rounded;
  if (l.contains('laser') || l.contains('ليزر')) return Icons.auto_fix_high_rounded;
  if (l.contains('eye') || l.contains('vision') || l.contains('عين') || l.contains('نظر')) return Icons.remove_red_eye_rounded;
  if (l.contains('lab') || l.contains('test') || l.contains('مختبر') || l.contains('تحليل')) return Icons.science_rounded;
  if (l.contains('pediatric') || l.contains('kids') || l.contains('أطفال')) return Icons.child_care_rounded;
  if (l.contains('physical') || l.contains('علاج طبيعي') || l.contains('physio')) return Icons.healing_rounded;
  if (l.contains('general') || l.contains('طب عام') || l.contains('عام')) return Icons.medical_services_rounded;
  return Icons.local_hospital_rounded;
}

IconData _jobsIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('tech') || l.contains('it') || l.contains('software') || l.contains('engineer') || l.contains('تقنية') || l.contains('هندس')) return Icons.computer_rounded;
  if (l.contains('sales') || l.contains('مبيعات')) return Icons.trending_up_rounded;
  if (l.contains('market') || l.contains('ad') || l.contains('تسويق') || l.contains('إعلان')) return Icons.campaign_rounded;
  if (l.contains('financ') || l.contains('account') || l.contains('مالية') || l.contains('محاسبة')) return Icons.account_balance_rounded;
  if (l.contains('educat') || l.contains('teach') || l.contains('تعليم') || l.contains('تدريس')) return Icons.school_rounded;
  if (l.contains('design') || l.contains('creative') || l.contains('تصميم') || l.contains('إبداع')) return Icons.palette_rounded;
  if (l.contains('hr') || l.contains('human') || l.contains('موارد') || l.contains('بشرية')) return Icons.groups_rounded;
  if (l.contains('health') || l.contains('medical') || l.contains('صحة') || l.contains('طبي')) return Icons.medical_services_rounded;
  if (l.contains('admin') || l.contains('إداري')) return Icons.badge_rounded;
  return Icons.work_rounded;
}

IconData _gymIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('nutrition') || l.contains('غذاء') || l.contains('تغذية')) return Icons.restaurant_menu_rounded;
  if (l.contains('physio') || l.contains('therapy') || l.contains('علاج طبيعي')) return Icons.healing_rounded;
  if (l.contains('weight loss') || l.contains('تخسيس') || l.contains('إنقاص الوزن')) return Icons.monitor_weight_rounded;
  if (l.contains('outdoor') || l.contains('خارجي') || l.contains('خارجية')) return Icons.directions_bike_rounded;
  if (l.contains('danc') || l.contains('zumba') || l.contains('رقص') || l.contains('زومبا')) return Icons.music_note_rounded;
  if (l.contains('pilates') || l.contains('barre') || l.contains('بيلاتيس') || l.contains('باريه')) return Icons.accessibility_new_rounded;
  if (l.contains('crossfit') || l.contains('hiit') || l.contains('كروس')) return Icons.whatshot_rounded;
  if (l.contains('personal') || l.contains('train') || l.contains('مدرب') || l.contains('تدريب شخصي')) return Icons.person_pin_rounded;
  if (l.contains('swim') || l.contains('pool') || l.contains('aqua') || l.contains('سباحة')) return Icons.pool_rounded;
  if (l.contains('yoga') || l.contains('يوغا')) return Icons.self_improvement_rounded;
  if (l.contains('martial') || l.contains('box') || l.contains('فنون قتال') || l.contains('ملاكمة')) return Icons.sports_martial_arts_rounded;
  if (l.contains('padel') || l.contains('tennis') || l.contains('squash') || l.contains('تنس') || l.contains('بادل')) return Icons.sports_tennis_rounded;
  if (l.contains('run') || l.contains('cardio') || l.contains('جري') || l.contains('كارديو')) return Icons.directions_run_rounded;
  if (l.contains('weight') || l.contains('وزن') || l.contains('تخسيس')) return Icons.monitor_weight_rounded;
  if (l.contains('gym') || l.contains('workout') || l.contains('fit') || l.contains('لياقة') || l.contains('صالة')) return Icons.fitness_center_rounded;
  return Icons.sports_gymnastics_rounded;
}

IconData _salonsIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('hair') || l.contains('شعر') || l.contains('قص')) return Icons.content_cut_rounded;
  if (l.contains('nail') || l.contains('أظافر') || l.contains('manicure') || l.contains('pedicure')) return Icons.brush_rounded;
  if (l.contains('skin') || l.contains('facial') || l.contains('بشرة') || l.contains('وجه') || l.contains('هيدرافيشل')) return Icons.face_retouching_natural_rounded;
  if (l.contains('makeup') || l.contains('bridal') || l.contains('مكياج') || l.contains('عرائس') || l.contains('سواريه')) return Icons.palette_rounded;
  if (l.contains('spa') || l.contains('massage') || l.contains('سبا') || l.contains('مساج')) return Icons.spa_rounded;
  if (l.contains('brow') || l.contains('lash') || l.contains('حواجب') || l.contains('رموش')) return Icons.visibility_rounded;
  if (l.contains('color') || l.contains('صبغة') || l.contains('صبغ')) return Icons.format_color_fill_rounded;
  if (l.contains('hair removal') || l.contains('إزالة شعر') || l.contains('laser') || l.contains('ليزر')) return Icons.auto_fix_high_rounded;
  return Icons.auto_awesome_rounded;
}

IconData _trainingIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('professional') || l.contains('تطوير') || l.contains('مهني')) return Icons.work_outline_rounded;
  if (l.contains('technical') || l.contains('تقني') || l.contains('برمجة')) return Icons.code_rounded;
  if (l.contains('language') || l.contains('لغة') || l.contains('عربي') || l.contains('إنجليزي')) return Icons.translate_rounded;
  if (l.contains('fitness') || l.contains('رياضي') || l.contains('تدريب')) return Icons.fitness_center_rounded;
  if (l.contains('business') || l.contains('أعمال') || l.contains('إدارة')) return Icons.business_center_rounded;
  if (l.contains('creative') || l.contains('فن') || l.contains('تصميم')) return Icons.palette_rounded;
  return Icons.school_rounded;
}
