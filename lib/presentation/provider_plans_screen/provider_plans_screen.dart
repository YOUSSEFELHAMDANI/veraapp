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

class ProviderPlansScreen extends StatefulWidget {
  const ProviderPlansScreen({super.key});

  @override
  State<ProviderPlansScreen> createState() => _ProviderPlansScreenState();
}

class _ProviderPlansScreenState extends State<ProviderPlansScreen>
    with SingleTickerProviderStateMixin, ProviderGuard {
  String _selectedPlanId = 'free';
  bool _isActivating = false;
  bool _isLoadingPlans = true;
  late AnimationController _animController;

  List<_PlanData> _plans = [];

  static final List<List<Color>> _palettes = [
    [AppTheme.tintPink, AppTheme.tintCream],
    [AppTheme.tintYellow, AppTheme.tintCream],
    [AppTheme.tintPink, AppTheme.tintOrangeLight],
  ];
  static const List<IconData> _planIcons = [
    Icons.rocket_launch_outlined,
    Icons.workspace_premium_outlined,
    Icons.diamond_outlined,
  ];

  @override
  void initState() {
    super.initState();
    if (!guardProviderSession()) return;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await VeraApiService.instance.fetchSubscriptionPlans();
    if (!mounted) return;
    setState(() {
      _plans = plans.asMap().entries.map((entry) {
        return _buildPlanData(entry.value, entry.key);
      }).toList();
      _isLoadingPlans = false;
      if (_plans.isNotEmpty && !_plans.any((p) => p.id == _selectedPlanId)) {
        _selectedPlanId = _plans.first.id;
      }
    });
  }

  _PlanData _buildPlanData(VeraSubscriptionPlan plan, int index) {
    final palette = _palettes[index % _palettes.length];
    final icon = _planIcons[index % _planIcons.length];
    final isFree = plan.price <= 0;
    return _PlanData(
      id: plan.id,
      name: plan.name,
      nameAr: plan.name.isNotEmpty ? plan.name : '...',
      price: plan.price,
      period: isFree ? '' : plan.period,
      periodEn: isFree ? '' : plan.period,
      tagline: plan.name,
      taglineEn: plan.name,
      badge: plan.isPopular ? 'mostPopular' : null,
      badgeColor: AppTheme.goldAccent,
      gradientColors: palette,
      iconColor: index == 0 ? AppTheme.primaryPink : AppTheme.goldAccent,
      iconBg: index == 0 ? AppTheme.fashionBg : AppTheme.goldLight,
      icon: icon,
      features: plan.features.map((f) => _Feature(f, f, true)).toList(),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _activatePlan(_PlanData plan) async {
    if (plan.price <= 0) {
      _showConfirmDialog(plan);
      return;
    }
    _showConfirmDialog(plan);
  }

  void _showConfirmDialog(_PlanData plan) {
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
                  gradient: LinearGradient(colors: plan.gradientColors),
                  shape: BoxShape.circle,
                ),
                child: Icon(plan.icon, color: plan.iconColor, size: 30),
              ),
              SizedBox(height: 2.h),
              Text(
                plan.price <= 0
                    ? l10n.t('activateFreePlan')
                    : l10n.t('subscribeToPlan', args: {'name': plan.nameAr}),
                style: GoogleFonts.cairo(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                plan.price <= 0
                    ? l10n.t('freePlanDesc')
                    : l10n.t('paidPlanDesc', args: {'amount': plan.price.toStringAsFixed(0)}),
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: AppTheme.grayText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.5.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _processPlanActivation(plan);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: plan.price <= 0
                            ? AppTheme.success
                            : AppTheme.goldAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        elevation: 0,
                      ),
                      child: Text(
                        plan.price <= 0 ? l10n.t('activateShort') : l10n.submit,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
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
    );
  }

  Future<void> _processPlanActivation(_PlanData plan) async {
    setState(() => _isActivating = true);
    final result = await VeraApiService.instance.subscribeToPlan(plan.id);
    if (!mounted) return;
    setState(() {
      _selectedPlanId = plan.id;
      _isActivating = false;
    });
    if (result != null) {
      final checkoutUrl = result['checkout_url']?.toString();
      final demo = result['demo'] == true;
      final pending = result['pending'] == true;
      if (checkoutUrl != null &&
          checkoutUrl.isNotEmpty &&
          !demo &&
          plan.price > 0) {
        try {
          await launchUrl(
            Uri.parse(checkoutUrl),
            mode: LaunchMode.externalApplication,
          );
          if (mounted) _showPaymentPendingSnack();
        } catch (_) {
          if (mounted) _showSuccessSnack(plan);
        }
      } else if (pending) {
        if (mounted) _showPaymentPendingSnack();
      } else {
        _showSuccessSnack(plan);
      }
    } else {
      _showErrorSnack();
    }
  }

  void _showErrorSnack() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                l10n.t('errorSubscribe'),
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showSuccessSnack(_PlanData plan) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                plan.price <= 0
                    ? l10n.t('freePlanActivated')
                    : l10n.t('planSubscribed', args: {'name': plan.nameAr}),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showPaymentPendingSnack() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.payment_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                l10n.t('paymentPending'),
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryPinkDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(l10n),
            Expanded(
              child: _isActivating
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldAccent,
                      ),
                    )
                  : _isLoadingPlans
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldAccent,
                      ),
                    )
                  : _plans.isEmpty
                  ? _buildEmptyState(l10n)
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroSection(l10n),
                          SizedBox(height: 3.h),
                          _buildCurrentPlanBanner(l10n),
                          SizedBox(height: 2.5.h),
                          ..._plans.asMap().entries.map(
                            (entry) => _buildPlanCard(entry.value, entry.key, l10n),
                          ),
                          SizedBox(height: 2.h),
                          _buildComparisonNote(l10n),
                          SizedBox(height: 3.h),
                        ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: const BoxDecoration(
                color: AppTheme.goldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: AppTheme.goldAccent,
                size: 32,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.t('noPlansAvailable'),
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              l10n.t('tryAgainLater'),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 11.sp,
                color: AppTheme.grayText,
              ),
            ),
            SizedBox(height: 2.h),
            OutlinedButton(
              onPressed: () {
                setState(() => _isLoadingPlans = true);
                _loadPlans();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.goldAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.2.h),
              ),
              child: Text(
                l10n.retry,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRoutes.providerDashboardScreen),
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('providerPlans'),
                  style: GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l10n.t('providerPlans'),
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
            decoration: BoxDecoration(
              color: AppTheme.goldLight,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              _plans.isEmpty
                  ? ''
                  : _selectedPlanId == 'free'
                  ? l10n.t('free')
                  : _plans.firstWhere((p) => p.id == _selectedPlanId).nameAr,
              style: GoogleFonts.cairo(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.tintYellow, AppTheme.tintCream, AppTheme.tintPink],
        ),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppTheme.goldLight),
      ),
      child: Row(
        children: [
          Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: const Icon(
              Icons.layers_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('chooseRightPlan'),
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  l10n.t('startFreeUpgrade'),
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppTheme.grayText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBanner(AppLocalizations l10n) {
    if (_plans.isEmpty) return const SizedBox.shrink();
    final current = _plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => _plans.first,
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: current.iconBg,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(current.icon, color: current.iconColor, size: 18),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('yourCurrentPlan'),
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppTheme.grayText,
                  ),
                ),
                Text(
                  l10n.t('planLabel', args: {'name': current.nameAr}),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: current.id == 'free'
                  ? AppTheme.tintGreen
                  : AppTheme.goldLight,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              current.id == 'free' ? l10n.t('free') : l10n.t('active'),
              style: GoogleFonts.cairo(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: current.id == 'free'
                    ? AppTheme.success
                    : AppTheme.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(_PlanData plan, int index, AppLocalizations l10n) {
    final isSelected = _selectedPlanId == plan.id;
    final isPopular = plan.badge != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isSelected
              ? AppTheme.goldAccent
              : (isPopular ? AppTheme.goldLight : AppTheme.borderLight),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.goldAccent.withAlpha(50),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Badge row
          if (plan.badge != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              decoration: BoxDecoration(
                color: plan.badgeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  '\u2B50 ${l10n.t(plan.badge!)}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Card header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: plan.gradientColors,
              ),
              borderRadius: plan.badge != null
                  ? BorderRadius.zero
                  : const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: plan.iconBg,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(plan.icon, color: plan.iconColor, size: 24),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: Text(
                              plan.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Flexible(
                            flex: 2,
                            child: Text(
                              '(${plan.name})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11.sp,
                                color: AppTheme.grayText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        plan.tagline,
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    plan.price == 0
                        ? Text(
                            l10n.t('free'),
                            style: GoogleFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.success,
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'AED',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.goldAccent,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${plan.price}',
                                style: GoogleFonts.cairo(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.goldAccent,
                                ),
                              ),
                            ],
                          ),
                    Text(
                      plan.price == 0 ? l10n.t('free') : plan.period,
                      style: GoogleFonts.cairo(
                        fontSize: 9.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Features list
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
            child: Column(
              children: plan.features.map((f) => _buildFeatureRow(f)).toList(),
            ),
          ),
          // CTA button
          Padding(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              height: 5.5.h,
              child: isSelected
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 18,
                      ),
                      label: Text(
                        l10n.t('yourCurrentPlanLabel'),
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppTheme.success,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _activatePlan(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: plan.price == 0
                            ? AppTheme.success
                            : AppTheme.goldAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        plan.price == 0 ? l10n.t('activateFree') : l10n.t('subscribeNow'),
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_Feature feature) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(
            feature.included
                ? Icons.check_circle_rounded
                : Icons.cancel_outlined,
            color: feature.included ? AppTheme.success : AppTheme.grayLight,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              feature.labelAr,
              style: GoogleFonts.cairo(
                fontSize: 11.sp,
                color: feature.included
                    ? AppTheme.charcoal
                    : AppTheme.grayLight,
                decoration: feature.included
                    ? null
                    : TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonNote(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.goldAccent,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('note'),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  l10n.t('planUpgradeNote'),
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
    );
  }
}

class _PlanData {
  final String id;
  final String name;
  final String nameAr;
  final double price;
  final String period;
  final String periodEn;
  final String tagline;
  final String taglineEn;
  final String? badge;
  final Color? badgeColor;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;
  final List<_Feature> features;

  const _PlanData({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.price,
    required this.period,
    required this.periodEn,
    required this.tagline,
    required this.taglineEn,
    required this.badge,
    required this.badgeColor,
    required this.gradientColors,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
    required this.features,
  });
}

class _Feature {
  final String labelAr;
  final String labelEn;
  final bool included;

  const _Feature(this.labelAr, this.labelEn, this.included);
}

