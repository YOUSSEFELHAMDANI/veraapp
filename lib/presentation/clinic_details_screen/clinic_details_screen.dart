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
import '../../services/vera_api_service.dart';
import '../booking_screen/widgets/booking_flow_sheet.dart';

class ClinicDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? clinicData;
  const ClinicDetailsScreen({super.key, this.clinicData});

  @override
  ConsumerState<ClinicDetailsScreen> createState() =>
      _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends ConsumerState<ClinicDetailsScreen> {
  bool _isSaved = false;
  bool _showFullDesc = false;
  Map<String, dynamic>? _serverData;

  Map<String, dynamic> get _clinic {
    if (widget.clinicData != null) {
      final merged = Map<String, dynamic>.from(widget.clinicData!);
      if (_serverData != null) merged.addAll(_serverData!);
      return merged;
    }
    return _serverData ?? const {};
  }

  @override
  void initState() {
    super.initState();
    UserInterestTracker.instance.recordProductView(widget.clinicData ?? const {});
    final id = (widget.clinicData?['id'] as String?) ?? '';
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
              SliverToBoxAdapter(child: _buildClinicInfo()),
              SliverToBoxAdapter(child: _buildDoctorCard()),
              SliverToBoxAdapter(child: _buildDescription()),
              SliverToBoxAdapter(child: _buildLocationMap()),
              SliverToBoxAdapter(child: _buildServices()),
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
        l10n.t('clinicDetailsTitle'),
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
              imageUrl: (_clinic['image'] as String?) ?? '',
              width: double.infinity,
              height: 26.h,
              fit: BoxFit.cover,
              semanticLabel:
                  l10n.serviceImageLabel((_clinic['name'] as String?) ?? 'Service'),
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
                      color: Color(
                        (_clinic['badgeColor'] as int?) ?? 0xFFC8A96A,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      (_clinic['badge'] as String?) ?? '',
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
                      color: ((_clinic['isOpen'] as bool?) ?? true)
                          ? AppTheme.success
                          : AppTheme.warning,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      ((_clinic['isOpen'] as bool?) ?? true)
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

  Widget _buildClinicInfo() {
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
                        (_clinic['name'] as String?) ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (_clinic['category'] as String?) ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.localizePrice((_clinic['price'] as String?) ?? ''),
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppTheme.grayText,
                ),
                const SizedBox(width: 4),
                Text(
                  (_clinic['location'] as String?) ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Color(0xFFFFB547),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_clinic['rating'] ?? 0}',
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  ' (${_clinic['reviews'] ?? 0} ${l10n.reviewsCount})',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
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

  Widget _buildDoctorCard() {
    final l10n = AppLocalizations.of(context);
    final doctor = (_clinic['providerName'] as String?) ?? '';
    if (doctor.isEmpty) return const SizedBox.shrink();
    final doctorImage =
        (_clinic['providerAvatar'] as String?) ??
        (_clinic['image'] as String?) ??
        '';
    final doctorTitle = ((_clinic['providerVerified'] as bool?) ?? false)
        ? l10n.t('verifiedProvider')
        : (_clinic['category'] as String? ?? '');
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: CustomImageWidget(
                imageUrl: doctorImage,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                semanticLabel: l10n.profilePhotoOf(doctor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    doctorTitle,
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
                _buildActionBtn(Icons.phone_outlined, AppTheme.success, onTap: () async {
                  final phone = (_clinic['phone'] as String?) ?? '';
                  if (phone.isNotEmpty) {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  }
                }),
                const SizedBox(width: 8),
                _buildActionBtn(
                  Icons.chat_bubble_outline_rounded,
                  AppTheme.primaryPinkDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, {VoidCallback? onTap}) {
    final btn = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
    if (onTap == null) return btn;
    return GestureDetector(onTap: onTap, child: btn);
  }

  Widget _buildDescription() {
    final l10n = AppLocalizations.of(context);
    final desc = (_clinic['description'] as String?) ?? '';
    final isLong = desc.length > 150;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('about'),
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
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
                height: 1.6,
              ),
            )
          else
            Text(
              _showFullDesc || !isLong ? desc : '${desc.substring(0, 150)}...',
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppTheme.grayText,
                height: 1.6,
              ),
            ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _showFullDesc = !_showFullDesc),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _showFullDesc ? l10n.t('showLessArrow') : l10n.t('viewMoreArrow'),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppTheme.primaryPinkDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationMap() {
    final lat = _clinic['latitude'];
    final lng = _clinic['longitude'];
    if (lat == null || lng == null) return const SizedBox.shrink();
    final latitude = (lat as num).toDouble();
    final longitude = (lng as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(latitude, longitude), zoom: 15),
          markers: {Marker(markerId: const MarkerId('clinic'), position: LatLng(latitude, longitude))},
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          liteModeEnabled: true,
          myLocationEnabled: false,
        ),
      ),
    );
  }

  Widget _buildServices() {
    final l10n = AppLocalizations.of(context);
    final rawServices = _clinic['services'];
    final services = rawServices is List
        ? rawServices.map((e) => e.toString()).toList()
        : <String>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.services,
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tintPinkLight,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: Color(0xFFE787C9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s,
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFE787C9),
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
    );
  }

  Widget _buildHoursInfo() {
    final hours = (_clinic['hours'] as String?) ?? '';
    final phone = (_clinic['phone'] as String?) ?? '';
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            if (hours.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: AppTheme.grayText,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    hours,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            if (hours.isNotEmpty && phone.isNotEmpty) const SizedBox(height: 8),
            if (phone.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppTheme.grayText,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    phone,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 12, 4.w, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final phone = (_clinic['phone'] as String?) ?? '';
                if (phone.isNotEmpty) {
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: Text(
                l10n.t('call'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryPinkDark,
                side: const BorderSide(color: AppTheme.primaryPinkDark),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                minimumSize: Size.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                final priceStr = _clinic['price']?.toString() ?? '0';
                final priceNum =
                    double.tryParse(
                      priceStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                    ) ??
                    0.0;
                final serviceName =
                    (_clinic['name'] as String?) ?? 'Véra Service';
                final providerId =
                    _clinic['providerId']?.toString() ??
                    _clinic['provider_id']?.toString();
                final providerName =
                    (_clinic['providerName'] as String?) ??
                    (_clinic['provider'] as String?) ??
                    'Véra';
                final serviceId =
                    _clinic['id']?.toString() ?? serviceName;
                showBookingFlowSheet(
                  context,
                  args: BookingFlowSheetArgs(
                    serviceId: serviceId,
                    serviceName: serviceName,
                    category: 'Clinics',
                    providerId: providerId,
                    providerName: providerName,
                    price: priceNum,
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                l10n.bookAppointment,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE787C9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                minimumSize: Size.zero,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
