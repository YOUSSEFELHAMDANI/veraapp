import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_localizations.dart';
import '../../core/user_interest_tracker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';

class GymSportsDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? gymData;
  const GymSportsDetailsScreen({super.key, this.gymData});

  @override
  ConsumerState<GymSportsDetailsScreen> createState() =>
      _GymSportsDetailsScreenState();
}

class _GymSportsDetailsScreenState
    extends ConsumerState<GymSportsDetailsScreen> {
  bool _isSaved = false;
  bool _showFullDesc = false;
  Map<String, dynamic>? _serverData;

  Map<String, dynamic> get _gym {
    if (widget.gymData != null) {
      final merged = Map<String, dynamic>.from(widget.gymData!);
      if (_serverData != null) merged.addAll(_serverData!);
      return merged;
    }
    return _serverData ?? const {};
  }

  @override
  void initState() {
    super.initState();
    _isSaved = (_gym['isSaved'] as bool?) ?? false;
    UserInterestTracker.instance.recordProductView(widget.gymData ?? const {});
    final id = (widget.gymData?['id'] as String?) ?? '';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildGymInfo()),
              SliverToBoxAdapter(child: _buildTrainerCard()),
              SliverToBoxAdapter(child: _buildDescription()),
              SliverToBoxAdapter(child: _buildLocationMap()),
              SliverToBoxAdapter(child: _buildAmenities()),
              SliverToBoxAdapter(child: _buildMembershipPlans()),
              SliverToBoxAdapter(child: _buildHoursInfo()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final l10n = AppLocalizations.of(context);
    return SliverAppBar(
      expandedHeight: 26.h,
      pinned: true,
      backgroundColor: AppTheme.backgroundLight,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppTheme.charcoal,
          ),
        ),
      ),
      title: Text(
        l10n.t('gymDetailsTitle'),
        style: GoogleFonts.cairo(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppTheme.charcoal,
        ),
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: () => setState(() => _isSaved = !_isSaved),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 20,
              color: _isSaved ? AppTheme.primaryPinkDark : AppTheme.charcoal,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageWidget(
              imageUrl: (_gym['image'] as String?) ?? '',
              width: double.infinity,
              height: 26.h,
              fit: BoxFit.cover,
              semanticLabel:
                  l10n.t('gymInteriorLabel'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(80)],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color((_gym['badgeColor'] as int?) ?? 0xFFC8A96A),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      (_gym['badge'] as String?) ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ((_gym['isOpen'] as bool?) ?? true)
                          ? AppTheme.success
                          : AppTheme.warning,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      ((_gym['isOpen'] as bool?) ?? true)
                          ? l10n.statusOpen
                          : l10n.statusClosed,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymInfo() {
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_gym['name'] as String?) ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (_gym['category'] as String?) ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.localizePrice((_gym['price'] as String?) ?? ''),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppTheme.grayText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (_gym['location'] as String?) ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_gym['rating'] ?? 0}',
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${_gym['reviews'] ?? 0} ${l10n.reviewsCount})',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerCard() {
    final l10n = AppLocalizations.of(context);
    final trainer =
        (_gym['providerName'] as String?) ??
        (_gym['provider'] as String?) ??
        '';
    if (trainer.isEmpty) return const SizedBox.shrink();
    final trainerImage =
        (_gym['providerAvatar'] as String?) ??
        (_gym['image'] as String?) ??
        '';
    final trainerTitle = ((_gym['providerVerified'] as bool?) ?? false)
        ? l10n.t('verifiedProvider')
        : (_gym['category'] as String? ?? '');
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: CustomImageWidget(
                imageUrl: trainerImage,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                semanticLabel: l10n.t('trainerPortrait'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trainerTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: AppTheme.grayText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.gymBg,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: Color(0xFF5DADE2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final l10n = AppLocalizations.of(context);
    final desc = (_gym['description'] as String?) ?? '';
    final isLong = desc.length > 120;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
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
              l10n.t('about'),
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            if (desc.isEmpty)
              Text(
                l10n.t('noDescriptionAvailable'),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                  height: 1.5,
                ),
              )
            else
              Text(
                _showFullDesc || !isLong
                    ? desc
                    : '${desc.substring(0, 120)}...',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                  height: 1.5,
                ),
              ),
            if (isLong)
              GestureDetector(
                onTap: () => setState(() => _showFullDesc = !_showFullDesc),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _showFullDesc ? l10n.t('showLess') : l10n.t('readMore'),
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5DADE2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMap() {
    final lat = _gym['latitude'];
    final lng = _gym['longitude'];
    if (lat == null || lng == null) return const SizedBox.shrink();
    final latitude = (lat as num).toDouble();
    final longitude = (lng as num).toDouble();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(latitude, longitude), zoom: 15),
            markers: {Marker(markerId: const MarkerId('gym'), position: LatLng(latitude, longitude))},
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            liteModeEnabled: true,
            myLocationEnabled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildAmenities() {
    final l10n = AppLocalizations.of(context);
    final rawAmenities = _gym['amenities'];
    final amenities = rawAmenities is List
        ? rawAmenities.map((e) => e.toString()).toList()
        : <String>[];
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
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
              l10n.t('facilitiesAndAmenities'),
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gymBg,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: const Color(0xFF5DADE2).withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: Color(0xFF5DADE2),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            a,
                            style: GoogleFonts.cairo(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipPlans() {
    final l10n = AppLocalizations.of(context);
    final rawPlans = _gym['plans'];
    final plans = rawPlans is List
        ? rawPlans.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    if (plans.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
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
              l10n.t('membershipPlans'),
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            ...plans.asMap().entries.map((entry) {
              final plan = entry.value;
              final isHighlighted = entry.key == 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0xFF5DADE2).withAlpha(20)
                      : AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isHighlighted
                        ? const Color(0xFF5DADE2)
                        : AppTheme.borderLight,
                    width: isHighlighted ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  plan['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.charcoal,
                                  ),
                                ),
                              ),
                              if (isHighlighted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5DADE2),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    l10n.t('popular'),
                                    style: GoogleFonts.cairo(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan['desc'] as String,
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: AppTheme.grayText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.localizePrice(plan['price'] as String),
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: isHighlighted
                            ? const Color(0xFF5DADE2)
                            : AppTheme.goldAccent,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursInfo() {
    final l10n = AppLocalizations.of(context);
    final hours = (_gym['hours'] as String?) ?? '';
    if (hours.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.gymBg,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                size: 20,
                color: Color(0xFF5DADE2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('workingHours'),
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hours,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppTheme.grayText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final phone = _gym['phone']?.toString() ??
                  _gym['providerPhone']?.toString() ??
                  _gym['provider_phone']?.toString();
              if (phone != null && phone.isNotEmpty) {
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.gymBg,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFF5DADE2).withAlpha(60)),
              ),
              child: const Icon(
                Icons.phone_outlined,
                size: 20,
                color: Color(0xFF5DADE2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.bookGymScreen, extra: _gym),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5DADE2), Color(0xFF2E86C1)],
                  ),
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5DADE2).withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    l10n.t('bookASession'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
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
    );
  }
}
