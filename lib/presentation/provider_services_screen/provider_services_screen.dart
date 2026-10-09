import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen>
    with ProviderGuard {
  List<VeraService> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!guardProviderSession()) return;
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final services = await VeraApiService.instance.fetchProviderOwnServices();
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddServiceWizard() {
    context.push(AppRoutes.providerServiceWizardScreen).then((_) => _loadServices());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go(AppRoutes.providerDashboardScreen),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppTheme.charcoal,
          ),
        ),
        title: Text(
          l10n.t('myServices'),
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: GestureDetector(
              onTap: _showAddServiceWizard,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      l10n.t('add'),
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadServices,
        color: AppTheme.goldAccent,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldAccent),
              )
            : _services.isEmpty
            ? _buildEmptyState(l10n)
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                itemCount: _services.length,
                itemBuilder: (_, i) => _buildServiceCard(_services[i], l10n),
              ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.goldLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.design_services_outlined,
              color: AppTheme.goldAccent,
              size: 36,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.t('noServicesYet'),
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.t('addFirstService'),
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          GestureDetector(
            onTap: _showAddServiceWizard,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                l10n.addService,
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
    );
  }

  Widget _buildServiceCard(VeraService service, AppLocalizations l10n) {
    final statusLower = service.status.toLowerCase();
    final statusColor = statusLower.contains('approved') || statusLower.contains('publish') ? AppTheme.success : statusLower.contains('reject') ? AppTheme.error : AppTheme.warning;
    final statusLabel = statusLower.contains('approved') || statusLower.contains('publish') ? l10n.t('approved') : statusLower.contains('reject') ? l10n.t('rejected') : l10n.t('pendingApproval');
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: service.imageUrl.isNotEmpty
                ? CustomImageWidget(
                    imageUrl: service.imageUrl,
                    width: 22.w,
                    height: 22.w,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.serviceImageLabel(service.name),
                  )
                : Container(
                    width: 22.w,
                    height: 22.w,
                    color: AppTheme.goldLight,
                    child: const Icon(
                      Icons.design_services_outlined,
                      color: AppTheme.goldAccent,
                      size: 28,
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    service.category,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                   Wrap(
                     alignment: WrapAlignment.spaceBetween,
                     crossAxisAlignment: WrapCrossAlignment.center,
                     spacing: 8,
                     runSpacing: 2,
                     children: [
                      Text(
                        'AED ${service.price.toStringAsFixed(0)}',
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                        child: Text(statusLabel, style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                       Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB547),
                            size: 14,
                          ),
                          SizedBox(width: 0.5.w),
                          Text(
                            service.rating.toStringAsFixed(1),
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppTheme.grayText,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              onSelected: (val) {
                if (val == 'edit') _editService(service);
                if (val == 'delete') _deleteService(service);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.charcoal,
                      ),
                      SizedBox(width: 2.w),
                      Text(l10n.edit, style: GoogleFonts.cairo(fontSize: 12.sp)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                      SizedBox(width: 2.w),
                      Text(l10n.delete, style: GoogleFonts.cairo(fontSize: 12.sp, color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editService(VeraService service) {
    context.push(AppRoutes.providerServiceWizardScreen, extra: service.toDetailsMap()).then((_) => _loadServices());
  }

  void _deleteService(VeraService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).t('delete'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('${AppLocalizations.of(ctx).t('delete')} "${service.name}"?', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(ctx).t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(ctx).t('delete'), style: const TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await VeraApiService.instance.deleteProviderService(service.id.toString());
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service deleted')));
      _loadServices();
    }
  }
}

