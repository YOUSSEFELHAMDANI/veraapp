import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/user_interest_tracker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../providers/cart_provider.dart';
import '../../services/vera_api_service.dart';
import '../../routes/app_routes.dart';

class FashionDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? productData;
  const FashionDetailsScreen({super.key, this.productData});

  @override
  ConsumerState<FashionDetailsScreen> createState() =>
      _FashionDetailsScreenState();
}

class _FashionDetailsScreenState extends ConsumerState<FashionDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isWishlisted = false;
  String _selectedSize = 'M';
  String _selectedColor = 'Black';
  int _quantity = 1;
  int _selectedImageIndex = 0;
  bool _descriptionExpanded = false;
  late PageController _pageController;
  Map<String, dynamic>? _serverData;

  List<String> get _galleryImages {
    final images = <String>[];
    final image = _product['image'];
    if (image is String && image.isNotEmpty) images.add(image);
    final imagesRaw = _product['images'];
    if (imagesRaw is List) {
      for (final e in imagesRaw) {
        if (e is String && e.isNotEmpty) images.add(e);
      }
    }
    final galleryRaw = _product['gallery'];
    if (galleryRaw is List) {
      for (final e in galleryRaw) {
        if (e is String && e.isNotEmpty) images.add(e);
      }
    }
    return images;
  }

  final List<Map<String, dynamic>> _features = [];

  final List<Map<String, dynamic>> _reviews = [];

  final List<Map<String, dynamic>> _ratingBreakdown = [];

  Map<String, dynamic> get _product {
    if (widget.productData != null) {
      final merged = Map<String, dynamic>.from(widget.productData!);
      if (_serverData != null) merged.addAll(_serverData!);
      return merged;
    }
    return _serverData ?? const {};
  }

  /// Parses a price value that may be an int (299) or a String ("AED 299" / "299").
  int _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    // Strip non-numeric characters (e.g. "AED ", "درهم") and parse
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  /// Returns a display string for a price value.
  String _priceLabel(dynamic value) {
    if (value == null) return '';
    if (value is int || value is double) return '${_parsePrice(value)} AED';
    final str = value.toString().trim();
    // Already contains AED or درهم — return as-is
    if (str.toUpperCase().contains('AED') || str.contains('درهم')) return str;
    return '$str AED';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    UserInterestTracker.instance.recordProductView(widget.productData ?? const {});
    final id = (widget.productData?['id'] as String?) ?? '';
    if (id.isNotEmpty) {
      _fetchDetails(id);
    }
  }

  Future<void> _fetchDetails(String id) async {
    final service = await VeraApiService.instance.fetchServiceById(id);
    if (mounted && service != null) {
      setState(() => _serverData = service.toDetailsMap());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onThumbnailTap(int index) {
    setState(() => _selectedImageIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildGallerySection()),
              SliverToBoxAdapter(child: _buildProductInfoSection()),
              SliverToBoxAdapter(child: _buildDescriptionSection()),
              SliverToBoxAdapter(child: _buildReviewsSection()),
              SliverToBoxAdapter(child: _buildShareSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  // ─── GALLERY ────────────────────────────────────────────────────────────────

  Widget _buildGallerySection() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 38.h,
      child: Stack(
        children: [
          // Main image pager
          PageView.builder(
            controller: _pageController,
            itemCount: _galleryImages.length,
            onPageChanged: (i) => setState(() => _selectedImageIndex = i),
            itemBuilder: (context, index) => CustomImageWidget(
              imageUrl: _galleryImages[index],
              width: double.infinity,
              height: 38.h,
              fit: BoxFit.cover,
              semanticLabel:
                  l10n.t('productImageCount', args: {'current': '${index + 1}', 'total': '${_galleryImages.length}'}),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(
                      Icons.arrow_back_ios_new_rounded,
                      () => context.pop(),
                    ),
                    Row(
                      children: [
                        _circleButton(Icons.share_outlined, _onShare),
                        const SizedBox(width: 8),
                        _circleButton(
                          _isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          () => setState(() => _isWishlisted = !_isWishlisted),
                          iconColor: _isWishlisted
                              ? AppTheme.primaryPinkDark
                              : AppTheme.charcoal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Discount badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryPinkDark,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                (_product['badge'] as String?) ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Image counter
          Positioned(
            bottom: 56,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '${_selectedImageIndex + 1}/${_galleryImages.length}',
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Thumbnails row
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 52,
              color: Colors.white.withAlpha(230),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _galleryImages.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedImageIndex == index;
                        return GestureDetector(
                          onTap: () => _onThumbnailTap(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryPinkDark
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: CustomImageWidget(
                                imageUrl: _galleryImages[index],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                semanticLabel: l10n.t('thumbnailNumber', args: {'number': '${index + 1}'}),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Video icon placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 22,
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

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppTheme.charcoal),
      ),
    );
  }

  // ─── PRODUCT INFO ────────────────────────────────────────────────────────────

  Widget _buildProductInfoSection() {
    final l10n = AppLocalizations.of(context);
    final price = _parsePrice(_product['price']);
    final originalPrice = _parsePrice(_product['originalPrice']);
    final savings = originalPrice - price;

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + brand badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  (_product['title'] as String?) ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tintLavender,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xFFD4B8FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      (_product['brand'] as String?) ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating + stock
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < ((_product['rating'] as num?)?.toDouble() ?? 0.0).floor()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16,
                  color: const Color(0xFFFFB547),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${_product['rating'] ?? 0} (${_product['reviews'] ?? 0} ${l10n.reviewsCount})',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.grayText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.tintGreen,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppTheme.success),
                    const SizedBox(width: 4),
                  Text(
                      l10n.inStock,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _priceLabel(_product['price']),
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _priceLabel(_product['originalPrice']),
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      color: AppTheme.grayText,
                      decoration: TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPinkDark,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    l10n.t('saveAmount', args: {'amount': _priceLabel(_parsePrice(_product['originalPrice']) - _parsePrice(_product['price']))}),
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Size selector
          _buildSizeSelector(),
          const SizedBox(height: 14),

          // Color selector
          _buildColorSelector(),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    final l10n = AppLocalizations.of(context);
    final sizes =
        ((_product['sizes'] as List<dynamic>?) ?? const [])
            .cast<String>();
    if (sizes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.t('sizeWithValue', args: {'size': _selectedSize}),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                l10n.t('sizeGuide'),
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: AppTheme.primaryPinkDark,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizes.map((s) {
            final isSelected = _selectedSize == s;
            return GestureDetector(
              onTap: () => setState(() => _selectedSize = s),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryPinkDark
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryPinkDark
                        : AppTheme.borderLight,
                  ),
                ),
                child: Center(
                  child: Text(
                    s,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.grayText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    final l10n = AppLocalizations.of(context);
    final colors =
        ((_product['colors'] as List<dynamic>?) ?? const [])
            .cast<String>();
    if (colors.isEmpty) return const SizedBox.shrink();
    final colorMap = {
      'Black': Colors.black87,
      'Beige': const Color(0xFFD4B896),
      'Brown': const Color(0xFF8B5E3C),
      'Navy': const Color(0xFF1B2A4A),
      'Burgundy': const Color(0xFF800020),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('colorWithValue', args: {'color': _selectedColor}),
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((c) {
            final isSelected = _selectedColor == c;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorMap[c] ?? Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryPinkDark
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryPinkDark.withAlpha(80),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c,
                    style: GoogleFonts.cairo(
                      fontSize: 9.sp,
                      color: isSelected
                          ? AppTheme.primaryPinkDark
                          : AppTheme.grayText,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── DESCRIPTION ─────────────────────────────────────────────────────────────

  Widget _buildDescriptionSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text(
                    l10n.description,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(
                    () => _descriptionExpanded = !_descriptionExpanded,
                  ),
                  child: Icon(
                    _descriptionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (_product['description'] as String?) ?? '',
              maxLines: _descriptionExpanded ? null : 3,
              overflow: _descriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppTheme.grayText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),

            // Features grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final f = _features[index];
                return Row(
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 16,
                      color: AppTheme.primaryPinkDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f['label'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: AppTheme.charcoal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── REVIEWS ─────────────────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                     '${l10n.reviewsCount} (${_product['reviews'] ?? 0})',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                   l10n.seeAll,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppTheme.primaryPinkDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Rating summary
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big rating number
                Column(
                  children: [
                    Text(
                      '${_product['rating'] ?? 0}',
                      style: GoogleFonts.cairo(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < 5
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 12,
                          color: const Color(0xFFFFB547),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(${_product['reviews'] ?? 0})',
                      style: GoogleFonts.cairo(
                        fontSize: 9.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Breakdown bars
                Expanded(
                  child: Column(
                    children: _ratingBreakdown.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              '${r['stars']}',
                              style: GoogleFonts.cairo(
                                fontSize: 10.sp,
                                color: AppTheme.grayText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star_rounded,
                              size: 10,
                              color: Color(0xFFFFB547),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: LinearProgressIndicator(
                                  value: r['percent'] as double,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.backgroundLight,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFB547),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 44,
                              child: Text(
                                r['label'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 9.sp,
                                  color: AppTheme.grayText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.borderLight),
            const SizedBox(height: 12),

            // Customer reviews
            ...(_reviews.map((review) => _buildReviewCard(review)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: CustomImageWidget(
                  imageUrl: review['image'] as String,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  semanticLabel: l10n.profilePhotoOf(review['name'] as String),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ),
                        if (review['verified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            l10n.t('verifiedPurchase'),
                            style: GoogleFonts.cairo(
                              fontSize: 9.sp,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          review['rating'] as int,
                          (i) => const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Color(0xFFFFB547),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          review['date'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 9.sp,
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  review['comment'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.grayText,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CustomImageWidget(
                  imageUrl: review['productImage'] as String,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  semanticLabel: l10n.t('productPhotoInReview'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SHARE ────────────────────────────────────────────────────────────────────

  Widget _buildShareSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('shareThisProduct'),
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _shareButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  bgColor: const Color(0xFFE8FFF1),
                ),
                const SizedBox(width: 10),
                _shareButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  bgColor: AppTheme.tintBlush,
                ),
                const SizedBox(width: 10),
                _shareButton(
                  icon: Icons.help_outline,
                  label: 'Snapchat',
                  color: const Color(0xFFFFFC00),
                  bgColor: AppTheme.tintLemonWarm,
                  textColor: const Color(0xFF333333),
                ),
                const SizedBox(width: 10),
                _shareButton(
                  icon: Icons.more_horiz_rounded,
                  label: l10n.t('more'),
                  color: AppTheme.grayText,
                  bgColor: AppTheme.backgroundLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    Color? textColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _onShare,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 9.sp,
                color: textColor ?? color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onShare() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.t('shareLinkCopied'),
          style: GoogleFonts.cairo(fontSize: 12.sp),
        ),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 10, 4.w, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wishlist
          GestureDetector(
            onTap: () => setState(() => _isWishlisted = !_isWishlisted),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isWishlisted
                    ? AppTheme.primaryPinkLight
                    : AppTheme.ivoryLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                _isWishlisted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: _isWishlisted
                    ? AppTheme.primaryPinkDark
                    : AppTheme.grayText,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryPinkLight,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_quantity > 1) setState(() => _quantity--);
                  },
                  icon: const Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: AppTheme.primaryPinkDark,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$_quantity',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppTheme.primaryPinkDark,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Add to Cart
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final p = _product;
                final price = _parsePrice(p['price']);
                ref
                    .read(cartProvider.notifier)
                    .addItem(
                      CartItem(
                        id: p['id']?.toString() ?? 'fashion_${p['title']?.toString().replaceAll(' ', '_') ?? DateTime.now().millisecondsSinceEpoch.toString()}',
                        name: p['title']?.toString() ?? l10n.t('fashionItem'),
                        provider: p['brand']?.toString() ?? 'VÉRA Fashion',
                        price: price.toDouble(),
                        quantity: _quantity,
                        imageUrl: _galleryImages.isNotEmpty
                            ? _galleryImages[0]
                            : '',
                        semanticLabel:
                            l10n.productPhotoLabel(p['title']?.toString() ?? l10n.t('fashionItem')),
                        category: 'Fashion',
                        weightKg: double.tryParse(p['shipping_weight_kg']?.toString() ?? p['weight']?.toString() ?? ''),
                        lengthCm: double.tryParse(p['package_length_cm']?.toString() ?? p['length']?.toString() ?? ''),
                        widthCm: double.tryParse(p['package_width_cm']?.toString() ?? p['width']?.toString() ?? ''),
                        heightCm: double.tryParse(p['package_height_cm']?.toString() ?? p['height']?.toString() ?? ''),
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('addedToCart'),
                            style: GoogleFonts.cairo(fontSize: 12.sp),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            context.push(AppRoutes.cartAndCheckoutScreen);
                          },
                          child: Text(
                            l10n.t('viewCart'),
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(
                l10n.addToCart,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPinkDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                minimumSize: Size.zero,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
