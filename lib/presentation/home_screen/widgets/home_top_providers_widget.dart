import '../../../core/app_export.dart';
import '../../../core/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../services/vera_api_service.dart';

class HomeTopProvidersWidget extends StatefulWidget {
  const HomeTopProvidersWidget({super.key});

  @override
  State<HomeTopProvidersWidget> createState() => _HomeTopProvidersWidgetState();
}

class _HomeTopProvidersWidgetState extends State<HomeTopProvidersWidget> {
  List<VeraProvider> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await VeraApiService.instance.fetchTopProviders();
      if (mounted && providers.isNotEmpty) {
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
              Text(
                l10n.topProviders,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              GestureDetector(
               onTap: () => context.push(AppRoutes.allProvidersScreen),
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
        if (_isLoading)
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          )
        else
          ..._providers
              .take(4)
              .map(
                (p) => _ProviderCard(
                  id: p.id,
                  name: p.name,
                  category: p.category,
                  city: p.city,
                  rating: p.rating,
                  reviews: p.reviewCount,
                  imageUrl: p.imageUrl,
                   isVerified: p.isVerified,
                   email: p.email,
                ),
              ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final String city;
  final double rating;
  final int reviews;
  final String imageUrl;
  final bool isVerified;
  final String email;

  const _ProviderCard({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    this.isVerified = false,
    this.email = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? CustomImageWidget(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.providerLogoLabel(name),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppTheme.primaryPinkLight,
                    child: const Icon(
                      Icons.store_rounded,
                      color: AppTheme.primaryPinkDark,
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified)
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppTheme.info,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  city.isNotEmpty ? '$category • $city' : category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.grayText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$rating ($reviews)',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.push(
              AppRoutes.publicProviderProfileScreen,
              extra: {
                'id': id,
                'name': name,
                'category': category,
                'city': city,
                'rating': rating,
                'reviews': reviews,
                'imageUrl': imageUrl,
                'isVerified': isVerified,
                'email': email,
                'followers': 0,
              },
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryPinkDark,
              side: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
              minimumSize: const Size(80, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n.view),
          ),
        ],
      ),
    );
  }
}
