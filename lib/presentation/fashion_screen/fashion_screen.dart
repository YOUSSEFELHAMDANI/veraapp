import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../services/vera_api_service.dart';

class FashionScreen extends StatefulWidget {
  const FashionScreen({super.key});

  @override
  State<FashionScreen> createState() => _FashionScreenState();
}

class _FashionScreenState extends State<FashionScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'Popular';
  bool _isGridView = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<bool> _favorites = [];
  List<String> _categories = [
    'All',
    'Abayas',
    'Dresses',
    'Bags',
    'Shoes',
    'Accessories',
    'Perfumes',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  Map<String, dynamic> _productToMap(VeraProduct p) {
    return {
      'id': p.id,
      'name': p.name,
      'brand': p.brand,
      'price': p.price,
      'originalPrice': p.originalPrice,
      'rating': p.rating,
      'reviews': p.reviews,
      'image': p.imageUrl,
      'badge': p.badge,
      'badgeColor': p.badgeColor,
      'isFavorite': p.isFavorite,
      'colors': p.colors,
    };
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final apiProducts = await VeraApiService.instance.fetchProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        sortBy: _sortBy == 'Popular' ? null : _sortBy.toLowerCase(),
      );
      if (!mounted) return;
      setState(() {
        _products = apiProducts.map(_productToMap).toList();
        _favorites = _products
            .map((p) => p['isFavorite'] as bool? ?? false)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _products = [];
        _favorites = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final apiCats = await VeraApiService.instance.fetchProductCategories();
      if (mounted && apiCats.isNotEmpty) {
        setState(() {
          _categories = ['All', ...apiCats.map((c) => c.name)];
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryChips(),
            _buildSortBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingGrid()
                  : _products.isEmpty
                  ? _buildEmptyState()
                  : (_isGridView ? _buildGrid() : _buildList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
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
                  l10n.fashion,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l10n.t('discoverLatestTrends'),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.fashionBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 20,
                color: AppTheme.fashion,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: AppTheme.charcoal,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final isActive = _selectedCategory == _categories[i];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = _categories[i]);
              _loadProducts();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.fashion : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppTheme.fashion : AppTheme.borderLight,
                ),
              ),
              child: Text(
                _categories[i],
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : AppTheme.charcoal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar() {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              _isLoading ? l.loading : l.t('itemsCount', args: {'count': '${_products.length}'}),
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showSortSheet(),
            child: Row(
              children: [
                const Icon(
                  Icons.sort_rounded,
                  size: 16,
                  color: AppTheme.primaryPinkDark,
                ),
                const SizedBox(width: 4),
                Text(
                  _sortBy,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryPinkDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppTheme.grayText,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).t('noProductsAvailable'),
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.grayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, i) => _buildProductCard(i),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: _products.length,
      itemBuilder: (context, i) => _buildProductListCard(i),
    );
  }

  Widget _buildProductCard(int index) {
    if (index >= _products.length) return const SizedBox.shrink();
    final p = _products[index];
    final isFav = index < _favorites.length ? _favorites[index] : false;
    final hasDiscount = (p['originalPrice'] as num) != (p['price'] as num);
    final badge = p['badge'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showProductDetails(p, index),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CustomImageWidget(
                      imageUrl: p['image'] as String? ?? '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      semanticLabel: '${p['name']} fashion product image',
                    ),
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Color(p['badgeColor'] as int? ?? 0xFFEFA9B8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (index < _favorites.length) {
                          setState(() => _favorites[index] = !isFav);
                        }
                        VeraApiService.instance.addToWishlist(
                          p['id'] as String? ?? '',
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: isFav ? AppTheme.error : AppTheme.grayText,
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
                    p['name'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p['brand'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.grayText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${p['price']} AED',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${p['originalPrice']}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppTheme.grayText,
                              decoration: TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildProductListCard(int index) {
    if (index >= _products.length) return const SizedBox.shrink();
    final p = _products[index];
    final isFav = index < _favorites.length ? _favorites[index] : false;
    final hasDiscount = (p['originalPrice'] as num) != (p['price'] as num);

    return GestureDetector(
      onTap: () => _showProductDetails(p, index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImageWidget(
                imageUrl: p['image'] as String? ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                semanticLabel: '${p['name']} product thumbnail',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['brand'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.grayText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${p['rating']} (${p['reviews']})',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
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
                      Flexible(
                        child: Text(
                          '${p['price']} AED',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${p['originalPrice']}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppTheme.grayText,
                              decoration: TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (index < _favorites.length) {
                            setState(() => _favorites[index] = !isFav);
                          }
                          VeraApiService.instance.addToWishlist(
                            p['id'] as String? ?? '',
                          );
                        },
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: isFav ? AppTheme.error : AppTheme.grayText,
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

  void _showSortSheet() {
    final l10n = AppLocalizations.of(context);
    final options = [
      'Popular',
      'Price: Low to High',
      'Price: High to Low',
      'Newest',
      'Top Rated',
    ];
    String sortLabel(String raw) {
      return switch (raw) {
        'Popular' => l10n.t('popular'),
        'Price: Low to High' => l10n.t('priceLowToHigh'),
        'Price: High to Low' => l10n.t('priceHighToLow'),
        'Newest' => l10n.t('newest'),
        'Top Rated' => l10n.topRated,
        _ => raw,
      };
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('sortBy'),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map(
              (opt) => GestureDetector(
                onTap: () {
                  setState(() => _sortBy = opt);
                  Navigator.pop(context);
                  _loadProducts();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          sortLabel(opt),
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: _sortBy == opt
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _sortBy == opt
                                ? AppTheme.primaryPinkDark
                                : AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      if (_sortBy == opt)
                        const Icon(
                          Icons.check_rounded,
                          color: AppTheme.primaryPinkDark,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> p, int index) {
    final colors = (p['colors'] as List?)?.cast<String>() ?? <String>[];
    String selectedColor = colors.isNotEmpty ? colors.first : '';
    int quantity = 1;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: CustomImageWidget(
                          imageUrl: p['image'] as String? ?? '',
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          semanticLabel: '${p['name']} product detail image',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p['name'] as String? ?? '',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.charcoal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${p['price']} AED',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryPinkDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p['brand'] as String? ?? '',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppTheme.grayText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${p['rating']} (${p['reviews']} reviews)',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: AppTheme.grayText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (colors.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(
                                'Color',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: colors
                                    .map(
                                      (c) => GestureDetector(
                                        onTap: () => setModalState(
                                          () => selectedColor = c,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selectedColor == c
                                                ? AppTheme.fashion
                                                : AppTheme.surfaceLight,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: selectedColor == c
                                                  ? AppTheme.fashion
                                                  : AppTheme.borderLight,
                                            ),
                                          ),
                                          child: Text(
                                            c,
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: selectedColor == c
                                                  ? Colors.white
                                                  : AppTheme.charcoal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Text(
                                  'Quantity',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.charcoal,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity > 1) {
                                          setModalState(() => quantity--);
                                        }
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppTheme.ivoryLight,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.borderLight,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove_rounded,
                                          size: 18,
                                          color: AppTheme.charcoal,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.charcoal,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          setModalState(() => quantity++),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      VeraApiService.instance.addToCart(
                                        itemId: p['id'] as String? ?? '',
                                        itemType: 'product',
                                        quantity: quantity,
                                      );
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Added to cart',
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: AppTheme.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.fashionBg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppTheme.fashion,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.addToCart,
                                          style: GoogleFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.fashion,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(ctx),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.buyNow,
                                          style: GoogleFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
