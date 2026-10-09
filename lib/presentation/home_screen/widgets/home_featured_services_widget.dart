import '../../../core/app_export.dart';
import '../../../core/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../services/vera_api_service.dart';

class HomeFeaturedServicesWidget extends StatefulWidget {
  const HomeFeaturedServicesWidget({super.key});

  @override
  State<HomeFeaturedServicesWidget> createState() =>
      _HomeFeaturedServicesWidgetState();
}

class _HomeFeaturedServicesWidgetState
    extends State<HomeFeaturedServicesWidget> {
  List<VeraListing> _services = [];
  bool _isLoading = true;

  static const Map<String, Color> _categoryColors = {
    'clinics': AppTheme.clinics,
    'clinic': AppTheme.clinics,
    'medical': AppTheme.clinics,
    'salons': AppTheme.salons,
    'salon': AppTheme.salons,
    'beauty': AppTheme.salons,
    'gym': AppTheme.gym,
    'fitness': AppTheme.gym,
    'sports': AppTheme.gym,
    'fashion': AppTheme.fashion,
    'clothing': AppTheme.fashion,
    'real-estate': AppTheme.realEstate,
    'real estate': AppTheme.realEstate,
    'property': AppTheme.realEstate,
    'jobs': AppTheme.jobs,
    'careers': AppTheme.jobs,
  };

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    try {
      final listings = await VeraApiService.instance.fetchFeaturedListings();
      if (mounted && listings.isNotEmpty) {
        setState(() {
          _services = listings;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _colorForCategory(String category) {
    final key = category.toLowerCase();
    for (final entry in _categoryColors.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return AppTheme.primaryPink;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.featuredServices,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push(AppRoutes.salonsScreen),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPinkDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          // The card content includes translated labels whose font metrics
          // can be taller than the English fallback.
          height: 236,
          child: _isLoading
              ? _buildLoadingShimmer()
              : _services.isEmpty
              ? const SizedBox.shrink()
              : _buildApiList(),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildApiList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _services.length,
      itemBuilder: (context, i) {
        final s = _services[i];
        final catColor = _colorForCategory(s.category);
        return _ServiceCard(
          name: s.name,
          category: s.category,
          price: s.price,
          rating: s.rating,
          reviews: s.reviewCount,
          imageUrl: s.imageUrl,
          categoryColor: catColor,
          cardData: s.toCardMap(),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String name;
  final String category;
  final String price;
  final double rating;
  final int reviews;
  final String imageUrl;
  final Color categoryColor;
  final Map<String, dynamic> cardData;

  const _ServiceCard({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.categoryColor,
    required this.cardData,
  });

  String _routeForCategory() {
    final cat = '${cardData['categorySlug'] ?? ''} ${cardData['listing_type'] ?? ''} $category'.toLowerCase();
    debugPrint('[featured] route cat="$cat"');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(_routeForCategory(), extra: cardData),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: imageUrl.isNotEmpty
                  ? CustomImageWidget(
                      imageUrl: imageUrl,
                      width: 180,
                      height: 110,
                      fit: BoxFit.cover,
                      semanticLabel: l10n.serviceImageLabel(name),
                    )
                  : Container(
                      width: 180,
                      height: 110,
                      color: categoryColor.withAlpha(60),
                      child: Icon(
                        Icons.image_outlined,
                        color: categoryColor,
                        size: 32,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$rating ($reviews)',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.localizePrice(price),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPinkDark,
                      fontFeatures: [const FontFeature.tabularFigures()],
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
