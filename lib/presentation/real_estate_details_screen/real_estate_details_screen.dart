import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class RealEstateDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? propertyData;
  const RealEstateDetailsScreen({super.key, this.propertyData});

  @override
  ConsumerState<RealEstateDetailsScreen> createState() =>
      _RealEstateDetailsScreenState();
}

class _RealEstateDetailsScreenState
    extends ConsumerState<RealEstateDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _showFullDesc = false;
  late ScrollController _scrollController;
  Map<String, dynamic>? _serverData;

  Map<String, dynamic> get _property {
    if (widget.propertyData != null) {
      final merged = Map<String, dynamic>.from(widget.propertyData!);
      if (_serverData != null) merged.addAll(_serverData!);
      return merged;
    }
    return _serverData ?? const {};
  }

  final List<Map<String, dynamic>> _amenityIcons = [
    {'label': 'Swimming Pool', 'icon': Icons.pool_rounded},
    {'label': 'Gym', 'icon': Icons.fitness_center_rounded},
    {'label': 'Parking', 'icon': Icons.local_parking_rounded},
    {'label': 'Security', 'icon': Icons.security_rounded},
    {'label': 'Balcony', 'icon': Icons.balcony_rounded},
    {'label': 'Sea View', 'icon': Icons.water_rounded},
    {'label': 'Furnished', 'icon': Icons.chair_rounded},
    {'label': 'Central A/C', 'icon': Icons.ac_unit_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    UserInterestTracker.instance.recordProductView(widget.propertyData ?? const {});
    final id = (widget.propertyData?['id'] as String?) ?? '';
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.charcoal,
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.propertyDetails,
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            color: AppTheme.charcoal,
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 20,
              color: _isSaved ? AppTheme.primaryPinkDark : AppTheme.charcoal,
            ),
            onPressed: () => setState(() => _isSaved = !_isSaved),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(),
                _buildPropertyHeader(),
                _buildMetaRow(),
                _buildAgentCard(),
                _buildDescription(),
                _buildLocationMap(),
                _buildAmenities(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeroImage() {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        CustomImageWidget(
          imageUrl: (_property['image'] as String?) ?? '',
          width: double.infinity,
          height: 25.h,
          fit: BoxFit.cover,
          semanticLabel:
              l10n.propertyExteriorLabel((_property['title'] as String?) ?? ''),
        ),
        // Badge
        Positioned(
          top: 12,
          left: 4.w,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color((_property['badgeColor'] as int?) ?? 0xFFD898AA),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              (_property['badge'] as String?) ?? '',
              style: GoogleFonts.cairo(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_property['title'] as String?) ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppTheme.primaryPinkDark,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        (_property['location'] as String?) ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: AppTheme.grayText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPinkLight,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: AppTheme.primaryPinkDark.withAlpha(60),
                  ),
                ),
                child: Text(
                  (_property['type'] as String?) ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryPinkDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.localizePrice((_property['price'] as String?) ?? ''),
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldAccent,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final l10n = AppLocalizations.of(context);
    final items = <Map<String, dynamic>>[
      if (_property['beds'] != null)
        {'icon': Icons.bed_rounded, 'label': '${_property['beds']} ${l10n.t('beds')}'},
      if (_property['baths'] != null)
        {
          'icon': Icons.bathtub_outlined,
          'label': '${_property['baths']} ${l10n.t('baths')}',
        },
      if ((_property['area'] as String?)?.isNotEmpty ?? false)
        {
          'icon': Icons.square_foot_rounded,
          'label': (_property['area'] as String?) ?? '',
        },
      if ((_property['floor'] as String?)?.isNotEmpty ?? false)
        {
          'icon': Icons.layers_rounded,
          'label': (_property['floor'] as String?) ?? '',
        },
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 20,
                    color: AppTheme.primaryPinkDark,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgentCard() {
    final l10n = AppLocalizations.of(context);
    final agent = (_property['providerName'] as String?) ?? '';
    if (agent.isEmpty) return const SizedBox.shrink();
    final agentImage =
        (_property['providerAvatar'] as String?) ??
        (_property['image'] as String?) ??
        '';
    final agentTitle =
        (_property['category'] as String?) ??
        (_property['subcategory'] as String?) ??
        '';
    final agentPhone =
        (_property['phone'] as String?) ??
        (_property['providerPhone'] as String?) ??
        (_property['provider_phone'] as String?) ??
        '';
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: CustomImageWidget(
                    imageUrl: agentImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.profilePhotoOf(agent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent,
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      Text(
                        agentTitle,
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
                    _buildAgentAction(Icons.phone_outlined, AppTheme.success, onTap: () async {
                      final phone = (_property['phone'] as String?) ??
                          (_property['providerPhone'] as String?) ??
                          (_property['provider_phone'] as String?) ?? '';
                      if (phone.isNotEmpty) {
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      }
                    }),
                    const SizedBox(width: 8),
                    _buildAgentAction(
                      Icons.chat_bubble_outline_rounded,
                      AppTheme.primaryPinkDark,
                    ),
                  ],
                ),
              ],
            ),
            if (agentPhone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withAlpha(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded, size: 18, color: AppTheme.success),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('tel:$agentPhone');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      child: Text(
                        agentPhone,
                        style: GoogleFonts.cairo(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgentAction(IconData icon, Color color, {VoidCallback? onTap}) {
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
    final desc = (_property['description'] as String?) ?? '';
    final isLong = desc.length > 150;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.description,
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

  Widget _buildAmenities() {
    final l10n = AppLocalizations.of(context);
    final amenities = (_property['amenities'] as List<dynamic>?) ?? [];
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.amenities,
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
            children: amenities.map((a) {
              final amenityStr = a as String;
              final iconData =
                  _amenityIcons.firstWhere(
                        (e) => e['label'] == amenityStr,
                        orElse: () => {
                          'label': amenityStr,
                          'icon': Icons.check_circle_outline_rounded,
                        },
                      )['icon']
                      as IconData;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPinkLight,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconData, size: 14, color: AppTheme.primaryPinkDark),
                    const SizedBox(width: 6),
                    Text(
                      amenityStr,
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryPinkDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap() {
    final lat = _property['latitude'];
    final lng = _property['longitude'];
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
          markers: {Marker(markerId: const MarkerId('property'), position: LatLng(latitude, longitude))},
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

  Widget _buildBottomBar() {
    final phone = (_property['phone']?.toString().isNotEmpty == true
        ? _property['phone']
        : _property['providerPhone'] ?? _property['provider_phone'] ?? '')
        .toString();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: phone.isNotEmpty ? () => launchUrl(Uri.parse('tel:$phone')) : null,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: Text(AppLocalizations.of(context).t('call'), style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryPinkDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: phone.isNotEmpty ? () => launchUrl(Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9+]'), '')}')) : null,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text('WhatsApp', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}