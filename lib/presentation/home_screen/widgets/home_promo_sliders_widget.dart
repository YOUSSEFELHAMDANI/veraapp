import '../../../core/app_export.dart';
import '../../../core/app_localizations.dart';
import '../../../core/user_interest_tracker.dart';
import '../../../routes/app_routes.dart';
import '../../../services/vera_api_service.dart';

// ─── Best Sellers Slider ───────────────────────────────────────────────────

class HomeBestSellersWidget extends StatelessWidget {
  const HomeBestSellersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ApiPromoSection(
      title: l10n.bestSellers,
      badge: l10n.bestSeller,
      seeAllRoute: AppRoutes.salonsScreen,
      loader: VeraApiService.instance.fetchBestSellers,
    );
  }
}

// ─── Most Viewed Slider ────────────────────────────────────────────────────

class HomeMostViewedWidget extends StatelessWidget {
  const HomeMostViewedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ApiPromoSection(
      title: l10n.mostViewed,
      badge: l10n.mostViewed,
      seeAllRoute: AppRoutes.salonsScreen,
      loader: VeraApiService.instance.fetchMostViewed,
    );
  }
}

// ─── Our Recommendations Slider ───────────────────────────────────────────

class HomeRecommendationsWidget extends StatelessWidget {
  const HomeRecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tracker = UserInterestTracker.instance;
    return _ApiPromoSection(
      title: l10n.recommendedForYou,
      badge: l10n.forYou,
      seeAllRoute: AppRoutes.salonsScreen,
      loader: () async {
        final services = await VeraApiService.instance.fetchServices();
        final List<Map<String, dynamic>> serviceMaps = services.map((s) => <String, dynamic>{
          'id': s.id,
          'title': s.name,
          'name': s.name,
          'category': s.category,
          'categorySlug': s.category,
          'price': s.price.toString(),
          'priceNumeric': s.price,
          'rating': s.rating,
          'reviews': s.reviews,
          'imageUrl': s.imageUrl,
          'description': s.description,
          'provider': s.provider,
          'providerName': s.provider,
        }).toList();
        final ranked = tracker.rankByRelevance(serviceMaps);
        return ranked.take(10).map((s) => VeraListing(
          id: s['id']?.toString() ?? '',
          name: s['name']?.toString() ?? '',
          category: s['category']?.toString() ?? '',
          categorySlug: s['categorySlug']?.toString() ?? '',
          price: _formatPrice((s['price'] as num?)?.toDouble() ?? 0, l10n),
          rating: (s['rating'] as num?)?.toDouble() ?? 0,
          reviewCount: s['reviews'] as int? ?? 0,
          imageUrl: s['imageUrl']?.toString() ?? '',
          location: '',
          type: 'service',
          isFeatured: false,
          isVerified: false,
          description: s['description']?.toString() ?? '',
          providerName: s['providerName']?.toString() ?? '',
        )).toList();
      },
    );
  }
}

// ─── API-backed section ────────────────────────────────────────────────────

class _ApiPromoSection extends StatefulWidget {
  final String title;
  final String badge;
  final String seeAllRoute;
  final Future<List<VeraListing>> Function() loader;

  const _ApiPromoSection({
    required this.title,
    required this.badge,
    required this.seeAllRoute,
    required this.loader,
  });

  @override
  State<_ApiPromoSection> createState() => _ApiPromoSectionState();
}

class _ApiPromoSectionState extends State<_ApiPromoSection> {
  List<_PromoItem> _items = [];
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
    _load();
  }

  Future<void> _load() async {
    try {
      final services = await widget.loader();
      if (mounted) {
        setState(() {
          _items = services
              .map(
                (s) => _PromoItem(
                  name: s.name,
                  category: s.category,
                  price: s.price,
                  rating: s.rating,
                  reviews: s.reviewCount,
                  imageUrl: s.imageUrl,
                  categoryColor: _colorForCategory(s.category),
                  badge: widget.badge,
                  cardData: s.toCardMap(),
                ),
              )
              .take(10)
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _isLoading = false;
        });
      }
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
    if (!_isLoading && _items.isEmpty) return const SizedBox.shrink();
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
                  widget.title,
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
                onTap: () => context.push(widget.seeAllRoute),
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
          height: 236,
          child: _isLoading
              ? ListView.builder(
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
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _items.length,
                  itemBuilder: (context, i) =>
                      _PromoCard(item: _items[i]),
                ),
        ),
      ],
    );
  }
}

String _formatPrice(double price, AppLocalizations l10n) {
  if (price <= 0) return l10n.priceOnRequest;
  final isWhole = price == price.roundToDouble();
  final value = isWhole ? price.toInt().toString() : price.toStringAsFixed(2);
  return l10n.currencyAed(value);
}

// ─── Shared Card Widget ───────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  final _PromoItem item;

  const _PromoCard({required this.item});

  String _routeForCategory() {
    final cat = '${item.cardData['categorySlug'] ?? ''} ${item.cardData['listing_type'] ?? ''} ${item.category}'.toLowerCase();
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
    final categoryText =
        item.category.isNotEmpty ? item.category : l10n.services;
    return GestureDetector(
      onTap: () => context.push(_routeForCategory(), extra: item.cardData),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: item.imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: item.imageUrl,
                          width: 180,
                          height: 110,
                          fit: BoxFit.cover,
                          semanticLabel: l10n.serviceImageLabel(item.name),
                        )
                      : Container(
                          width: 180,
                          height: 110,
                          color: item.categoryColor.withAlpha(60),
                          child: Icon(
                            Icons.image_outlined,
                            color: item.categoryColor,
                            size: 32,
                          ),
                        ),
                ),
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      item.badge,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.categoryColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      categoryText,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: item.categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
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
                      Flexible(
                        child: Text(
                          '${item.rating} (${item.reviews})',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppTheme.grayText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.localizePrice(item.price),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPinkDark,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ─── Data Model ───────────────────────────────────────────────────────────

class _PromoItem {
  final String name;
  final String category;
  final String price;
  final double rating;
  final int reviews;
  final String imageUrl;
  final Color categoryColor;
  final String badge;
  final Map<String, dynamic> cardData;

  const _PromoItem({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.categoryColor,
    required this.badge,
    required this.cardData,
  });
}
