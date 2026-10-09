import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_localizations.dart';
import '../../core/user_interest_tracker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? jobData;
  const JobDetailsScreen({super.key, this.jobData});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isSaved = false;
  bool _showFullOverview = false;
  Map<String, dynamic>? _serverData;

  Map<String, dynamic> get _job {
    if (widget.jobData != null) {
      final merged = Map<String, dynamic>.from(widget.jobData!);
      if (_serverData != null) merged.addAll(_serverData!);
      return merged;
    }
    return _serverData ?? const {};
  }

  @override
  void initState() {
    super.initState();
    UserInterestTracker.instance.recordProductView(widget.jobData ?? const {});
    final id = (widget.jobData?['id'] as String?) ?? '';
    if (id.isNotEmpty) {
      _fetchDetails(id);
      _loadBookmark(id);
    }
  }

  String get _bookmarkKey => 'job_bookmark_${_job['id'] ?? ''}';

  Future<void> _loadBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _isSaved = prefs.getBool('job_bookmark_$id') ?? false);
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isSaved = !_isSaved);
    await prefs.setBool(_bookmarkKey, _isSaved);
  }

  Future<void> _shareJob() async {
    final title = _job['title']?.toString() ?? '';
    final company = _job['company']?.toString() ?? '';
    final url = 'https://veraapp.app';
    final text = 'Check out this job: $title at $company\n$url';
    final uri = Uri(scheme: 'mailto', queryParameters: {'subject': 'Job Opportunity: $title', 'body': text});
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              SliverToBoxAdapter(child: _buildCompanyCard()),
              SliverToBoxAdapter(child: _buildJobMeta()),
              SliverToBoxAdapter(child: _buildTags()),
              SliverToBoxAdapter(child: _buildOverview()),
              SliverToBoxAdapter(child: _buildResponsibilities()),
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
    final coverImage =
        (_job['coverImage'] as String?) ??
        (_job['logo'] as String?) ??
        '';
    return SliverAppBar(
      expandedHeight: 22.h,
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
        l10n.jobDetails,
        style: GoogleFonts.cairo(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppTheme.charcoal,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageWidget(
              imageUrl: coverImage,
              width: double.infinity,
              height: 22.h,
              fit: BoxFit.cover,
              semanticLabel: l10n.t('officeBuildingLabel'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard() {
    final l10n = AppLocalizations.of(context);
    final logoUrl = (_job['logo'] as String?) ?? '';
    final title = (_job['title'] as String?) ?? '';
    final company = (_job['company'] as String?) ?? '';
    final location = (_job['location'] as String?) ?? '';
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
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
                imageUrl: logoUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                semanticLabel: l10n.companyLogoLabel(company),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                  Text(
                    location,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _shareJob,
              child: Icon(
                Icons.share_outlined,
                color: AppTheme.grayText,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobMeta() {
    final l10n = AppLocalizations.of(context);
    final type = (_job['type'] as String?) ?? '';
    final workMode = (_job['workMode'] as String?) ?? '';
    final salary = (_job['salary'] as String?) ?? '';
    if (type.isEmpty && workMode.isEmpty && salary.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Row(
        children: [
          if (type.isNotEmpty) ...[
            _buildMetaChip(
              Icons.work_outline_rounded,
              type,
              AppTheme.primaryPinkLight,
              AppTheme.primaryPinkDark,
            ),
          ],
          if (workMode.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildMetaChip(
              Icons.location_on_outlined,
              workMode,
              AppTheme.tintGreen,
              AppTheme.success,
            ),
          ],
          if (salary.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.tintPeach,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  l10n.localizePrice(salary),
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.goldAccent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    final rawTags = _job['tags'];
    final tags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.ivoryLight,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildOverview() {
    final l10n = AppLocalizations.of(context);
    final overview =
        (_job['description'] as String?) ??
        (_job['overview'] as String?) ??
        '';
    final isLong = overview.length > 150;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('jobOverview'),
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          if (overview.isEmpty)
            Text(
              l10n.t('noOverviewAvailable'),
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppTheme.grayText,
                height: 1.6,
              ),
            )
          else
            Text(
              _showFullOverview || !isLong
                  ? overview
                  : '${overview.substring(0, 150)}...',
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppTheme.grayText,
                height: 1.6,
              ),
            ),
          if (isLong) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () =>
                  setState(() => _showFullOverview = !_showFullOverview),
              child: Text(
                _showFullOverview ? l10n.t('viewLessArrow') : l10n.t('viewMoreArrow'),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryPinkDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsibilities() {
    final l10n = AppLocalizations.of(context);
    final rawList = _job['responsibilities'];
    final responsibilities = rawList is List
        ? rawList.map((e) => e.toString()).toList()
        : <String>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('responsibilities'),
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          if (responsibilities.isEmpty)
            Text(
              l10n.t('noResponsibilitiesListed'),
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppTheme.grayText,
              ),
            )
          else
            ...responsibilities.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryPink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: AppTheme.charcoal,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleBookmark,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isSaved
                    ? AppTheme.primaryPinkLight
                    : AppTheme.ivoryLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                _isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: _isSaved ? AppTheme.primaryPinkDark : AppTheme.grayText,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    context.push(AppRoutes.applyJobScreen, extra: _job),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  l10n.applyNow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
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
