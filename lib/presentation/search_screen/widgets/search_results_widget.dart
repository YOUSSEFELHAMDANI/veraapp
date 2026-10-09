import '../../../core/app_export.dart';
import '../../../core/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../services/vera_api_service.dart';

class SearchResultsWidget extends StatefulWidget {
  final String query;
  final String category;
  final bool isTablet;

  const SearchResultsWidget({
    required this.query,
    required this.category,
    this.isTablet = false,
    super.key,
  });

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  List<VeraListing> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';
  String _lastCategory = '';

  @override
  void didUpdateWidget(SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query ||
        widget.category != oldWidget.category) {
      _performSearch();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) {
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    if (_isLoading) return;
    if (widget.query == _lastQuery && widget.category == _lastCategory) return;

    _lastQuery = widget.query;
    _lastCategory = widget.category;

    setState(() => _isLoading = true);

    try {
      final results = await VeraApiService.instance.search(
        query: widget.query,
        category: widget.category,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crossAxisCount = widget.isTablet ? 3 : 2;

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              l10n.t('searchingFor', args: {'query': widget.query}),
              style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Use API results if available
    if (_results.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              l10n.t('noResultsFor', args: {'query': widget.query}),
              style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppTheme.grayText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tryDifferentKeyword,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grayText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              l10n.t('resultsFoundFor', args: {'count': '${_results.length}', 'query': widget.query}),
            style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: _results.length,
            itemBuilder: (context, i) {
              final r = _results[i];
              return _ResultCard(
                name: r.name,
                category: r.category,
                price: r.price,
                rating: r.rating,
                imageUrl: r.imageUrl,
                type: r.type,
                cardData: r.toCardMap(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String name;
  final String category;
  final String price;
  final double rating;
  final String imageUrl;
  final String type;
  final Map<String, dynamic> cardData;

  const _ResultCard({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.type,
    required this.cardData,
  });

  String _routeForCategory() {
    final cat = '${cardData['categorySlug'] ?? ''} ${cardData['listing_type'] ?? ''} $category'.toLowerCase();
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
    // Default fallback: real estate details
    return AppRoutes.realEstateDetailsScreen;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(_routeForCategory(), extra: cardData),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? CustomImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            semanticLabel: l10n.t('listingImageLabel', args: {'name': name}),
                          )
                        : Container(
                            color: AppTheme.borderLight,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppTheme.grayText,
                              size: 32,
                            ),
                          ),
                  ),
                  PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                      color: AppTheme.primaryPinkDark,
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(235),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.grayText,
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
                        '$rating',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
