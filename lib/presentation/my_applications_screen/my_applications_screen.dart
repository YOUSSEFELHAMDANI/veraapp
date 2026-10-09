import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin, AuthGuard {
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Applied', 'Under Review', 'Shortlisted'];

  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apps = await VeraApiService.instance.fetchApplications();
      if (!mounted) return;
      setState(() {
        _applications = apps.map(_appToMap).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'errorLoadApplications';
      });
    }
  }

  Map<String, dynamic> _appToMap(Map<String, dynamic> a) {
    final job = a['job'] is Map ? a['job'] as Map : null;
    final title = job?['title']?.toString() ??
        job?['job_title']?.toString() ??
        a['title']?.toString() ??
        a['job_title']?.toString() ??
        '';
    final companyRaw = a['company'] ?? job?['company'] ?? a['company_name'] ?? '';
    final companyName =
        companyRaw is Map ? (companyRaw['name'] ?? '').toString() : companyRaw.toString();
    final location = a['location']?.toString() ??
        a['city']?.toString() ??
        job?['location']?.toString() ??
        job?['city']?.toString() ??
        '';
    final logo = a['logo']?.toString() ??
        a['company_logo']?.toString() ??
        job?['logo']?.toString() ??
        a['image']?.toString() ??
        '';
    final appliedAt = a['applied_at']?.toString() ??
        a['applied_date']?.toString() ??
        a['date']?.toString() ??
        '';
    return {
      'title': title,
      'company': companyName,
      'location': location,
      'appliedDateRaw': appliedAt,
      'status': _displayStatus(a['status']?.toString() ?? ''),
      'logo': logo,
    };
  }

  String _displayStatus(String status) {
    final s = status
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (s == 'under review' || s == 'in review') return 'Under Review';
    if (s == 'shortlisted' || s == 'short listed') return 'Shortlisted';
    if (s == 'rejected') return 'Rejected';
    if (s == 'applied' || s == 'submitted') return 'Applied';
    if (s.isEmpty) return 'Applied';
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredApplications(String tab) {
    if (tab == 'All') return _applications;
    return _applications.where((a) => a['status'] == tab).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Applied':
        return const Color(0xFF5DADE2);
      case 'Under Review':
        return AppTheme.warning;
      case 'Shortlisted':
        return AppTheme.success;
      case 'Rejected':
        return AppTheme.error;
      default:
        return AppTheme.grayText;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'Applied':
        return AppTheme.tintBlue;
      case 'Under Review':
        return AppTheme.tintAmber;
      case 'Shortlisted':
        return AppTheme.tintGreen;
      case 'Rejected':
        return AppTheme.tintRed;
      default:
        return AppTheme.ivoryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabLabels = {
      'All': l10n.allLabel,
      'Applied': l10n.t('applied'),
      'Under Review': l10n.t('underReview'),
      'Shortlisted': l10n.t('shortlisted'),
    };
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppTheme.charcoal,
            ),
          ),
        ),
        title: Text(
          l10n.myApplications,
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: AppTheme.ivoryLight,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: AppTheme.primaryPink,
                borderRadius: BorderRadius.circular(10.0),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.grayText,
              labelStyle: GoogleFonts.cairo(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.cairo(
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
              padding: const EdgeInsets.all(4),
              tabs: _tabs
                  .map((t) => Tab(text: tabLabels[t] ?? t, height: 36))
                  .toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(l10n)
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    final apps = _filteredApplications(tab);
                    if (apps.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off_outlined,
                              size: 56,
                              color: AppTheme.grayLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('noApplicationsYet'),
                              style: GoogleFonts.cairo(
                                fontSize: 14.sp,
                                color: AppTheme.grayText,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 100),
                      itemCount: apps.length,
                      itemBuilder: (context, index) =>
                          _buildApplicationCard(apps[index], l10n),
                    );
                  }).toList(),
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
              l10n.t(_error!),
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

  Widget _buildApplicationCard(
      Map<String, dynamic> app, AppLocalizations l10n) {
    final status = app['status'] as String;
    final statusDisplay = _localizedStatus(status, l10n);
    final appliedDateRaw = app['appliedDateRaw'] as String? ?? '';
    return GestureDetector(
      onTap: () => context.push(AppRoutes.jobDetailsScreen, extra: app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: CustomImageWidget(
                imageUrl: app['logo'] as String,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                semanticLabel: l10n.companyLogoLabel(app['company'] as String),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${app['company']} – ${app['location']}',
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppTheme.grayText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (appliedDateRaw.isNotEmpty)
                    Text(
                      l10n.t('appliedOn', args: {'date': appliedDateRaw}),
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: AppTheme.grayLight,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBgColor(status),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      statusDisplay,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.grayText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _localizedStatus(String status, AppLocalizations l10n) {
    switch (status) {
      case 'Applied':
        return l10n.t('applied');
      case 'Under Review':
        return l10n.t('underReview');
      case 'Shortlisted':
        return l10n.t('shortlisted');
      case 'Rejected':
        return l10n.t('rejected');
      default:
        return status;
    }
  }
}
