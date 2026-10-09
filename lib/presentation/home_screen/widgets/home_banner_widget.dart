import '../../../core/app_export.dart';
import '../../../core/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../services/vera_api_service.dart';

// Anatomy LOCKED: full-width card, gradient bg, text left + image right + CTA button
class _BannerData {
  final String title;
  final String subtitle;
  final String ctaText;
  final String imageUrl;
  final Color bgColor;
  final String targetRoute;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.imageUrl,
    required this.bgColor,
    this.targetRoute = '',
  });
}

class HomeBannerWidget extends StatefulWidget {
  const HomeBannerWidget({super.key});

  @override
  State<HomeBannerWidget> createState() => _HomeBannerWidgetState();
}

class _HomeBannerWidgetState extends State<HomeBannerWidget> {
  final PageController _controller = PageController();
  int _current = 0;
  List<_BannerData> _banners = [];
  bool _isLoading = true;

  static const List<Color> _bgColors = [
    Color(0xFFEFA9B8),
    Color(0xFFD898AA),
    Color(0xFFDCCFE8),
    Color(0xFFC8A96A),
    Color(0xFFB8D4E8),
  ];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final apiBanners = await VeraApiService.instance.fetchBanners();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final banners = apiBanners.asMap().entries.map((entry) {
        final b = entry.value;
        final colorHex = b.bgColorHex.replaceAll('#', '');
        Color bgColor;
        try {
          bgColor = Color(int.parse('FF$colorHex', radix: 16));
        } catch (_) {
          bgColor = _bgColors[entry.key % _bgColors.length];
        }
        return _BannerData(
          title: b.title,
          subtitle: b.subtitle,
          ctaText: b.ctaText,
          imageUrl: b.imageUrl,
          bgColor: bgColor,
          targetRoute: b.targetRoute,
        );
      }).toList();

      // The backend may publish only one hero banner. Use real featured
      // listings from /home/data as additional slides until more banners are
      // configured server-side.
      if (banners.length < 2) {
        final featured = await VeraApiService.instance.fetchFeaturedListings();
        for (final listing in featured.take(4)) {
          banners.add(
            _BannerData(
              title: listing.name,
              subtitle: listing.providerName.isNotEmpty
                  ? listing.providerName
                  : listing.category,
              ctaText: l10n.t('view'),
              imageUrl: listing.imageUrl,
              bgColor: _bgColors[banners.length % _bgColors.length],
              targetRoute: _routeForCategory(listing.category),
            ),
          );
        }
      }

      if (mounted && banners.isNotEmpty) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
        _startAutoScroll();
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _banners = [];
        _isLoading = false;
      });
    }
  }

  String _routeForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('fashion')) return AppRoutes.fashionHubScreen;
    if (value.contains('real') || value.contains('property')) {
      return AppRoutes.realEstateScreen;
    }
    if (value.contains('clinic') || value.contains('medical')) {
      return AppRoutes.clinicsScreen;
    }
    if (value.contains('salon') || value.contains('beauty')) {
      return AppRoutes.salonsScreen;
    }
    if (value.contains('gym') || value.contains('fitness')) {
      return AppRoutes.gymSportsScreen;
    }
    if (value.contains('job')) return AppRoutes.jobsScreen;
    return AppRoutes.searchScreen;
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || _banners.isEmpty) return;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryPink,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _banners.length,
            itemBuilder: (context, i) => _BannerCard(banner: _banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _current == i
                    ? AppTheme.primaryPink
                    : AppTheme.borderMedium,
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _BannerData banner;
  const _BannerCard({required this.banner});

  String _routeForBanner() {
    if (banner.targetRoute.isNotEmpty &&
        (banner.targetRoute.startsWith('/') ||
            banner.targetRoute.startsWith('http'))) {
      return banner.targetRoute;
    }
    final title = banner.title.toLowerCase();
    if (title.contains('fashion') ||
        title.contains('collection') ||
        title.contains('shop')) {
      return AppRoutes.fashionHubScreen;
    } else if (title.contains('home') ||
        title.contains('estate') ||
        title.contains('villa')) {
      return AppRoutes.realEstateScreen;
    } else if (title.contains('salon') ||
        title.contains('pamper') ||
        title.contains('beauty')) {
      return AppRoutes.salonsScreen;
    } else if (title.contains('gym') || title.contains('fitness')) {
      return AppRoutes.gymSportsScreen;
    } else if (title.contains('clinic') || title.contains('health')) {
      return AppRoutes.clinicsScreen;
    }
    return AppRoutes.searchScreen;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(_routeForBanner()),
      child: Container(
        decoration: BoxDecoration(
          color: banner.bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: banner.bgColor.withAlpha(102),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text content left
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      banner.title,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      banner.subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withAlpha(217),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        banner.ctaText,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Image right
            Expanded(
              flex: 45,
              child: ClipRRect(
                borderRadius: const BorderRadiusDirectional.only(
                  topEnd: Radius.circular(20),
                  bottomEnd: Radius.circular(20),
                ),
                child: banner.imageUrl.isNotEmpty
                    ? CustomImageWidget(
                        imageUrl: banner.imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        semanticLabel: l10n.bannerSemanticLabel(banner.title),
                      )
                    : Container(
                        height: 160,
                        color: banner.bgColor.withAlpha(180),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
