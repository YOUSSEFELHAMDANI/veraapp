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

class ProviderSubscriptionsScreen extends StatefulWidget {
  const ProviderSubscriptionsScreen({super.key});

  @override
  State<ProviderSubscriptionsScreen> createState() =>
      _ProviderSubscriptionsScreenState();
}

class _ProviderSubscriptionsScreenState
    extends State<ProviderSubscriptionsScreen> with ProviderGuard {
  List<VeraSubscriptionPlan> _plans = [];
  List<VeraAdPackage> _adPackages = [];
  bool _isLoading = true;
  String? _error;
  String? _purchasingPlanId;
  String? _successPlanId;

  @override
  void initState() {
    super.initState();
    if (!guardProviderSession()) return;
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        VeraApiService.instance.fetchSubscriptionPlans(),
        VeraApiService.instance.fetchAdPackages(),
      ]);
      final plans = results[0] as List<VeraSubscriptionPlan>;
      if (mounted) {
        setState(() {
          _plans = plans;
          _adPackages = results[1] as List<VeraAdPackage>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = l10n.t('errorLoadPlans');
        });
      }
    }
  }

  Future<void> _purchasePlan(VeraSubscriptionPlan plan) async {
    setState(() => _purchasingPlanId = plan.id);
    try {
      final result = await VeraApiService.instance.subscribeToPlan(
        plan.id,
        paymentMethod: 'card',
      );
      if (mounted) {
        if (result != null) {
          final checkoutUrl = result['checkout_url']?.toString();
          final demo = result['demo'] == true;
          final pending = result['pending'] == true;
          setState(() {
            _successPlanId = plan.id;
            _purchasingPlanId = null;
          });
          if (checkoutUrl != null &&
              checkoutUrl.isNotEmpty &&
              !demo &&
              plan.price > 0) {
            try {
              await launchUrl(
                Uri.parse(checkoutUrl),
                mode: LaunchMode.externalApplication,
              );
              if (mounted) _showPendingDialog(plan);
            } catch (_) {
              if (mounted) _showSuccessDialog(plan);
            }
          } else if (pending) {
            _showPendingDialog(plan);
          } else {
            _showSuccessDialog(plan);
          }
        } else {
          setState(() => _purchasingPlanId = null);
          _showErrorSnack();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _purchasingPlanId = null);
        _showErrorSnack();
      }
    }
  }

  void _showPendingDialog(VeraSubscriptionPlan plan) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  color: AppTheme.tintAmber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: AppTheme.goldAccent,
                  size: 40,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.t('completePayment'),
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                l10n.t('completePaymentDesc', args: {'name': plan.name}),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    l10n.t('okay'),
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
      ),
    );
  }

  void _showSuccessDialog(VeraSubscriptionPlan plan) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  color: AppTheme.tintGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 40,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.t('subscribedTitle'),
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                l10n.t('subscribedSuccess', args: {'name': plan.name}),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    l10n.t('great'),
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
      ),
    );
  }

  void _showErrorSnack() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.t('purchaseFailed'),
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
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
              onTap: _loadPlans,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent,
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 48,
              color: AppTheme.grayText,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t('noSubscriptionPlans'),
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                color: AppTheme.grayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadPlans,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent,
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
          l10n.t('adSubscriptionPlans'),
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldAccent),
            )
          : _error != null
              ? _buildError(l10n)
              : _plans.isEmpty && _adPackages.isEmpty
                  ? _buildEmptyState(l10n)
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           _buildHeader(l10n),
                           SizedBox(height: 3.h),
                           if (_adPackages.isNotEmpty) ...[
                             Text('باقات الإعلانات', style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
                             SizedBox(height: 1.5.h),
                             ..._adPackages.map(_buildAdPackageCard),
                             SizedBox(height: 2.h),
                             if (_plans.isNotEmpty) Text('باقات الاشتراك', style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
                           ],
                           ..._plans.map((plan) => _buildPlanCard(plan, l10n)),
                          SizedBox(height: 2.h),
                          _buildBannerPreview(l10n),
                          SizedBox(height: 2.h),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.tintYellow, AppTheme.tintCream],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.goldLight),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.goldLight,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: AppTheme.goldAccent,
              size: 26,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('boostYourVisibility'),
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l10n.t('bannerDesc'),
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(VeraSubscriptionPlan plan, AppLocalizations l10n) {
    final isPurchasing = _purchasingPlanId == plan.id;
    final isSubscribed = _successPlanId == plan.id;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: plan.isPopular ? AppTheme.goldAccent : AppTheme.borderLight,
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: plan.isPopular
            ? [
                BoxShadow(
                  color: AppTheme.goldAccent.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          if (plan.isPopular)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              decoration: const BoxDecoration(
                color: AppTheme.goldAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Text(
                  l10n.t('mostPopularBadge'),
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'AED ${plan.price.toStringAsFixed(0)}',
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldAccent,
                          ),
                        ),
                        Text(
                          '/ ${plan.period}',
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                ...plan.features.map(
                  (f) => Padding(
                    padding: EdgeInsets.only(bottom: 0.8.h),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.success,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.cairo(
                              fontSize: 11.sp,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  height: 5.5.h,
                  child: ElevatedButton(
                    onPressed: isPurchasing || isSubscribed
                        ? null
                        : () => _purchasePlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSubscribed
                          ? AppTheme.success
                          : (plan.isPopular
                                ? AppTheme.goldAccent
                                : AppTheme.charcoal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: isPurchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isSubscribed
                                ? l10n.t('subscribedLabel')
                                : l10n.t('subscribeNowEn'),
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
        ],
      ),
    );
  }

  Widget _buildAdPackageCard(VeraAdPackage plan) {
    return GestureDetector(
      onTap: () => _showAdPackageDetails(plan),
      child: Container(
      margin: EdgeInsets.only(bottom: 1.5.h), padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.goldLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(plan.nameAr.isNotEmpty ? plan.nameAr : plan.name, style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
          Text('${plan.price.toStringAsFixed(0)} AED', style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppTheme.goldAccent)),
        ]),
        SizedBox(height: 1.h),
        Text('${plan.impressionLimit.toString()} ظهور · ${plan.durationDays} أيام · وزن ${plan.packageWeight}', style: GoogleFonts.cairo(fontSize: 10.5.sp, color: AppTheme.grayText)),
        Text('حد التكرار: ${plan.frequencyCap} مرات يوميًا', style: GoogleFonts.cairo(fontSize: 10.5.sp, color: AppTheme.grayText)),
        SizedBox(height: 1.5.h),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => _showAdPackageDetails(plan),
          child: Text('اختيار الباقة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        )),
      ]),
      ),
    );
  }

  void _showAdPackageDetails(VeraAdPackage plan) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(plan.nameAr.isNotEmpty ? plan.nameAr : plan.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('السعر: ${plan.price.toStringAsFixed(0)} AED\nالظهور: ${plan.impressionLimit}\nالمدة: ${plan.durationDays} أيام\nأماكن الظهور: ${plan.placements.join('، ')}', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('إغلاق', style: GoogleFonts.cairo())),
          FilledButton(onPressed: () async {
            Navigator.pop(dialogContext);
            final result = await VeraApiService.instance.purchaseAdPackage(plan.id);
            final checkoutUrl = result?['checkout_url']?.toString();
            if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
              await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إنشاء جلسة الدفع عبر Stripe')));
            }
          }, child: Text('الدفع عبر Stripe', style: GoogleFonts.cairo())),
        ],
      ),
    );
  }

  Widget _buildBannerPreview(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('bannerPreview'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        Container(
          width: double.infinity,
          height: 18.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC8A96A), Color(0xFFEFA9B8)],
            ),
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'AD',
                        style: GoogleFonts.cairo(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      l10n.t('yourBusinessName'),
                      style: GoogleFonts.cairo(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l10n.t('specialOffer'),
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        l10n.t('exploreNow'),
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        Center(
          child: Text(
            l10n.t('bannerAppearance'),
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              color: AppTheme.grayText,
            ),
          ),
        ),
      ],
    );
  }
}
