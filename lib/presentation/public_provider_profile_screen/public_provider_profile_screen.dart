import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';

class PublicProviderProfileScreen extends ConsumerStatefulWidget {
  final String? providerId;
  final String? providerName;
  final String? providerCategory;
  final String? providerCity;
  final double? providerRating;
  final int? providerReviews;
  final String? providerImageUrl;
  final bool? isVerified;
  final String? providerEmail;
  final int? providerFollowers;

  const PublicProviderProfileScreen({
    super.key,
    this.providerId,
    this.providerName,
    this.providerCategory,
    this.providerCity,
    this.providerRating,
    this.providerReviews,
    this.providerImageUrl,
    this.isVerified,
    this.providerEmail,
    this.providerFollowers,
  });

  @override
  ConsumerState<PublicProviderProfileScreen> createState() =>
      _PublicProviderProfileScreenState();
}

class _PublicProviderProfileScreenState
    extends ConsumerState<PublicProviderProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _services = const [];
  List<Map<String, dynamic>> _serviceCards = const [];
  List<Map<String, dynamic>> _reviews = [];

  String? _apiName;
  String? _apiCategory;
  String? _apiCity;
  double? _apiRating;
  int? _apiReviewCount;
  String? _apiImageUrl;
  bool? _apiVerified;
  String? _apiEmail;
  int? _apiFollowers;
  String _description = '';
  bool _isFollowingBusy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // The provider card already contains enough data to render the profile
    // shell immediately. Network data can enrich it without blocking the page.
    _isLoading = widget.providerName?.trim().isEmpty ?? true;
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context);
    final hasFallback = widget.providerName?.trim().isNotEmpty == true;
    if (mounted) {
      setState(() {
        _isLoading = !hasFallback;
        _error = null;
      });
    }
    final providerId = widget.providerId;
    if (providerId == null || providerId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!hasFallback) _error = l10n.t('errorLoadProvider');
      });
      return;
    }

    VeraProvider? provider;
    List<VeraService> services = const [];

    // Provider details and services are optional independently. A slow or
    // unavailable services endpoint must not keep the whole profile loading.
    try {
      provider = await VeraApiService.instance
          .fetchProviderById(providerId)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}

    try {
      services = await VeraApiService.instance
          .fetchProviderServices(providerId)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      if (provider != null) {
        _apiName = provider!.name;
        _apiCategory = provider!.category;
        _apiCity = provider!.city;
        _apiRating = provider!.rating;
        _apiReviewCount = provider!.reviewCount;
        _apiImageUrl = provider!.imageUrl;
      _apiVerified = provider!.isVerified;
        _apiEmail = provider!.email;
        _apiFollowers = provider!.followers;
        _description = provider!.description;
      }
      _services = services.map(_serviceToMap).toList();
      _serviceCards = services.map((s) => s.toCardMap()).toList();
      _reviews = const [];
      _isLoading = false;
      if (provider == null && widget.providerName == null) {
        _error = l10n.t('errorLoadProvider');
      }
    });

    try {
      final reviews = await VeraApiService.instance.fetchReviews(
        targetId: providerId,
        targetType: 'provider',
      );
      if (!mounted) return;
      setState(() {
        _reviews = reviews.map((review) => {
          'name': review.authorName,
          'avatar': review.authorAvatar,
          'rating': review.rating,
          'date': review.createdAt,
          'service': review.targetType,
          'comment': review.comment,
        }).toList();
      });
    } catch (_) {}

    if (mounted) {
      final following = await VeraApiService.instance.isFollowingProvider(
        providerId,
      );
      if (mounted) setState(() => _isFollowing = following);
    }
  }

  Map<String, dynamic> _serviceToMap(VeraService s) {
    final sub = s.subcategory.isNotEmpty ? s.subcategory : s.category;
    final priceStr = s.price > 0
        ? 'AED ${s.price.toStringAsFixed(s.price == s.price.roundToDouble() ? 0 : 2)}'
        : 'Price on request';
    return {
      'name': s.name,
      'price': priceStr,
      'duration': s.duration,
      'rating': s.rating,
      'reviews': s.reviews,
      'imageUrl': s.imageUrl,
      'category': sub,
    };
  }

  String get _name => _apiName ?? widget.providerName ?? '';
  String get _category => _apiCategory ?? widget.providerCategory ?? '';
  String get _city => _apiCity ?? widget.providerCity ?? '';
  double get _rating => _apiRating ?? widget.providerRating ?? 0;
  int get _reviewCount => _apiReviewCount ?? widget.providerReviews ?? 0;
  String get _imageUrl => _apiImageUrl ?? widget.providerImageUrl ?? '';
  String get _email => _apiEmail ?? widget.providerEmail ?? '';
  int get _followers => _apiFollowers ?? widget.providerFollowers ?? 0;
  bool get _verified => _apiVerified ?? widget.isVerified ?? false;

  Future<void> _toggleFollow() async {
    final providerId = widget.providerId;
    if (_isFollowingBusy || providerId == null || providerId.isEmpty) return;
    if (!await requireAuth(context) || !mounted) return;
    var user = ref.read(currentUserProvider);
    user ??= await VeraApiService.instance.fetchProfile();
    if (!mounted || user == null || user.id.isEmpty) return;
    setState(() => _isFollowingBusy = true);
    final nextValue = !_isFollowing;
    final success = await VeraApiService.instance.followProvider(
      providerId,
      follow: nextValue,
      followerId: user.id,
    );
    if (!mounted) return;
    setState(() {
      _isFollowingBusy = false;
      if (success) _isFollowing = nextValue;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('followFailed'))),
      );
    }
  }

  Future<void> _composeMessage(AppLocalizations l10n) async {
    if (_email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('providerEmailUnavailable'))),
      );
      return;
    }
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.t('messageProvider')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: l10n.t('messageSubject'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.t('messageBody'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    if (shouldSend != true || !mounted) return;
    final sent = await VeraApiService.instance.sendEmail(
      to: _email,
      subject: subjectController.text.trim().isEmpty
          ? l10n.t('messageFromVera')
          : subjectController.text.trim(),
      body: bodyController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent ? l10n.t('messageSent') : l10n.t('messageFailed'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(l10n)
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.grayText,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                color: AppTheme.grayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPinkDark,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  l10n.retry,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
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

  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 30.h,
      pinned: true,
      backgroundColor: AppTheme.backgroundLight,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.charcoal,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.share_outlined,
              size: 18,
              color: AppTheme.charcoal,
            ),
            onPressed: () {},
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 22.w,
                    height: 22.w,
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
                      child: _imageUrl.isNotEmpty
                          ? CustomImageWidget(
                              imageUrl: _imageUrl,
                              width: 22.w,
                              height: 22.w,
                              fit: BoxFit.cover,
                                  semanticLabel: l10n.t('providerProfilePhoto', args: {'name': _name}),
                            )
                          : Container(
                              color: AppTheme.goldLight,
                              child: Center(
                                child: Text(
                                  _name.isNotEmpty
                                      ? _name[0].toUpperCase()
                                      : 'P',
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
                  SizedBox(width: 4.w),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name,
                                style: GoogleFonts.cairo(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.charcoal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (_verified)
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: AppTheme.info,
                              ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _city.isNotEmpty ? '$_category • $_city' : _category,
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: AppTheme.grayText,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n.t('ratingReviews', args: {'rating': '$_rating', 'count': '$_reviewCount'}),
                              style: GoogleFonts.cairo(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.2.h),
                        // Follow + Contact buttons
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleFollow,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 0.8.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _isFollowing
                                      ? null
                                      : AppTheme.primaryGradient,
                                  color: _isFollowing
                                      ? AppTheme.surfaceLight
                                      : null,
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: _isFollowing
                                      ? Border.all(
                                          color: AppTheme.primaryPink,
                                          width: 1.5,
                                        )
                                      : null,
                                  boxShadow: _isFollowing
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppTheme.primaryPink
                                                .withAlpha(77),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isFollowingBusy
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                      _isFollowing
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      size: 14,
                                      color: _isFollowing
                                          ? AppTheme.primaryPinkDark
                                          : Colors.white,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                              l10n.t(_isFollowing ? 'following' : 'follow'),
                              style: GoogleFonts.cairo(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                        color: _isFollowing
                                            ? AppTheme.primaryPinkDark
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                             SizedBox(width: 2.w),
                             GestureDetector(
                               onTap: () => _composeMessage(l10n),
                               child: Container(
                                 padding: EdgeInsets.symmetric(
                                   horizontal: 3.w,
                                   vertical: 0.8.h,
                                 ),
                                 decoration: BoxDecoration(
                                   color: AppTheme.surfaceLight,
                                   borderRadius: BorderRadius.circular(20.0),
                                   border: Border.all(
                                     color: AppTheme.borderLight,
                                     width: 1.5,
                                   ),
                                 ),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Icon(
                                       Icons.chat_bubble_outline_rounded,
                                       size: 13,
                                       color: AppTheme.charcoal,
                                     ),
                                     SizedBox(width: 1.w),
                                     Text(
                                       l10n.t('message'),
                                       style: GoogleFonts.cairo(
                                         fontSize: 11.sp,
                                         fontWeight: FontWeight.w600,
                                         color: AppTheme.charcoal,
                                       ),
                                     ),
                                   ],
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
            ],
          ),
        ),
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
        tabs: [
          Tab(text: l10n.t('about')),
          Tab(text: l10n.services),
          Tab(text: l10n.reviews),
        ],
      ),
    );
  }

  // ─── ABOUT TAB ────────────────────────────────────────────────
  Widget _buildOverviewTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(l10n),
          SizedBox(height: 2.5.h),
          _buildAboutSection(l10n),
          SizedBox(height: 2.5.h),
          _buildWorkingHours(l10n),
          SizedBox(height: 2.5.h),
          _buildLocationSection(l10n),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    final stats = [
      {
        'label': l10n.services,
        'value': '${_services.length}',
        'icon': Icons.design_services_outlined,
        'color': AppTheme.primaryPink,
        'bg': AppTheme.fashionBg,
      },
      {
        'label': l10n.t('followers'),
        'value': '$_followers',
        'icon': Icons.people_outline_rounded,
        'color': AppTheme.goldAccent,
        'bg': AppTheme.goldLight,
      },
      {
        'label': l10n.reviews,
        'value': '$_reviewCount',
        'icon': Icons.star_outline_rounded,
        'color': const Color(0xFFFF9500),
        'bg': AppTheme.tintAmberLight,
      },
    ];
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
                    fontSize: 14.sp,
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

  Widget _buildAboutSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('about'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Text(
            _description.isNotEmpty
                ? _description
                : l10n.t('noDescriptionAvailable'),
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHours(AppLocalizations l10n) {
    final hours = [
      {'day': l10n.t('mondayFriday'), 'time': '9:00 AM – 8:00 PM', 'open': true},
      {'day': l10n.t('saturday'), 'time': '10:00 AM – 6:00 PM', 'open': true},
      {'day': l10n.t('sunday'), 'time': l10n.t('closed'), 'open': false},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('workingHours'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: List.generate(hours.length, (i) {
              final h = hours[i];
              final isLast = i == hours.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          h['day'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        Text(
                          h['time'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: (h['open'] as bool)
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: AppTheme.borderLight,
                      indent: 4.w,
                      endIndent: 4.w,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.location,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppTheme.fashionBg,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.primaryPinkDark,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _city,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    Text(
                      l10n.t('unitedArabEmirates'),
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.grayText,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SERVICES TAB ─────────────────────────────────────────────
  Widget _buildServicesTab(AppLocalizations l10n) {
    if (_services.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.design_services_outlined,
                size: 48,
                color: AppTheme.grayText,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('noServicesAvailable'),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: _services.length,
      itemBuilder: (_, i) => _buildServiceCard(_services[i], i, l10n),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, int index, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: CustomImageWidget(
              imageUrl: service['imageUrl'] as String,
              width: 24.w,
              height: 24.w,
              fit: BoxFit.cover,
              semanticLabel: l10n.serviceImageLabel(service['name'] as String),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.fashionBg,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          service['category'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryPinkDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    service['name'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppTheme.grayText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        service['duration'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: AppTheme.grayText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${service['rating']} (${service['reviews']})',
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.localizePrice(service['price'] as String),
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(
                          AppRoutes.bookingScreen,
                          extra: _serviceCards[index],
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 0.6.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(
                            l10n.t('book'),
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
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
          ),
        ],
      ),
    );
  }

  // ─── REVIEWS TAB ──────────────────────────────────────────────
  Widget _buildReviewsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummary(l10n),
          SizedBox(height: 2.h),
          if (_reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: AppTheme.grayText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('noReviewsYet'),
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._reviews.map((r) => _buildReviewCard(r, l10n)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.tintCreamSoft, AppTheme.tintOrangeLight],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.goldLight),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                '$_rating',
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
                    i < _rating.floor()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ),
              SizedBox(height: 0.4.h),
              Text(
                l10n.t('reviewsCountLabel', args: {'count': '$_reviewCount'}),
                style: GoogleFonts.cairo(
                  fontSize: 9.sp,
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final total = _reviews.length;
                final matching = _reviews.where(
                  (review) =>
                      (review['rating'] as num).round() == star,
                ).length;
                final pct = total == 0 ? 0.0 : matching / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: AppTheme.grayText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppTheme.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFC107),
                            ),
                            minHeight: 6,
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
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, AppLocalizations l10n) {
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
                  semanticLabel: l10n.t('reviewerAvatar', args: {'name': review['name'] as String}),
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
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
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
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                     i < (review['rating'] as num).round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 12,
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
            decoration: BoxDecoration(
              color: AppTheme.fashionBg,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              review['service'] as String,
              style: GoogleFonts.cairo(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPinkDark,
              ),
            ),
          ),
          SizedBox(height: 0.8.h),
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
