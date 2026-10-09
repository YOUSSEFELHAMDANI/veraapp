import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../core/auth_gate.dart';
import '../../core/app_localizations.dart';
import '../../services/vera_api_service.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with AuthGuard {
  bool _isLoading = true;

  // ── All favorites in one list ────────────────────────────────
  List<Map<String, dynamic>> _allFavorites = [];

  // ── Cart state ─────────────────────────────────────────────────
  final Set<String> _cartIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final items = await VeraApiService.instance.fetchWishlist();
      if (!mounted) return;
      final all = <Map<String, dynamic>>[];
      for (final item in items) {
        all.add(_itemToCardMap(item));
      }
      setState(() {
        _allFavorites = all;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allFavorites = [];
        _isLoading = false;
      });
    }
  }

  String _tabTypeFor(VeraWishlistItem i) {
    final t = i.type.toLowerCase();
    if (t.contains('property') || t.contains('real') || t.contains('estate')) {
      return 'property';
    }
    if (t.contains('job')) return 'job';
    return 'service';
  }

  Map<String, dynamic> _itemToCardMap(VeraWishlistItem i) {
    final tab = _tabTypeFor(i);
    final category = i.category.isNotEmpty ? i.category : 'Service';
    final tag = tab == 'property' ? 'For Sale' : category;
    final priceStr = i.price > 0
        ? 'AED ${i.price.toStringAsFixed(i.price == i.price.roundToDouble() ? 0 : 2)}'
        : 'Price on request';
    return {
      'id': i.id,
      'name': i.name,
      'title': i.name,
      'category': category,
      'categorySlug': category,
      'subcategory': category,
      'location': '',
      'rating': i.rating,
      'reviews': 0,
      'price': i.price,
      'image': i.imageUrl,
      'badge': tag,
      'badgeColor': 0xFFC8A96A,
      'isOpen': true,
      'isSaved': true,
      'description': '',
      'type': i.type,
      'providerName': category,
      'providerAvatar': '',
      'providerVerified': false,
      'propertyType': category,
      'beds': 0,
      'baths': 0,
      'area': '',
      'company': category,
      'salary': priceStr,
      'logo': i.imageUrl,
      'jobCategory': category,
      'tag': tag,
      'provider': category,
      'posted': '',
    };
  }

  void _removeItem(String id) {
    setState(() {
      _allFavorites.removeWhere((i) => i['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).t('removedFromFavorites'),
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleCart(String id) {
    setState(() {
      if (_cartIds.contains(id)) {
        _cartIds.remove(id);
      } else {
        _cartIds.add(id);
      }
    });
    final inCart = _cartIds.contains(id);
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          inCart ? l.t('addedToCart') : l.t('removedFromCart'),
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        backgroundColor: inCart ? AppTheme.primaryPinkDark : AppTheme.grayText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        action: inCart
            ? SnackBarAction(
                label: l.t('viewCart'),
                textColor: Colors.white,
                onPressed: () => context.push(AppRoutes.cartAndCheckoutScreen),
              )
            : null,
      ),
    );
  }

  void _showQuickView(Map<String, dynamic> item, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickViewSheet(
        item: item,
        type: type,
        inCart: _cartIds.contains(item['id']),
        onAddToCart: () {
          Navigator.pop(context);
          _toggleCart(item['id']);
        },
        onViewDetails: () {
          Navigator.pop(context);
          if (type == 'property') {
            context.push(AppRoutes.realEstateDetailsScreen, extra: _detailExtra(item));
          } else if (type == 'job') {
            context.push(AppRoutes.jobDetailsScreen, extra: _detailExtra(item));
          } else if (type == 'service') {
            final tag = '${item['tag'] ?? ''} ${item['category'] ?? ''} ${item['categorySlug'] ?? ''} ${item['listing_type'] ?? ''}'.toLowerCase();
            if (tag.contains('real-estate') || tag.contains('real estate') || tag.contains('property') || tag.contains('عقار')) {
              context.push(AppRoutes.realEstateDetailsScreen, extra: _detailExtra(item));
            } else if (tag.contains('beauty') ||
                tag.contains('hair') ||
                tag.contains('salon')) {
              context.push(AppRoutes.salonDetailsScreen, extra: _detailExtra(item));
            } else if (tag.contains('fitness') ||
                tag.contains('gym') ||
                tag.contains('sport')) {
              context.push(AppRoutes.gymSportsDetailsScreen, extra: _detailExtra(item));
            } else if (tag.contains('medical') ||
                tag.contains('dental') ||
                tag.contains('clinic')) {
              context.push(AppRoutes.clinicDetailsScreen, extra: _detailExtra(item));
            } else {
              context.push(AppRoutes.clinicDetailsScreen, extra: _detailExtra(item));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const AppNavigation(initialVisualIndex: 3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _allFavorites.isEmpty
                      ? _buildEmpty()
                      : _buildUnifiedList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    final l = AppLocalizations.of(context);
    final total = _allFavorites.length;
    final cartCount = ref.watch(cartCountProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.myFavorites,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l.t('savedItemsCount', args: {'count': '$total'}),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
          // Cart shortcut with live badge
          GestureDetector(
            onTap: () => context.push(AppRoutes.cartAndCheckoutScreen),
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 20,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryPinkDark,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: GoogleFonts.cairo(
                            fontSize: 7,
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
        ],
      ),
    );
  }


  // ── Loading ────────────────────────────────────────────────────
  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 110,
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────
  Widget _buildEmpty() {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 32,
              color: AppTheme.primaryPink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.t('noSavedServices'),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.t('browseServicesToSave'),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppTheme.grayText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Unified List ──────────────────────────────────────────────
  Widget _buildUnifiedList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _allFavorites.length,
      itemBuilder: (_, i) {
        final item = _allFavorites[i];
        final type = _tabTypeForItem(item);
        if (type == 'property') {
          return _PropertyCard(
            item: item,
            inCart: _cartIds.contains(item['id']),
            onRemove: () => _removeItem(item['id']),
            onCart: () => _toggleCart(item['id']),
            onQuickView: () => _showQuickView(item, 'property'),
          );
        } else if (type == 'job') {
          return _JobCard(
            item: item,
            onRemove: () => _removeItem(item['id']),
            onQuickView: () => _showQuickView(item, 'job'),
            onApply: () => context.push(AppRoutes.applyJobScreen),
          );
        } else {
          return _ServiceCard(
            item: item,
            inCart: _cartIds.contains(item['id']),
            onRemove: () => _removeItem(item['id']),
            onCart: () => _toggleCart(item['id']),
            onQuickView: () => _showQuickView(item, 'service'),
          );
        }
      },
    );
  }

  String _tabTypeForItem(Map<String, dynamic> item) {
    final t = (item['type'] as String? ?? '').toLowerCase();
    if (t.contains('property') || t.contains('real') || t.contains('estate')) return 'property';
    if (t.contains('job')) return 'job';
    return 'service';
  }
}

// ══════════════════════════════════════════════════════════════════
// SERVICE CARD
// ══════════════════════════════════════════════════════════════════
Map<String, dynamic> _detailExtra(Map<String, dynamic> item) {
  final price = (item['price'] as num?) ?? 0;
  final priceStr = price > 0
      ? 'AED ${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}'
      : 'Price on request';
  return {
    ...item,
    'price': priceStr,
    'originalPrice': priceStr,
    'salary': item['salary'],
  };
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool inCart;
  final VoidCallback onRemove;
  final VoidCallback onCart;
  final VoidCallback onQuickView;

  const _ServiceCard({
    required this.item,
    required this.inCart,
    required this.onRemove,
    required this.onCart,
    required this.onQuickView,
  });

  String _routeForTag() {
    final tag = '${item['tag'] ?? ''} ${item['category'] ?? ''} ${item['categorySlug'] ?? ''} ${item['listing_type'] ?? ''}'.toLowerCase();
    if (tag.contains('real-estate') || tag.contains('real estate') || tag.contains('property') || tag.contains('عقار')) {
      return AppRoutes.realEstateDetailsScreen;
    } else if (tag.contains('beauty') ||
        tag.contains('hair') ||
        tag.contains('salon')) {
      return AppRoutes.salonDetailsScreen;
    } else if (tag.contains('fitness') ||
        tag.contains('gym') ||
        tag.contains('sport')) {
      return AppRoutes.gymSportsDetailsScreen;
    } else if (tag.contains('medical') ||
        tag.contains('dental') ||
        tag.contains('clinic')) {
      return AppRoutes.clinicDetailsScreen;
    }
    return AppRoutes.clinicDetailsScreen;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(_routeForTag(), extra: _detailExtra(item)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CustomImageWidget(
                imageUrl: item['image'] as String,
                width: 100,
                height: 110,
                fit: BoxFit.cover,
                semanticLabel: l.serviceImageLabel(item['title'] as String),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPinkLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.localizeBadge(item['tag'] as String),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryPinkDark,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Remove
                        GestureDetector(
                          onTap: onRemove,
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['provider'] as String,
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
                          size: 13,
                          color: Color(0xFFFFB547),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${item['rating']}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${item['reviews']})',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppTheme.grayText,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'AED ${(item['price'] as double).toStringAsFixed(0)}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Quick View
                        Expanded(
                          child: GestureDetector(
                            onTap: onQuickView,
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Center(
                                  child: Text(
                                  l.t('quickView'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.charcoal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add to Cart
                        GestureDetector(
                          onTap: onCart,
                          child: Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: inCart
                                  ? null
                                  : AppTheme.primaryGradient,
                              color: inCart ? AppTheme.success : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              inCart
                                  ? Icons.check_rounded
                                  : Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
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
}

// ══════════════════════════════════════════════════════════════════
// PROPERTY CARD
// ══════════════════════════════════════════════════════════════════
class _PropertyCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool inCart;
  final VoidCallback onRemove;
  final VoidCallback onCart;
  final VoidCallback onQuickView;

  const _PropertyCard({
    required this.item,
    required this.inCart,
    required this.onRemove,
    required this.onCart,
    required this.onQuickView,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isForSale = (item['tag'] as String) == 'For Sale';
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.realEstateDetailsScreen, extra: _detailExtra(item)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CustomImageWidget(
                    imageUrl: item['image'] as String,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    semanticLabel: l.propertyExteriorLabel(item['title'] as String),
                  ),
                ),
                // Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isForSale ? AppTheme.goldAccent : AppTheme.info,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.localizeBadge(item['tag'] as String),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Remove
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: AppTheme.primaryPinkDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 13,
                        color: AppTheme.grayText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['provider'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppTheme.grayText,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.square_foot_outlined,
                        size: 13,
                        color: AppTheme.grayText,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item['area'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.grayText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'AED ${_formatPrice(item['price'] as double)}',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      if (!isForSale)
                        Text(
                          ' ${l.perYear}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.grayText,
                          ),
                        ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFFFB547),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${item['rating']}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onQuickView,
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Center(
                              child: Text(
                                l.t('quickView'),
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onCart,
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: inCart
                                  ? null
                                  : AppTheme.primaryGradient,
                              color: inCart ? AppTheme.success : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    inCart
                                        ? Icons.check_rounded
                                        : Icons.add_shopping_cart_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    inCart ? l.t('added') : l.addToCart,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}

// ══════════════════════════════════════════════════════════════════
// JOB CARD
// ══════════════════════════════════════════════════════════════════
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  final VoidCallback onQuickView;
  final VoidCallback onApply;

  const _JobCard({
    required this.item,
    required this.onRemove,
    required this.onQuickView,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.jobDetailsScreen, extra: _detailExtra(item)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Company logo placeholder
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.jobsBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Icon(
                      Icons.business_center_outlined,
                      size: 22,
                      color: AppTheme.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['company'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(
                      Icons.bookmark_rounded,
                      size: 22,
                      color: AppTheme.primaryPinkDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(
                    Icons.location_on_outlined,
                    item['location'] as String,
                    AppTheme.grayText,
                  ),
                  _chip(
                    Icons.attach_money_rounded,
                    l.localizePrice(item['salary'] as String),
                    AppTheme.success,
                  ),
                  _chip(
                    Icons.access_time_rounded,
                    item['type'] as String,
                    AppTheme.info,
                  ),
                  _chip(
                    Icons.schedule_outlined,
                    item['posted'] as String,
                    AppTheme.grayText,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onQuickView,
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Center(
                          child: Text(
                            l.t('quickView'),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onApply,
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            l.applyNow,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
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

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// QUICK VIEW BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════
class _QuickViewSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;
  final bool inCart;
  final VoidCallback onAddToCart;
  final VoidCallback onViewDetails;

  const _QuickViewSheet({
    required this.item,
    required this.type,
    required this.inCart,
    required this.onAddToCart,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: CustomImageWidget(
              imageUrl: item['image'] as String,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              semanticLabel:
                  l.serviceImageLabel(item['title'] ?? item['title'] ?? ''),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + tag
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (item['title'] ?? item['title'] ?? '') as String,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ),
                    if (item['tag'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPinkLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.localizeBadge(item['tag'] as String),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Provider / company
                Text(
                  (item['provider'] ?? item['company'] ?? '') as String,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.grayText,
                  ),
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  (item['description'] ?? '') as String,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.charcoal,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                // Price / salary row
                if (type != 'job')
                  Row(
                    children: [
                      Text(
                        'AED ${_formatPrice(item['price'] as double)}',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFB547),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['rating']}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money_rounded,
                        size: 16,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.localizePrice(item['salary'] as String),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppTheme.primaryPink,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(0, 46),
                        ),
                        child: Text(
                          l.t('viewDetails'),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: inCart
                              ? AppTheme.success
                              : AppTheme.primaryPinkDark,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          type == 'job'
                              ? l.t('applyNow')
                              : (inCart ? l.t('inCart') : l.addToCart),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
