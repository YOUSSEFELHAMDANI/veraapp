import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_session.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_menu_section_widget.dart';
import './widgets/profile_stats_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // TODO: Replace with Riverpod/Bloc for production
  final bool _notificationsEnabled = true;
  int _ordersCount = 0;
  int _bookingsCount = 0;
  double _walletBalance = 0;
  int _loyaltyPoints = 0;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (await VeraApiService.instance.ensureAuthenticated()) {
      if (mounted) _loadProfileData();
      return;
    }
    if (mounted) context.go(AppRoutes.loginScreen);
  }

  Future<void> _loadProfileData() async {
    final results = await Future.wait([
      VeraApiService.instance.fetchProfile(),
      VeraApiService.instance.fetchOrders(),
      VeraApiService.instance.fetchMyBookings(),
      VeraApiService.instance.fetchLoyalty(),
      VeraApiService.instance.fetchWallet(),
    ]);
    if (!mounted) return;
    final user = results[0] as VeraUser?;
    final orders = results[1] as List<VeraOrder>;
    final bookings = results[2] as List<VeraBooking>;
    final loyalty = results[3] as VeraLoyalty?;
    final wallet = results[4] as VeraWallet?;
    if (user != null) {
      ref.read(currentUserProvider.notifier).setUser(user);
    }
      setState(() {
        if (orders.isNotEmpty) {
          _ordersCount = orders
              .where((o) => !o.status.toLowerCase().contains('cancel'))
              .length;
        } else if (user != null && user.ordersCount > 0) {
          _ordersCount = user.ordersCount;
        }
        if (bookings.isNotEmpty) {
          _bookingsCount = bookings
              .where((b) => !b.status.toLowerCase().contains('cancel'))
              .length;
        } else if (user != null && user.bookingsCount > 0) {
          _bookingsCount = user.bookingsCount;
        }
      if (wallet != null) {
        _walletBalance = wallet.balance;
      } else if (user != null) {
        _walletBalance = user.walletBalance;
      }
      if (user != null) {
        _loyaltyPoints = user.loyaltyPoints;
      }
      if (loyalty != null && loyalty.points > 0) {
        _loyaltyPoints = loyalty.points;
      }
    });
  }

  String _formatAmount(double v) {
    return v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildAppBar()),
        SliverToBoxAdapter(child: const ProfileHeaderWidget()),
        SliverToBoxAdapter(child: const ProfileStatsWidget()),
        SliverToBoxAdapter(child: _buildMenuSections()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: profile card
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _buildAppBar(),
              const ProfileHeaderWidget(),
              const ProfileStatsWidget(),
            ],
          ),
        ),
        Container(width: 1, color: AppTheme.borderLight),
        // Right: menu
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            child: _buildMenuSections(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(cartCountProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              l10n.myProfile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: AppTheme.titlePageSize,
                fontWeight: AppTheme.titlePageWeight,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          Row(
            children: [
              // Cart icon with badge
              GestureDetector(
                onTap: () => context.push(AppRoutes.cartAndCheckoutScreen),
                child: Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: AppTheme.iconMd,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    if (cartCount > 0)
                      PositionedDirectional(
                        top: 4,
                        end: 4,
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
              const SizedBox(width: 8),
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    end: 8,
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(AppRoutes.settingsScreen),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Orders & Bookings
        ProfileMenuSectionWidget(
          title: l10n.myActivity,
          items: [
            ProfileMenuItem(
              icon: Icons.shopping_bag_outlined,
              label: l10n.myOrders,
              badge: '$_ordersCount',
              onTap: () => context.push(AppRoutes.myOrdersScreen),
            ),
            ProfileMenuItem(
              icon: Icons.calendar_month_outlined,
              label: l10n.myAppointments,
              badge: '$_bookingsCount',
              onTap: () => context.push(AppRoutes.myAppointmentsScreen),
            ),
            ProfileMenuItem(
              icon: Icons.calendar_today_outlined,
              label: l10n.myBookings,
              badge: '$_bookingsCount',
              onTap: () => context.push(AppRoutes.myBookingsScreen),
            ),
            ProfileMenuItem(
              icon: Icons.bookmark_border_rounded,
              label: l10n.myFavorites,
              onTap: () => context.push(AppRoutes.favoritesScreen),
            ),
          ],
        ),

        // Finance
        ProfileMenuSectionWidget(
          title: l10n.finance,
          items: [
            ProfileMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.walletBnpl,
              trailing: l10n.currencyAed(_formatAmount(_walletBalance)),
              onTap: () => context.push(AppRoutes.walletScreen),
            ),
            ProfileMenuItem(
              icon: Icons.credit_card_rounded,
              label: l10n.paymentMethods,
              onTap: () => context.push(AppRoutes.paymentMethodsScreen),
            ),
            // Loyalty points hidden temporarily
            // ProfileMenuItem(
            //   icon: Icons.workspace_premium_rounded,
            //   label: l10n.loyaltyPoints,
            //   trailing: '$_loyaltyPoints ${l10n.pointsAbbr}',
            //   trailingColor: AppTheme.goldAccent,
            //   onTap: () => context.push(AppRoutes.loyaltyScreen),
            // ),
          ],
        ),

        // Account
        ProfileMenuSectionWidget(
          title: l10n.account,
          items: [
            ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: l10n.notifications,
              trailing: _notificationsEnabled ? l10n.onLabel : l10n.offLabel,
              trailingColor: _notificationsEnabled
                  ? AppTheme.success
                  : AppTheme.grayText,
              onTap: () => context.push(AppRoutes.notificationsScreen),
            ),
            ProfileMenuItem(
              icon: Icons.language_rounded,
              label: l10n.language,
              trailing: l10n.english,
              onTap: () => context.push(AppRoutes.settingsScreen),
            ),
            ProfileMenuItem(
              icon: Icons.privacy_tip_outlined,
              label: l10n.privacySettings,
              onTap: () => context.push(AppRoutes.settingsScreen),
            ),
          ],
        ),

        // Support
        ProfileMenuSectionWidget(
          title: l10n.helpSupport,
          items: [
            ProfileMenuItem(
              icon: Icons.support_agent_rounded,
              label: l10n.customerSupport,
              onTap: () => context.push(AppRoutes.aiAssistantScreen),
            ),
            ProfileMenuItem(
              icon: Icons.info_outline_rounded,
              label: l10n.aboutUs,
              trailing: 'v2.4.1',
              onTap: () => context.push(AppRoutes.settingsScreen),
            ),
          ],
        ),

        // Logout
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: GestureDetector(
            onTap: () => _showLogoutDialog(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.error.withAlpha(51)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    l10n.signOut,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 30,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.signOut,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signOutConfirm,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppTheme.grayText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.charcoal,
                        side: BorderSide(color: AppTheme.borderMedium),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await AuthSession.instance.clearSession(
                          clearBuyer: true,
                          clearProvider: true,
                        );
                        if (mounted) context.go(AppRoutes.loginScreen);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.signOut,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
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
}
