import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _Section {
  final String slug;
  final String titleKey;
  final IconData icon;

  const _Section({
    required this.slug,
    required this.titleKey,
    required this.icon,
  });
}

class _OffersScreenState extends State<OffersScreen> {
  static const List<_Section> _sections = [
    _Section(slug: '', titleKey: 'allLabel', icon: Icons.grid_view_rounded),
    _Section(
      slug: 'fashion',
      titleKey: 'fashion',
      icon: Icons.diamond_rounded,
    ),
    _Section(
      slug: 'real-estate',
      titleKey: 'realEstate',
      icon: Icons.apartment_rounded,
    ),
    _Section(
      slug: 'clinics',
      titleKey: 'clinics',
      icon: Icons.health_and_safety_rounded,
    ),
    _Section(
      slug: 'jobs',
      titleKey: 'jobs',
      icon: Icons.work_outline_rounded,
    ),
    _Section(
      slug: 'fitness',
      titleKey: 'gym',
      icon: Icons.fitness_center_rounded,
    ),
    _Section(
      slug: 'beauty-salons',
      titleKey: 'salons',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  final PageController _pageController = PageController();
  List<VeraBanner> _banners = const [];
  List<VeraService> _items = const [];
  String _selectedSlug = '';
  bool _loadingBanners = true;
  bool _loadingItems = true;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _loadItems('');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    final banners = await VeraApiService.instance.fetchBanners();
    if (!mounted) return;
    setState(() {
      _banners = banners;
      _loadingBanners = false;
    });
  }

  Future<void> _loadItems(String slug) async {
    setState(() {
      _selectedSlug = slug;
      _loadingItems = true;
    });
    if (slug.isEmpty) {
      final results = await Future.wait(
        _sections
            .where((s) => s.slug.isNotEmpty)
            .map((s) => VeraApiService.instance.fetchServices(category: s.slug)),
      );
      if (!mounted) return;
      final items = <VeraService>[];
      for (final list in results) {
        items.addAll(list.take(8));
      }
      setState(() {
        _items = items;
        _loadingItems = false;
      });
    } else {
      final services =
          await VeraApiService.instance.fetchServices(category: slug);
      if (!mounted) return;
      setState(() {
        _items = services;
        _loadingItems = false;
      });
    }
  }

  String _detailRoute(VeraService s) {
    switch (_selectedSlug) {
      case 'fashion':
        return AppRoutes.fashionDetailsScreen;
      case 'real-estate':
        return AppRoutes.realEstateDetailsScreen;
      case 'clinics':
        return AppRoutes.clinicDetailsScreen;
      case 'jobs':
        return AppRoutes.jobDetailsScreen;
      case 'fitness':
        return AppRoutes.gymSportsDetailsScreen;
      case 'beauty-salons':
        return AppRoutes.salonDetailsScreen;
    }
    final cat = '${s.categorySlug} ${s.listingType} ${s.category}'.toLowerCase();
    if (cat.contains('real-estate') || cat.contains('real estate') || cat.contains('property') || cat.contains('عقار')) {
      return AppRoutes.realEstateDetailsScreen;
    } else if (cat.contains('fashion') || cat.contains('clothing')) {
      return AppRoutes.fashionDetailsScreen;
    } else if (cat.contains('clinic') || cat.contains('medical')) {
      return AppRoutes.clinicDetailsScreen;
    } else if (cat.contains('salon') || cat.contains('beauty')) {
      return AppRoutes.salonDetailsScreen;
    } else if (cat.contains('gym') ||
        cat.contains('fitness') ||
        cat.contains('sport')) {
      return AppRoutes.gymSportsDetailsScreen;
    } else if (cat.contains('job') || cat.contains('career')) {
      return AppRoutes.jobDetailsScreen;
    }
    return AppRoutes.clinicDetailsScreen;
  }

  Color _categoryColor(VeraService s) {
    final key = s.category.toLowerCase();
    if (key.contains('real-estate') || key.contains('real estate') || key.contains('property') || key.contains('عقار')) {
      return AppTheme.realEstate;
    } else if (key.contains('fashion') || key.contains('clothing')) {
      return AppTheme.fashion;
    } else if (key.contains('clinic') || key.contains('medical')) {
      return AppTheme.clinics;
    } else if (key.contains('salon') || key.contains('beauty')) {
      return AppTheme.salons;
    } else if (key.contains('gym') ||
        key.contains('fitness') ||
        key.contains('sport')) {
      return AppTheme.gym;
    } else if (key.contains('job') || key.contains('career')) {
      return AppTheme.jobs;
    }
    return AppTheme.primaryPink;
  }

  void _openBanner(VeraBanner banner) {
    final route = banner.targetRoute.toLowerCase();
    String? target;
    if (route.contains('fashion')) {
      target = AppRoutes.fashionHubScreen;
    } else if (route.contains('real') || route.contains('property')) {
      target = AppRoutes.realEstateScreen;
    } else if (route.contains('clinic') || route.contains('medical')) {
      target = AppRoutes.clinicsScreen;
    } else if (route.contains('salon') || route.contains('beauty')) {
      target = AppRoutes.salonsScreen;
    } else if (route.contains('job') || route.contains('career')) {
      target = AppRoutes.jobsScreen;
    } else if (route.contains('gym') ||
        route.contains('fitness') ||
        route.contains('sport')) {
      target = AppRoutes.gymSportsScreen;
    } else if (route.contains('search')) {
      target = AppRoutes.searchScreen;
    }
    if (target != null) context.push(target);
  }

  String _formatPrice(VeraService s, AppLocalizations l10n) {
    if (s.price <= 0) return l10n.priceOnRequest;
    final isWhole = s.price == s.price.roundToDouble();
    final value =
        isWhole ? s.price.toInt().toString() : s.price.toStringAsFixed(2);
    return l10n.currencyAed(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadBanners();
            await _loadItems(_selectedSlug);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(l10n)),
              if (_loadingBanners)
                const SliverToBoxAdapter(child: SizedBox.shrink())
              else
                SliverToBoxAdapter(child: _buildBannerCarousel(l10n)),
              SliverToBoxAdapter(child: _buildSectionChips(l10n)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                sliver: _buildItemsGrid(l10n, isTablet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryPinkLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              size: 22,
              color: AppTheme.primaryPinkDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.promotionsOffers,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.promotionsOffersSubtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel(AppLocalizations l10n) {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: _banners.length,
            itemBuilder: (context, i) => _BannerCard(
              banner: _banners[i],
              onTap: () => _openBanner(_banners[i]),
            ),
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              final active = i == _bannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryPinkDark
                      : AppTheme.borderMedium,
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionChips(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: AppTheme.chipHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _sections.length,
          itemBuilder: (context, i) {
            final section = _sections[i];
            final isSelected = _selectedSlug == section.slug;
            return GestureDetector(
              onTap: () => _loadItems(section.slug),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryPink
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryPink
                        : AppTheme.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      section.icon,
                      size: AppTheme.iconXs,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.grayText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.t(section.titleKey),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? Colors.white : AppTheme.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  SliverGrid _buildItemsGrid(AppLocalizations l10n, bool isTablet) {
    if (_loadingItems) {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => Container(
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          childCount: 6,
        ),
      );
    }
    if (_items.isEmpty) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: AppTheme.grayText,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('noOffersFound'),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppTheme.grayText,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          childCount: 1,
        ),
      );
    }
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => _OfferCard(
          service: _items[i],
          color: _categoryColor(_items[i]),
          price: _formatPrice(_items[i], l10n),
          onTap: () => context.push(
            _detailRoute(_items[i]),
            extra: _items[i].toCardMap(),
          ),
        ),
        childCount: _items.length,
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final VeraBanner banner;
  final VoidCallback onTap;

  const _BannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            banner.imageUrl.isNotEmpty
                ? CustomImageWidget(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    semanticLabel: banner.title,
                  )
                : Container(
                    color: _hexColor(banner.bgColorHex, AppTheme.primaryPink),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _hexColor(banner.bgColorHex, AppTheme.primaryPink)
                        .withAlpha(200),
                    Colors.black.withAlpha(120),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner.title.isNotEmpty)
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  if (banner.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withAlpha(230),
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

  Color _hexColor(String hex, Color fallback) {
    final value = hex.replaceAll('#', '');
    if (value.length == 6) {
      final parsed = int.tryParse('FF$value', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }
}

class _OfferCard extends StatelessWidget {
  final VeraService service;
  final Color color;
  final String price;
  final VoidCallback onTap;

  const _OfferCard({
    required this.service,
    required this.color,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoryText =
        service.category.isNotEmpty ? service.category : l10n.services;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: service.imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: service.imageUrl,
                          height: 96,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          semanticLabel: l10n.serviceImageLabel(service.name),
                        )
                      : Container(
                          height: 96,
                          width: double.infinity,
                          color: color.withAlpha(60),
                          child: Icon(
                            Icons.local_offer_outlined,
                            color: color,
                            size: 30,
                          ),
                        ),
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
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      categoryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${service.rating}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
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
}
