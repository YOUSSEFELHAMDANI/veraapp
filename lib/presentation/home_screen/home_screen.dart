import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../widgets/custom_image_widget.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import './widgets/home_banner_widget.dart';
import './widgets/home_search_bar_widget.dart';
import './widgets/home_category_grid_widget.dart';
import './widgets/home_featured_services_widget.dart';
import './widgets/home_top_providers_widget.dart';
import './widgets/home_promo_sliders_widget.dart';
import './widgets/home_category_banner_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _userName = '';
  String _avatarUrl = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnreadCount();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await VeraApiService.instance.fetchProfile();
      if (mounted && user != null) {
        ref.read(currentUserProvider.notifier).setUser(user);
        setState(() {
          _userName = user.name;
          _avatarUrl = user.avatarUrl;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await VeraApiService.instance.fetchUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // AppBar — V4 Gradient LOCKED
            SliverToBoxAdapter(child: _buildAppBar(context)),

            // Search bar — fixed below appbar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: HomeSearchBarWidget(
                  onTap: () => context.go(AppRoutes.searchScreen),
                ),
              ),
            ),

            // AI Assistant card
            SliverToBoxAdapter(child: _buildAiAssistantCard(context)),

            // Promo banner carousel
            const SliverToBoxAdapter(child: HomeBannerWidget()),

            // Filter chips + categories
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeCategoryGridWidget(isTablet: isTablet),
                  const HomeCategoryBannerWidget(),
                ],
              ),
            ),

            // Featured services
            const SliverToBoxAdapter(child: HomeFeaturedServicesWidget()),

            // Best Sellers slider
            const SliverToBoxAdapter(child: HomeBestSellersWidget()),

            // Most Viewed slider
            const SliverToBoxAdapter(child: HomeMostViewedWidget()),

            // Our Recommendations slider
            const SliverToBoxAdapter(child: HomeRecommendationsWidget()),

            // Top providers
            const SliverToBoxAdapter(child: HomeTopProvidersWidget()),

            // Bottom padding for floating nav
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    // V4 Gradient AppBar — LOCKED
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(cartCountProvider);
    final currentUser = ref.watch(currentUserProvider);
    final avatarUrl = currentUser?.avatarUrl.isNotEmpty == true
        ? currentUser!.avatarUrl
        : _avatarUrl;
    final userName = currentUser?.name.isNotEmpty == true
        ? currentUser!.name
        : _userName;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
      child: Row(
        children: [
          // Avatar + greeting
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? CustomImageWidget(
                      imageUrl: avatarUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      semanticLabel: l10n.profilePhotoOf(userName),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: Colors.white.withAlpha(204),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 24,
                        color: AppTheme.primaryPinkDark,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeBack,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.charcoal.withAlpha(179),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  userName.isNotEmpty ? userName : l10n.toVera,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
              ],
            ),
          ),
          // Cart icon with badge
          GestureDetector(
            onTap: () => context.push(AppRoutes.cartAndCheckoutScreen),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 22,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (cartCount > 0)
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryPinkDark,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: GoogleFonts.cairo(
                            fontSize: 9,
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
          const SizedBox(width: 8),
          // Notification bell
          GestureDetector(
            onTap: () async {
              await context.push(AppRoutes.notificationsScreen);
              _loadUnreadCount();
            },
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (_unreadCount > 0)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
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

  Widget _buildAiAssistantCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push(AppRoutes.aiAssistantScreen),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.aiGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(204),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryPinkDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiAssistantTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    l10n.aiAssistantSubtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.charcoal.withAlpha(166),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryPinkLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.mic_rounded,
                size: 16,
                color: AppTheme.primaryPinkDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryPinkLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 16,
                color: AppTheme.primaryPinkDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
