import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../core/auth_session.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin, ProviderGuard {
  VeraUser? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  late TabController _tabController;
  Map<String, dynamic>? _stripeStatus;
  bool _stripeLoading = true;
  bool _stripeActionLoading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  // Services + reviews loaded from the API
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (!guardProviderSession()) return;
    _loadProfile();
    _loadStripeStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await VeraApiService.instance.fetchProviderProfile();
      if (mounted && user != null) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _phoneController.text = user.phone;
          _cityController.text = user.city;
        });
      }
    } catch (_) {}
    try {
      final services =
          await VeraApiService.instance.fetchProviderOwnServices();
      if (mounted) {
        setState(() {
          _services = List.generate(services.length, (i) {
            return _serviceToMap(services[i], i);
          });
        });
      }
    } catch (_) {}
    try {
      final reviews = await VeraApiService.instance.fetchReviews(
        targetId: _user?.id ?? '',
        targetType: 'provider',
      );
      if (mounted) {
        setState(() {
          _reviews = reviews.map(_reviewToMap).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Map<String, dynamic> _serviceToMap(VeraService service, int index) {
    final combos = <List<Color>>[
      [AppTheme.goldAccent, AppTheme.goldLight],
      [AppTheme.primaryPink, AppTheme.fashionBg],
      [const Color(0xFF8FD9F7), const Color(0xFFE0F5FD)],
    ];
    final icons = <IconData>[
      Icons.star_outline_rounded,
      Icons.design_services_outlined,
      Icons.flash_on_outlined,
    ];
    final c = combos[index % combos.length];
    final price = service.price > 0
        ? 'AED ${service.price.toStringAsFixed(service.price == service.price.roundToDouble() ? 0 : 2)}'
        : 'On request';
    return {
      'name': service.name,
      'price': price,
      'duration': service.duration,
      'icon': icons[index % icons.length],
      'color': c[0],
      'bg': c[1],
    };
  }

  Map<String, dynamic> _reviewToMap(VeraReview review) {
    return {
      'name': review.authorName,
      'avatar': review.authorAvatar,
      'rating': review.rating,
      'date': review.createdAt,
      'comment': review.comment,
      'service': '',
    };
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      final success = await VeraApiService.instance.updateProviderProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.t('profileUpdated')
                  : l10n.t('profileUpdateFailed'),
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.somethingWentWrong,
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final l10n = AppLocalizations.of(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
              kIsWeb ? 'Uploading...' : 'جاري الرفع...',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppTheme.goldAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      final url = await VeraApiService.instance.uploadProviderAvatar(picked.path);
      if (url != null && mounted) {
        setState(() {
          _user = _user?.copyWith(avatarUrl: url);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.t('profileUpdated'),
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.somethingWentWrong,
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Provider avatar upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.somethingWentWrong,
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthSession.instance.clearSession(
      clearBuyer: false,
      clearProvider: true,
    );
    if (mounted) context.go(AppRoutes.providerLoginScreen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldAccent),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(l10n),
              ],
              body: Column(
                children: [
                  _buildTabBar(l10n),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(l10n),
                        _buildServicesTab(l10n),
                        _buildReviewsTab(l10n),
                        _buildStripeTab(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 28.h,
      pinned: true,
      backgroundColor: AppTheme.backgroundLight,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.go(AppRoutes.providerDashboardScreen),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.charcoal,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _isSaving ? null : _saveProfile,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    l10n.save,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildProfileHeader(l10n)),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.tintOrangeLight, AppTheme.tintCream, AppTheme.tintPink],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(5.w, 7.h, 5.w, 2.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.goldAccent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldAccent.withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _user?.avatarUrl.isNotEmpty == true
                          ? CustomImageWidget(
                              imageUrl: _user!.avatarUrl,
                              width: 20.w,
                              height: 20.w,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppTheme.goldLight,
                              child: Center(
                                child: Text(
                                  (_user?.name.isNotEmpty == true
                                      ? _user!.name[0].toUpperCase()
                                      : 'P'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.goldAccent,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              ),
              SizedBox(width: 4.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _user?.name ?? l10n.t('provider'),
                      style: GoogleFonts.cairo(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _user?.email ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: AppTheme.grayText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        _buildBadge(
                          Icons.verified_rounded,
                          l10n.t('verifiedProviderBadge'),
                          AppTheme.goldAccent,
                          AppTheme.goldLight,
                        ),
                        SizedBox(width: 2.w),
                        _buildBadge(
                          Icons.star_rounded,
                          '4.8',
                          const Color(0xFFFF9500),
                          AppTheme.tintAmberLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 1.w),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.goldAccent,
        unselectedLabelColor: AppTheme.grayText,
        indicatorColor: AppTheme.goldAccent,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.cairo(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: l10n.t('overview')),
          Tab(text: l10n.services),
          Tab(text: l10n.reviews),
          const Tab(text: 'Stripe Connect'),
        ],
      ),
    );
  }

  // ─── OVERVIEW TAB ─────────────────────────────────────────────
  Widget _buildOverviewTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(l10n),
          SizedBox(height: 1.8.h),
          _buildStripeShortcut(),
          SizedBox(height: 2.5.h),
          _buildFormSection(l10n),
          SizedBox(height: 2.5.h),
          _buildMenuSection(l10n),
          SizedBox(height: 2.5.h),
          _buildLogoutButton(l10n),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStripeShortcut() {
    final connected = _stripeStatus?['connected'] == true;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _tabController.animateTo(3),
      child: Container(
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF7F5FF), Color(0xFFEDEAFF)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCD5FF)),
        ),
        child: Row(children: [
          Container(width: 12.w, height: 12.w, decoration: BoxDecoration(color: const Color(0xFF635BFF).withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF635BFF))),
          SizedBox(width: 3.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Stripe Connect', style: GoogleFonts.cairo(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: AppTheme.charcoal)), SizedBox(height: .3.h), Text(connected ? 'حسابك مرتبط وجاهز لاستلام الأرباح' : 'اربط حسابك البنكي لاستلام الأرباح', style: GoogleFonts.cairo(fontSize: 10.sp, color: AppTheme.grayText))])),
          Icon(connected ? Icons.check_circle : Icons.arrow_forward_ios_rounded, size: 18, color: connected ? AppTheme.success : const Color(0xFF635BFF)),
        ]),
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    final stats = [
      {
        'label': l10n.orders,
        'value': '${_user?.ordersCount ?? 0}',
        'icon': Icons.shopping_bag_outlined,
        'color': AppTheme.primaryPink,
        'bg': AppTheme.fashionBg,
      },
      {
        'label': l10n.bookings,
        'value': '${_user?.bookingsCount ?? 0}',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFF8FD9F7),
        'bg': const Color(0xFFE0F5FD),
      },
      {
        'label': l10n.points,
        'value': '${_user?.loyaltyPoints ?? 0}',
        'icon': Icons.stars_outlined,
        'color': AppTheme.goldAccent,
        'bg': AppTheme.goldLight,
      },
    ];
    // Loyalty points hidden temporarily — filter them out
    stats.removeWhere((s) => s['label'] == l10n.points);
    return Row(
      children: List.generate(stats.length, (i) {
        final s = stats[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < stats.length - 1 ? 2.w : 0),
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: s['bg'] as Color,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    s['icon'] as IconData,
                    color: s['color'] as Color,
                    size: 18,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  s['value'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  s['label'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 9.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFormSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('businessInformation'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        _buildField(
          l10n.t('businessFullName'),
          _nameController,
          Icons.business_outlined,
        ),
        SizedBox(height: 1.5.h),
        _buildField(
          l10n.phoneNumber,
          _phoneController,
          Icons.phone_outlined,
          type: TextInputType.phone,
        ),
        SizedBox(height: 1.5.h),
        _buildField(
          l10n.t('cityLocation'),
          _cityController,
          Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 0.8.h),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          style: GoogleFonts.cairo(fontSize: 13.sp, color: AppTheme.charcoal),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.grayText, size: 20),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: AppTheme.goldAccent,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.8.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(AppLocalizations l10n) {
    final items = [
      _MenuItem(
        icon: Icons.design_services_outlined,
        label: l10n.t('myServices'),
        route: AppRoutes.providerServicesScreen,
        color: AppTheme.primaryPink,
        bg: AppTheme.fashionBg,
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        label: l10n.t('myOrders'),
        route: AppRoutes.providerOrdersScreen,
        color: const Color(0xFF8FD9F7),
        bg: const Color(0xFFE0F5FD),
      ),
      _MenuItem(
        icon: Icons.campaign_outlined,
        label: l10n.t('adSubscriptionPlans'),
        route: AppRoutes.providerSubscriptionsScreen,
        color: AppTheme.goldAccent,
        bg: AppTheme.goldLight,
      ),
      _MenuItem(
        icon: Icons.layers_outlined,
        label: l10n.t('myPlan'),
        route: AppRoutes.providerPlansScreen,
        color: AppTheme.primaryPinkDark,
        bg: AppTheme.primaryPinkLight,
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        label: l10n.settings,
        route: AppRoutes.settingsScreen,
        color: AppTheme.grayText,
        bg: AppTheme.ivoryLight,
      ),
    ];
    return Column(
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
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: List.generate(
              items.length,
              (i) => Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 9.w,
                      height: 9.w,
                      decoration: BoxDecoration(
                        color: items[i].bg,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        items[i].icon,
                        color: items[i].color,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      items[i].label,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.grayLight,
                      size: 20,
                    ),
                    onTap: () => context.go(items[i].route),
                  ),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      color: AppTheme.borderLight,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
        label: Text(
          l10n.signOut,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  // ─── SERVICES TAB ─────────────────────────────────────────────
  Widget _buildServicesTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.t('myServices'),
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.providerServicesScreen),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        l10n.addService,
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ..._services.map((service) => _buildServiceCard(service)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: service['bg'] as Color,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              service['icon'] as IconData,
              color: service['color'] as Color,
              size: 22,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppTheme.grayText,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      service['duration'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.localizePrice(service['price'] as String),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldAccent,
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: BoxDecoration(
                        color: AppTheme.ivoryLight,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ),
                  SizedBox(width: 1.5.w),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: BoxDecoration(
                        color: AppTheme.tintRed,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppTheme.error.withAlpha(77)),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadStripeStatus() async {
    final result = await VeraApiService.instance.fetchStripeConnectStatus();
    if (!mounted) return;
    setState(() { _stripeStatus = result; _stripeLoading = false; });
  }

  Future<void> _openStripeOnboarding({bool refresh = false}) async {
    setState(() => _stripeActionLoading = true);
    final result = refresh ? await VeraApiService.instance.refreshStripeConnect() : await VeraApiService.instance.startStripeConnect();
    final url = result?['url']?.toString();
    if (url != null && url.isNotEmpty) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() { _stripeActionLoading = false; if (result != null) _stripeStatus = {...?_stripeStatus, ...result}; });
    if (result == null || result['error'] != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['error']?.toString() ?? 'تعذر الاتصال بـ Stripe', style: GoogleFonts.cairo())));
  }

  Future<void> _disconnectStripe() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text('فصل حساب Stripe', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)), content: Text('هل تريد فصل حساب Stripe Connect؟', style: GoogleFonts.cairo()), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('فصل الحساب', style: GoogleFonts.cairo(color: AppTheme.error)))]));
    if (confirmed != true) return;
    setState(() => _stripeActionLoading = true);
    final ok = await VeraApiService.instance.disconnectStripeConnect();
    if (!mounted) return;
    setState(() { _stripeActionLoading = false; if (ok) _stripeStatus = {'connected': false, 'status': 'not_connected'}; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم فصل حساب Stripe' : 'تعذر فصل الحساب', style: GoogleFonts.cairo())));
  }

  Widget _buildStripeTab(AppLocalizations l10n) {
    final status = _stripeStatus ?? const <String, dynamic>{};
    final connected = status['connected'] == true;
    final incomplete = status['status'] == 'onboarding_incomplete' || status['status'] == 'onboarding_started';
    return RefreshIndicator(onRefresh: _loadStripeStatus, child: ListView(padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h), children: [
      Container(padding: EdgeInsets.all(5.w), decoration: BoxDecoration(color: const Color(0xFFF6F4FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE4DFFF))), child: Row(children: [Container(width: 13.w, height: 13.w, decoration: BoxDecoration(color: const Color(0xFF635BFF).withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF635BFF))), SizedBox(width: 3.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Stripe Connect', style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppTheme.charcoal)), Text('استلم أرباحك مباشرة في حسابك البنكي بأمان عبر Stripe.', style: GoogleFonts.cairo(fontSize: 10.5.sp, color: AppTheme.grayText))]))])),
      SizedBox(height: 2.h),
      if (_stripeLoading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF635BFF)))) else if (connected) ...[
        _stripeInfoCard('الحالة', 'الحساب مرتبط وجاهز لاستلام الدفعات', Icons.verified_outlined, AppTheme.success),
        if (status['accountId'] != null) _stripeInfoCard('معرف حساب Stripe', status['accountId'].toString(), Icons.badge_outlined, const Color(0xFF635BFF)),
        _stripeInfoCard('جدول التحويل', 'تحويل يومي بعد نافذة حماية 14 يومًا', Icons.calendar_month_outlined, AppTheme.goldAccent),
        OutlinedButton.icon(onPressed: _stripeActionLoading ? null : _disconnectStripe, icon: const Icon(Icons.link_off, color: AppTheme.error), label: Text('فصل حساب Stripe', style: GoogleFonts.cairo(color: AppTheme.error))),
      ] else ...[
        _stripeInfoCard('قبل البدء', 'أكمل بياناتك البنكية في صفحة Stripe الآمنة. لا نخزن بياناتك البنكية داخل VÉRA.', Icons.shield_outlined, const Color(0xFF635BFF)),
        _stripeInfoCard('التحويلات', 'تبدأ التسوية بعد 14 يومًا من اكتمال كل طلب', Icons.timelapse_outlined, AppTheme.goldAccent),
        SizedBox(height: 1.h),
        SizedBox(width: double.infinity, height: 6.h, child: FilledButton.icon(onPressed: _stripeActionLoading ? null : () => _openStripeOnboarding(refresh: incomplete), icon: _stripeActionLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.credit_card), label: Text(incomplete ? 'إكمال إعداد Stripe' : 'ربط حساب Stripe', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF635BFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ],
      SizedBox(height: 2.h), Text('كيف تعمل العملية؟', style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoal)), SizedBox(height: 1.h),
      ...[
        'اربط حساب Stripe مرة واحدة',
        'يؤكد العميل استلام الطلب',
        'تبدأ فترة الحماية لمدة 14 يومًا',
        'يحوّل Stripe المبلغ تلقائيًا إلى حسابك',
      ].asMap().entries.map(
        (entry) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF635BFF).withValues(alpha: .12),
            child: Text(
              '${entry.key + 1}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF635BFF),
              ),
            ),
          ),
          title: Text(
            entry.value,
            style: GoogleFonts.cairo(fontSize: 11.5.sp, color: AppTheme.charcoal),
          ),
        ),
      ),
    ]));
  }

  Widget _stripeInfoCard(String title, String value, IconData icon, Color color) => Container(margin: EdgeInsets.only(bottom: 1.2.h), padding: EdgeInsets.all(3.5.w), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)), child: Row(children: [Icon(icon, color: color, size: 22), SizedBox(width: 3.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.cairo(fontSize: 10.sp, color: AppTheme.grayText)), Text(value, style: GoogleFonts.cairo(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoal))]))]));

  // ─── REVIEWS TAB ──────────────────────────────────────────────
  Widget _buildReviewsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummary(),
          SizedBox(height: 2.5.h),
          Text(
            l10n.t('customerReviews'),
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          SizedBox(height: 1.5.h),
          ..._reviews.map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.tintCreamWarm, AppTheme.tintOrangeLight],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.goldLight),
      ),
      child: Row(
        children: [
          // Big rating number
          Column(
            children: [
              Text(
                '4.8',
                style: GoogleFonts.cairo(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < 5 ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFF9500),
                    size: 14,
                  ),
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                l10n.t('reviewsCountLabel', args: {'count': '${_reviews.length}'}),
                style: GoogleFonts.cairo(
                  fontSize: 9.sp,
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
          SizedBox(width: 5.w),
          // Rating bars
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5, 0.8),
                _buildRatingBar(4, 0.15),
                _buildRatingBar(3, 0.05),
                _buildRatingBar(2, 0.0),
                _buildRatingBar(1, 0.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double fraction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        children: [
          Text(
            '$stars',
            style: GoogleFonts.cairo(fontSize: 9.sp, color: AppTheme.grayText),
          ),
          SizedBox(width: 1.w),
          const Icon(Icons.star_rounded, color: Color(0xFFFF9500), size: 10),
          SizedBox(width: 1.5.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: AppTheme.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFF9500),
                ),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: CustomImageWidget(
                  imageUrl: review['avatar'] as String,
                  width: 10.w,
                  height: 10.w,
                  fit: BoxFit.cover,
                  semanticLabel: l10n.profilePhotoOf(review['name'] as String),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          review['rating'] as int,
                          (_) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFF9500),
                            size: 12,
                          ),
                        ),
                        ...List.generate(
                          5 - (review['rating'] as int),
                          (_) => Icon(
                            Icons.star_outline_rounded,
                            color: AppTheme.grayLight,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                review['date'] as String,
                style: GoogleFonts.cairo(
                  fontSize: 9.sp,
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: AppTheme.ivoryLight,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              review['service'] as String,
              style: GoogleFonts.cairo(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.goldAccent,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            review['comment'] as String,
            style: GoogleFonts.cairo(
              fontSize: 11.sp,
              color: AppTheme.grayText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final Color bg;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    required this.bg,
  });
}
