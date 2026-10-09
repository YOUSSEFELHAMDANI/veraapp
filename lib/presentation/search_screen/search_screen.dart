import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../core/user_interest_tracker.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_back_button.dart';
import './widgets/ai_suggestions_widget.dart';
import './widgets/search_filter_sheet_widget.dart';
import './widgets/search_results_widget.dart';
import './widgets/smart_search_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _isSearching = false;
  bool _showAiSuggestions = false;
  String _selectedCategory = 'All';

  List<String> _recentSearches(AppLocalizations l10n) => const [];

  List<String> _trending(AppLocalizations l10n) => const [];

  static const List<String> _filterCategories = [
    'All',
    'Fashion',
    'Real Estate',
    'Clinics',
    'Salons',
    'Jobs',
    'Gym',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _query = value;
      _isSearching = value.isNotEmpty;
      _showAiSuggestions = value.length >= 3 && !_isSearching;
    });
  }

  void _onSearchSubmit(String value) {
    setState(() {
      _query = value;
      _isSearching = value.isNotEmpty;
      _showAiSuggestions = false;
    });
    UserInterestTracker.instance.recordSearch(value);
    _focusNode.unfocus();
  }

  void _applyQuery(String value) {
    _searchController.text = value;
    setState(() {
      _query = value;
      _isSearching = value.isNotEmpty;
      _showAiSuggestions = false;
    });
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _isSearching = false;
      _showAiSuggestions = false;
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchFilterSheetWidget(),
    );
  }

  void _openMapView() {
    final mode = _selectedCategory == 'Real Estate'
        ? 'real_estate'
        : 'services';
    context.push('${AppRoutes.mapViewScreen}?mode=$mode');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cartCount = ref.watch(cartCountProvider);

    String catLabel(String c) {
      switch (c) {
        case 'All':
          return l10n.allLabel;
        case 'Fashion':
          return l10n.fashion;
        case 'Real Estate':
          return l10n.realEstate;
        case 'Clinics':
          return l10n.clinics;
        case 'Salons':
          return l10n.salons;
        case 'Jobs':
          return l10n.jobs;
        case 'Gym':
          return l10n.gym;
        default:
          return c;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppBackButton(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.homeScreen),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          l10n.t('discover'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: AppTheme.titlePageSize,
                            fontWeight: AppTheme.titlePageWeight,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 6),
                      // Cart icon with badge
                      GestureDetector(
                        onTap: () =>
                            context.push(AppRoutes.cartAndCheckoutScreen),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPinkLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                size: AppTheme.iconMd,
                                color: AppTheme.primaryPinkDark,
                              ),
                            ),
                            if (cartCount > 0)
                              PositionedDirectional(
                                top: 2,
                                end: 2,
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
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _openFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPinkLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _openMapView,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPinkLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search input with AI icons
                  Container(
                    height: AppTheme.searchBarHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? AppTheme.primaryPink
                            : AppTheme.borderLight,
                        width: _focusNode.hasFocus ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppTheme.grayText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: _onSearch,
                            onSubmitted: _onSearchSubmit,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: AppTheme.charcoal,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.t('searchWithAiHint'),
                              hintStyle: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppTheme.grayText,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_isSearching)
                          GestureDetector(
                            onTap: _clearSearch,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppTheme.grayText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category filter chips
                  SizedBox(
                    height: AppTheme.chipHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterCategories.length,
                      itemBuilder: (context, i) {
                        final isActive =
                            _selectedCategory == _filterCategories[i];
                        return GestureDetector(
                          onTap: () => setState(
                            () => _selectedCategory = _filterCategories[i],
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primaryPink
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.primaryPink
                                    : AppTheme.borderLight,
                              ),
                            ),
                            child: Text(
                              catLabel(_filterCategories[i]),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? Colors.white
                                    : AppTheme.charcoal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: _isSearching
                  ? SearchResultsWidget(
                      query: _query,
                      category: _selectedCategory,
                      isTablet: isTablet,
                    )
                  : _buildDiscoveryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryContent() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
      children: [
        // AI suggestions when typing
        if (_showAiSuggestions && _query.length >= 3)
          AiSuggestionsWidget(query: _query, onSuggestionTap: _applyQuery),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI search hint card
              if (!_showAiSuggestions)
                SmartSearchCard(onQuery: _applyQuery),

              // Recent searches
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentSearches,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    l10n.t('clearAll'),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryPinkDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._recentSearches(l10n).map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _applyQuery(s),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: AppTheme.primaryPinkLight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: AppTheme.grayText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.north_west_rounded,
                            size: 16,
                            color: AppTheme.grayText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Trending
              Text(
                l10n.t('trendingNow'),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _trending(l10n).map((t) {
                  return GestureDetector(
                    onTap: () => _applyQuery(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPinkLight,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppTheme.primaryPink.withAlpha(77),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 14,
                            color: AppTheme.primaryPinkDark,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            t,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryPinkDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
