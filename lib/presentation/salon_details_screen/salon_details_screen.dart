import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/user_interest_tracker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';

class SalonDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? salonData;
  const SalonDetailsScreen({super.key, this.salonData});

  @override
  ConsumerState<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends ConsumerState<SalonDetailsScreen> {
  bool _isSaved = false;
  bool _showFullDesc = false;
  String? _selectedService;
  Map<String, dynamic>? _serverData;

  Map<String, dynamic> get _salon {
    if (widget.salonData != null) {
      final merged = Map<String, dynamic>.from(widget.salonData!);
      if (_serverData != null) merged.addAll(_serverData!);
      return merged;
    }
    return _serverData ?? const {};
  }

  @override
  void initState() {
    super.initState();
    _isSaved = (_salon['isSaved'] as bool?) ?? false;
    UserInterestTracker.instance.recordProductView(widget.salonData ?? const {});
    final id = (widget.salonData?['id'] as String?) ?? '';
    if (id.isNotEmpty) {
      _fetchDetails(id);
    }
  }

  Future<void> _fetchDetails(String id) async {
    try {
      final service = await VeraApiService.instance.fetchServiceById(id);
      if (mounted && service != null) {
        setState(() => _serverData = service.toDetailsMap());
      }
    } catch (e, st) {
      debugPrint('SalonDetailsScreen._fetchDetails failed for id=$id: $e\n$st');
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
              SliverToBoxAdapter(child: _buildSalonInfo()),
              SliverToBoxAdapter(child: _buildStylistCard()),
              SliverToBoxAdapter(child: _buildDescription()),
              SliverToBoxAdapter(child: _buildLocationMap()),
              SliverToBoxAdapter(child: _buildServices()),
              SliverToBoxAdapter(child: _buildHoursInfo()),
              SliverToBoxAdapter(child: _buildLocationInfo()),
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
        l10n.t('salonDetailsTitle'),
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
              imageUrl: (_salon['image'] as String?) ?? '',
              width: double.infinity,
              height: 26.h,
              fit: BoxFit.cover,
              semanticLabel:
                  l10n.salonInteriorLabel((_salon['name'] as String?) ?? ''),
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
                        (_salon['badgeColor'] as int?) ?? 0xFFC8A96A,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      (_salon['badge'] as String?) ?? '',
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
                      color: ((_salon['isOpen'] as bool?) ?? true)
                          ? AppTheme.success
                          : AppTheme.warning,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      ((_salon['isOpen'] as bool?) ?? true)
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

  Widget _buildSalonInfo() {
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
                        (_salon['name'] as String?) ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (_salon['category'] as String?) ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: AppTheme.salons,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${_salon['rating'] ?? 0}',
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_salon['reviews'] ?? 0} ${l10n.reviewsCount}',
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppTheme.borderLight, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.location_on_outlined,
                  (_salon['location'] as String?) ?? '',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.attach_money_rounded,
                  l10n.localizePrice((_salon['price'] as String?) ?? ''),
                ),
              ],
            ),
            if (((_salon['isOpen'] as bool?) ?? true) &&
                _salon['waitTime'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoChip(
                Icons.access_time_rounded,
                l10n.t('waitTimeValue', args: {'time': '${_salon['waitTime']}'}),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.grayText),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11.sp, color: AppTheme.grayText),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStylistCard() {
    final l10n = AppLocalizations.of(context);
    final stylist =
        (_salon['providerName'] as String?) ??
        (_salon['provider'] as String?) ??
        '';
    if (stylist.isEmpty) return const SizedBox.shrink();
    final stylistImage =
        (_salon['providerAvatar'] as String?) ??
        (_salon['image'] as String?) ??
        '';
    final stylistTitle = ((_salon['providerVerified'] as bool?) ?? false)
        ? l10n.t('verifiedProvider')
        : (_salon['category'] as String? ?? '');
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.salonsBg,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppTheme.salons.withAlpha(60)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: CustomImageWidget(
                imageUrl: stylistImage,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                semanticLabel: l10n.t('professionalPortrait', args: {'name': stylist}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stylist,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    stylistTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: AppTheme.grayText,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.salons,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final l10n = AppLocalizations.of(context);
    final desc = _salon['description'] as String? ?? '';
    final isLong = desc.length > 120;
    final displayText = (!_showFullDesc && isLong)
        ? '${desc.substring(0, 120)}...'
        : desc;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
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
          Text(
            displayText,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText,
              height: 1.6,
            ),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _showFullDesc = !_showFullDesc),
              child: Text(
                _showFullDesc ? l10n.t('showLess') : l10n.t('readMore'),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.primaryPinkDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationMap() {
    final lat = _salon['latitude'];
    final lng = _salon['longitude'];
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
          markers: {Marker(markerId: const MarkerId('salon'), position: LatLng(latitude, longitude))},
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
    final services = <({String name, String duration, String price})>[];
    final rawServices = _salon['services'];
    if (rawServices is List) {
      for (final raw in rawServices) {
        final String name;
        final String duration;
        final String price;
        if (raw is Map) {
          name = raw['name']?.toString() ?? '';
          duration = raw['duration']?.toString() ?? '';
          price = raw['price']?.toString() ?? '';
        } else {
          name = raw.toString();
          duration = (_salon['duration'] as String?) ?? '';
          price = l10n.localizePrice((_salon['price'] as String?) ?? '');
        }
        if (name.isEmpty) continue;
        services.add((
          name: name,
          duration: duration,
          price: price,
        ));
      }
    }
    if (services.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.services,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          ...services.map((service) {
            final isSelected = _selectedService == service.name;
            return GestureDetector(
              onTap: () => setState(
                () => _selectedService = isSelected ? null : service.name,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.salonsBg : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isSelected ? AppTheme.salons : AppTheme.borderLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.salons : AppTheme.salonsBg,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        size: 18,
                        color: isSelected ? Colors.white : AppTheme.salons,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          Text(
                            service.duration,
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              color: AppTheme.grayText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.localizePrice(service.price),
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? AppTheme.salons : AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: isSelected ? AppTheme.salons : AppTheme.grayLight,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHoursInfo() {
    final l10n = AppLocalizations.of(context);
    final hours = (_salon['hours'] as String?) ?? '';
    if (hours.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.salonsBg,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                size: 20,
                color: AppTheme.salons,
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
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    hours,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
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

  Widget _buildLocationInfo() {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.salonsBg,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppTheme.salons,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_salon['location'] as String?) ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    _salon['phone'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.salonsBg,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 18,
                color: AppTheme.salons,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _selectedServicePrice(String? selected) {
    if (selected != null) {
      final rawServices = _salon['services'];
      if (rawServices is List) {
        for (final raw in rawServices) {
          if (raw is Map && raw['name']?.toString() == selected) {
            final price = raw['price']?.toString();
            if (price != null && price.isNotEmpty) return price;
          }
        }
      }
    }
    return AppLocalizations.of(context).localizePrice((_salon['price'] as String?) ?? '');
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 12, 4.w, 3.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedServicePrice(_selectedService),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  _selectedService ?? l10n.t('selectAService'),
                  maxLines: 1,
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppTheme.grayText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Call button
          OutlinedButton.icon(
            onPressed: () {
              final phone = (_salon['phone'] as String?) ?? '';
              if (phone.isNotEmpty) {
                launchUrl(Uri.parse('tel:$phone'));
              }
            },
            icon: const Icon(Icons.phone_rounded, size: 16),
            label: Text(
              l10n.t('call'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.salons,
              side: const BorderSide(color: AppTheme.salons),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              minimumSize: Size.zero,
            ),
          ),
          const SizedBox(width: 8),
          // Book button
          ElevatedButton(
            onPressed: () => context.push(
              AppRoutes.bookSalonScreen,
              extra: {
                ..._salon,
                if (_selectedService != null)
                  'preselectedService': _selectedService,
              },
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.salons,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size(32.w, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              l10n.t('book'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
