import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_localizations.dart';
import '../../../theme/app_theme.dart';

class SearchFilterSheetWidget extends StatefulWidget {
  const SearchFilterSheetWidget({super.key});

  @override
  State<SearchFilterSheetWidget> createState() =>
      _SearchFilterSheetWidgetState();
}

class _SearchFilterSheetWidgetState extends State<SearchFilterSheetWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  RangeValues _priceRange = const RangeValues(0, 2000);
  double _minRating = 4.0;
  String _selectedSort = 'Relevance';
  final List<String> _selectedCategories = ['Fashion'];

  static const List<String> _sortOptions = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Highest Rated',
    'Newest',
  ];

  static const List<String> _categories = [
    'Fashion',
    'Real Estate',
    'Clinics',
    'Salons',
    'Jobs',
    'Gym',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String catLabel(String c) {
      switch (c) {
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

    String sortLabel(String s) {
      switch (s) {
        case 'Relevance':
          return l10n.t('relevance');
        case 'Price: Low to High':
          return l10n.t('priceLowToHigh');
        case 'Price: High to Low':
          return l10n.t('priceHighToLow');
        case 'Highest Rated':
          return l10n.t('topRatedSort');
        case 'Newest':
          return l10n.t('newestSort');
        default:
          return s;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderMedium,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filter,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.t('reset'),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppTheme.primaryPinkDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category filter
                  Text(
                    l10n.t('categoryLabel'),
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
                    children: _categories.map((c) {
                      final isSelected = _selectedCategories.contains(c);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(c);
                          } else {
                            _selectedCategories.add(c);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryPink
                                : AppTheme.ivoryLight,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryPink
                                  : AppTheme.borderLight,
                            ),
                          ),
                          child: Text(
                            catLabel(c),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.charcoal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Price range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('priceRange'),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      Text(
                        '${_priceRange.start.toInt()} – ${_priceRange.end.toInt()} AED',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppTheme.primaryPinkDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryPink,
                      inactiveTrackColor: AppTheme.borderLight,
                      thumbColor: AppTheme.primaryPink,
                      overlayColor: AppTheme.primaryPink.withAlpha(26),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 5000,
                      divisions: 50,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Minimum rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('minimumRating'),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFFFC107),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _minRating.toStringAsFixed(1),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryPink,
                      inactiveTrackColor: AppTheme.borderLight,
                      thumbColor: AppTheme.primaryPink,
                    ),
                    child: Slider(
                      value: _minRating,
                      min: 1,
                      max: 5,
                      divisions: 8,
                      onChanged: (v) => setState(() => _minRating = v),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sort by
                  Text(
                    l10n.t('sortBy'),
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._sortOptions.map((s) {
                    final isSelected = _selectedSort == s;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSort = s),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryPinkLight
                              : AppTheme.ivoryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryPink
                                : AppTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sortLabel(s),
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppTheme.primaryPinkDark
                                      : AppTheme.charcoal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppTheme.primaryPinkDark,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.t('applyFilters'),
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
