import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with ProviderGuard {
  VeraDashboardStats? _stats;
  List<VeraOrder> _recentOrders = [];
  Map<String, dynamic>? _earnings;
  VeraAccountManager? _accountManager;
  VeraUser? _profile;
  bool _amLoading = true;
  bool _isLoading = true;
  int _selectedTab = 0; // 0=all, 1=pending, 2=completed

  @override
  void initState() {
    super.initState();
    if (!guardProviderSession()) return;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        VeraApiService.instance.fetchProviderDashboard(),
        VeraApiService.instance.fetchProviderOrders(),
        VeraApiService.instance.fetchProviderEarnings(),
        VeraApiService.instance.fetchProviderAccountManager(),
        VeraApiService.instance.fetchProviderProfile(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as VeraDashboardStats?;
          _recentOrders = (results[1] as List<VeraOrder>).take(10).toList();
          _earnings = results[2] as Map<String, dynamic>?;
          _accountManager = results[3] as VeraAccountManager?;
          _profile = results[4] as VeraUser?;
          _amLoading = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<VeraOrder> get _filteredOrders {
    if (_selectedTab == 0) return _recentOrders;
    if (_selectedTab == 1) {
      return _recentOrders
          .where((o) => o.status == 'pending' || o.status == 'processing')
          .toList();
    }
    return _recentOrders
        .where((o) => o.status == 'completed' || o.status == 'delivered')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.goldAccent,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(l10n)),
              SliverToBoxAdapter(child: _buildStatsGrid(l10n)),
              SliverToBoxAdapter(child: _buildEarningsCard(l10n)),
              SliverToBoxAdapter(child: _buildAccountManagerCard(l10n)),
              SliverToBoxAdapter(child: _buildQuickActions(l10n)),
              SliverToBoxAdapter(child: _buildOrdersSection(l10n)),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final avatarUrl = _profile?.avatarUrl.isNotEmpty == true
        ? VeraApiService.resolveAssetUrl(_profile!.avatarUrl)
        : null;
    final name = _profile?.name.isNotEmpty == true ? _profile!.name : '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.tintCream, AppTheme.tintOrangeLight],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC8A96A), Color(0xFFEFA9B8)],
              ),
              borderRadius: BorderRadius.circular(14.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.providerDashboard,
                  style: GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l10n.t('manageYourBusiness'),
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _headerIconBtn(
                Icons.notifications_outlined,
                () => context.push(AppRoutes.notificationsScreen),
              ),
              SizedBox(width: 2.w),
              _headerIconBtn(
                Icons.person_outline_rounded,
                () => context.push(AppRoutes.providerProfileScreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Icon(icon, size: 20, color: AppTheme.charcoal),
      ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.all(4.w),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.goldAccent),
        ),
      );
    }
    final stats = [
      _StatItem(
        label: l10n.t('totalOrders'),
        value: '${_stats?.totalOrders ?? 0}',
        icon: Icons.shopping_bag_outlined,
        color: AppTheme.primaryPink,
        bgColor: AppTheme.fashionBg,
      ),
      _StatItem(
        label: l10n.bookings,
        value: '${_stats?.totalBookings ?? 0}',
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFF8FD9F7),
        bgColor: const Color(0xFFE0F5FD),
      ),
      _StatItem(
        label: l10n.t('revenue'),
        value: 'AED ${(_stats?.totalRevenue ?? 0).toStringAsFixed(0)}',
        icon: Icons.trending_up_rounded,
        color: AppTheme.goldAccent,
        bgColor: AppTheme.goldLight,
      ),
      _StatItem(
        label: l10n.t('wallet'),
        value: 'AED ${(_stats?.walletBalance ?? 0).toStringAsFixed(0)}',
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.success,
        bgColor: AppTheme.tintGreen,
      ),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.6,
        children: stats.map((s) => _buildStatCard(s)).toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: stat.bgColor,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                stat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(AppLocalizations l10n) {
    final totalEarnings =
        (_earnings?['data']?['total'] ??
                _earnings?['total'] ??
                _stats?.totalRevenue ??
                0.0)
            .toDouble();
    final pendingPayout =
        (_earnings?['data']?['pending'] ?? _earnings?['pending'] ?? 0.0)
            .toDouble();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC8A96A), Color(0xFFEFA9B8)],
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('totalEarnings'),
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'AED ${totalEarnings.toStringAsFixed(2)}',
                    style: GoogleFonts.cairo(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    l10n.t(
                      'pendingAed',
                      args: {'amount': pendingPayout.toStringAsFixed(2)},
                    ),
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.providerSubscriptionsScreen),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.white.withAlpha(80)),
                ),
                child: Text(
                  l10n.t('getBanners'),
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountManagerCard(AppLocalizations l10n) {
    final am = _accountManager;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Container(
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: _amLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                ),
              )
            : am == null
            ? _buildNoAccountManager(l10n)
            : _buildAccountManagerBody(l10n, am),
      ),
    );
  }

  Widget _buildNoAccountManager(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: AppTheme.ivoryLight,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(
            Icons.support_agent_outlined,
            color: AppTheme.grayText,
            size: 22,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            l10n.accountManagerNotAssigned,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.grayText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountManagerBody(
    AppLocalizations l10n,
    VeraAccountManager am,
  ) {
    final avatarUrl = am.avatarUrl.isEmpty
        ? null
        : VeraApiService.resolveAssetUrl(am.avatarUrl);
    final initials = am.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.substring(0, 1).toUpperCase())
        .join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 11.w,
              height: 11.w,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC8A96A), Color(0xFFEFA9B8)],
                ),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarInitials(initials),
                    )
                  : _avatarInitials(initials),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountManager,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grayText,
                    ),
                  ),
                  Text(
                    am.name,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Text(
          l10n.accountManagerSubtitle,
          style: GoogleFonts.cairo(fontSize: 10.5.sp, color: AppTheme.grayText),
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            Expanded(
              child: _amActionButton(
                icon: Icons.call_outlined,
                label: l10n.call,
                onTap: () => _launchUrl('tel:${am.phone}'),
                enabled: am.phone.isNotEmpty,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _amActionButton(
                icon: Icons.chat_outlined,
                label: l10n.whatsApp,
                onTap: () => _launchUrl(
                  'https://wa.me/${am.phone.replaceAll(RegExp(r'[^\d]'), '')}',
                ),
                enabled: am.phone.isNotEmpty,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _amActionButton(
                icon: Icons.email_outlined,
                label: l10n.email,
                onTap: () => _launchUrl('mailto:${am.email}'),
                enabled: am.email.isNotEmpty,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _amActionButton(
                icon: Icons.forum_outlined,
                label: 'رسالة',
                onTap: () =>
                    context.push(AppRoutes.providerAccountManagerChatScreen),
                enabled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatarInitials(String initials) {
    return Center(
      child: Text(
        initials.isEmpty ? 'AM' : initials,
        style: GoogleFonts.cairo(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _amActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final color = enabled ? AppTheme.goldAccent : AppTheme.grayLight;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.ivoryLight,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(height: 0.3.h),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w600,
                color: enabled ? AppTheme.charcoal : AppTheme.grayLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    final actions = [
      _QuickAction(
        label: l10n.t('addProduct'),
        icon: Icons.shopping_bag_outlined,
        route: AppRoutes.providerProductWizardScreen,
      ),
      _QuickAction(
        label: l10n.addService,
        icon: Icons.design_services_outlined,
        route: AppRoutes.providerServiceWizardScreen,
      ),
      _QuickAction(
        label: l10n.t('importExcelCsv'),
        icon: Icons.upload_file_outlined,
        route: AppRoutes.providerImportScreen,
      ),
      _QuickAction(
        label: l10n.t('myCatalog'),
        icon: Icons.inventory_2_outlined,
        route: AppRoutes.providerCatalogScreen,
      ),
      _QuickAction(
        label: l10n.t('myServices'),
        icon: Icons.miscellaneous_services_outlined,
        route: AppRoutes.providerServicesScreen,
      ),
      _QuickAction(
        label: l10n.orders,
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.providerOrdersScreen,
      ),
      _QuickAction(
        label: l10n.profile,
        icon: Icons.person_outline_rounded,
        route: AppRoutes.providerProfileScreen,
      ),
      _QuickAction(
        label: l10n.t('adPlans'),
        icon: Icons.campaign_outlined,
        route: AppRoutes.providerSubscriptionsScreen,
      ),
      _QuickAction(
        label: l10n.t('myPlan'),
        icon: Icons.layers_outlined,
        route: AppRoutes.providerPlansScreen,
      ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('quickActions'),
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          SizedBox(height: 1.5.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map(
                  (a) => SizedBox(
                    width:
                        (MediaQuery.of(context).size.width - 8.w * 2 - 8 * 3) /
                        4,
                    child: GestureDetector(
                      onTap: () => context.push(a.route),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            Icon(a.icon, color: AppTheme.goldAccent, size: 22),
                            SizedBox(height: 0.5.h),
                            Text(
                              a.label,
                              style: GoogleFonts.cairo(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.charcoal,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection(AppLocalizations l10n) {
    final tabs = [l10n.t('all'), l10n.pending, l10n.completed];
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.t('recentOrders'),
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.providerOrdersScreen),
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          // Tabs
          Row(
            children: List.generate(
              tabs.length,
              (i) => GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  margin: EdgeInsets.only(right: 2.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedTab == i
                        ? AppTheme.goldAccent
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: _selectedTab == i
                          ? AppTheme.goldAccent
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: _selectedTab == i
                          ? Colors.white
                          : AppTheme.grayText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          if (_filteredOrders.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Text(
                  l10n.t('noOrdersFound'),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ),
            )
          else
            ...(_filteredOrders.take(5).map((order) => _buildOrderTile(order))),
        ],
      ),
    );
  }

  Widget _buildOrderTile(VeraOrder order) {
    Color statusColor;
    Color statusBg;
    switch (order.status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        statusColor = AppTheme.success;
        statusBg = AppTheme.tintGreen;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusBg = AppTheme.tintAmber;
        break;
      case 'cancelled':
        statusColor = AppTheme.error;
        statusBg = AppTheme.tintRed;
        break;
      default:
        statusColor = AppTheme.info;
        statusBg = AppTheme.tintBlueSoft;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: AppTheme.ivoryLight,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.goldAccent,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (order.itemNames.isNotEmpty)
                  Text(
                    order.itemNames.take(2).join(', '),
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: AppTheme.grayText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'AED ${order.total.toStringAsFixed(0)}',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              SizedBox(height: 0.4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.cairo(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });
}
