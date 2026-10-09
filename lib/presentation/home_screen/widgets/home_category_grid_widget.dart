import '../../../core/app_export.dart';
import '../../../core/app_localizations.dart';
import '../../../routes/app_routes.dart';

class _CategoryData {
  final String nameKey;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String route;

  const _CategoryData({
    required this.nameKey,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.route,
  });
}

class HomeCategoryGridWidget extends StatefulWidget {
  final bool isTablet;

  const HomeCategoryGridWidget({this.isTablet = false, super.key});

  @override
  State<HomeCategoryGridWidget> createState() => _HomeCategoryGridWidgetState();
}

class _HomeCategoryGridWidgetState extends State<HomeCategoryGridWidget> {
  static final List<_CategoryData> _categories = [
    _CategoryData(
      nameKey: 'fashion',
      icon: Icons.diamond_rounded,
      bgColor: AppTheme.tintPinkMist,
      iconColor: Color(0xFFEC4899),
      route: AppRoutes.fashionHubScreen,
    ),
    _CategoryData(
      nameKey: 'realEstate',
      icon: Icons.villa_rounded,
      bgColor: AppTheme.tintLemon,
      iconColor: Color(0xFFD97706),
      route: AppRoutes.realEstateScreen,
    ),
    _CategoryData(
      nameKey: 'clinics',
      icon: Icons.health_and_safety_rounded,
      bgColor: AppTheme.tintBlue,
      iconColor: Color(0xFF2563EB),
      route: AppRoutes.clinicsScreen,
    ),
    _CategoryData(
      nameKey: 'salons',
      icon: Icons.auto_awesome_rounded,
      bgColor: AppTheme.tintVioletMist,
      iconColor: Color(0xFF7C3AED),
      route: AppRoutes.salonsScreen,
    ),
    _CategoryData(
      nameKey: 'jobs',
      icon: Icons.badge_rounded,
      bgColor: AppTheme.tintGreenMist,
      iconColor: Color(0xFF059669),
      route: AppRoutes.jobsScreen,
    ),
    _CategoryData(
      nameKey: 'gym',
      icon: Icons.sports_gymnastics_rounded,
      bgColor: AppTheme.tintOrangeMist,
      iconColor: Color(0xFFEA580C),
      route: AppRoutes.gymSportsScreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crossAxisCount = widget.isTablet ? 4 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.categories,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.searchScreen),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: widget.isTablet ? 0.85 : 0.95,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, i) =>
                _CategoryIconButton(category: _categories[i]),
          ),
        ),
      ],
    );
  }
}

class _CategoryIconButton extends StatefulWidget {
  final _CategoryData category;
  const _CategoryIconButton({required this.category});

  @override
  State<_CategoryIconButton> createState() => _CategoryIconButtonState();
}

class _CategoryIconButtonState extends State<_CategoryIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      value: 1.0,
      lowerBound: 0.92,
      upperBound: 1.0,
    );
    _scaleAnim = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        context.push(widget.category.route);
      },
      onTapCancel: () => _scaleController.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.category.bgColor,
                    widget.category.bgColor.withAlpha(200),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.category.iconColor.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                widget.category.icon,
                size: 30,
                color: widget.category.iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t(widget.category.nameKey),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
