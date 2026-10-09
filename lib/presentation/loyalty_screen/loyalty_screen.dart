import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> with AuthGuard {
  bool _isLoading = true;
  int _points = 0;
  String _level = 'bronze';
  List<Map<String, dynamic>> _history = [];
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final loyalty = await VeraApiService.instance.fetchLoyalty();
    if (!mounted) return;
    setState(() {
      _points = loyalty?.points ?? 0;
      _level = loyalty?.tier.toLowerCase() ?? 'bronze';
      _history = loyalty?.history ?? [];
      _isLoading = false;
    });
  }

  String _levelLabel(AppLocalizations l10n) {
    switch (_level) {
      case 'silver':
        return l10n.silverLevel;
      case 'gold':
        return l10n.goldLevel;
      default:
        return l10n.bronzeLevel;
    }
  }

  Future<void> _showRedeemDialog() async {
    final l10n = AppLocalizations.of(context);
    if (_points <= 0) {
      _showMessage(l10n.redeemBalanceError, AppTheme.warning);
      return;
    }
    final controller = TextEditingController(text: '$_points');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.redeemTitle,
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.redeemSubtitle,
              style: GoogleFonts.cairo(fontSize: 12.sp, color: AppTheme.grayText),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(fontSize: 15.sp, color: AppTheme.charcoal),
              decoration: InputDecoration(
                labelText: l10n.loyaltyBalance,
                labelStyle: GoogleFonts.cairo(color: AppTheme.grayText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderLight),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '$_points ${l10n.pointsAbbr} ${l10n.t('available').toLowerCase()}',
              style: GoogleFonts.cairo(fontSize: 11.sp, color: AppTheme.grayText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.cairo(color: AppTheme.grayText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(int.tryParse(controller.text.trim()) ?? 0),
            child: Text(
              l10n.redeemNow,
              style: GoogleFonts.cairo(
                color: AppTheme.primaryPinkDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (value == null || value <= 0) return;
    await _doRedeem(value);
  }

  Future<void> _doRedeem(int points) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _redeeming = true);
    final result = await VeraApiService.instance.redeemLoyaltyPoints(points: points);
    if (!mounted) return;
    setState(() => _redeeming = false);

    if (result == null) {
      _showMessage(l10n.somethingWentWrong, AppTheme.error);
      return;
    }
    if (result['success'] == true) {
      _showMessage(l10n.redeemSuccess, AppTheme.success);
      await _load();
    } else {
      final error = result['error']?.toString() ?? '';
      _showMessage(error.isNotEmpty ? error : l10n.redeemBalanceError, AppTheme.warning);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          l10n.loyaltyTitle,
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppTheme.primaryPinkDark,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                children: [
                  _buildPointsCard(l10n),
                  SizedBox(height: 2.h),
                  _buildRedeemButton(l10n),
                  SizedBox(height: 3.h),
                  _buildSectionTitle(l10n),
                  SizedBox(height: 1.h),
                  if (_history.isEmpty)
                    _buildEmptyState(l10n)
                  else
                    ..._history.map((h) => _buildHistoryTile(h, l10n)),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsCard(AppLocalizations l10n) {
    final isGold = _level == 'gold';
    final isSilver = _level == 'silver';
    final List<Color> gradient = isGold
        ? const [Color(0xFFC8A96A), Color(0xFFE8D5A3)]
        : isSilver
            ? const [Color(0xFF9AA5B1), Color(0xFFD5DEE6)]
            : const [Color(0xFFC08B5C), Color(0xFFEFA9B8)];
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPinkLight.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGold
                      ? Icons.workspace_premium_rounded
                      : isSilver
                          ? Icons.military_tech_rounded
                          : Icons.stars_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  l10n.loyaltyBalance,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${l10n.yourLevel}: ${_levelLabel(l10n)}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '$_points',
            style: GoogleFonts.cairo(
              fontSize: 34.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            l10n.points,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemButton(AppLocalizations l10n) {
    return InkWell(
      onTap: _redeeming ? null : _showRedeemDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.6.h),
        decoration: BoxDecoration(
          color: _redeeming ? AppTheme.grayLight : AppTheme.primaryPinkDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_redeeming)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 20.sp),
            SizedBox(width: 2.w),
            Text(
              l10n.redeemNow,
              style: GoogleFonts.cairo(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(AppLocalizations l10n) {
    return Text(
      l10n.activityHistory,
      style: GoogleFonts.cairo(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.charcoal,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/empty_points.svg',
            width: 20.w,
            height: 20.w,
            placeholderBuilder: (_) => Icon(
              Icons.stars_outlined,
              size: 60.sp,
              color: AppTheme.grayLight,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.noLoyaltyHistory,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppTheme.grayText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> h, AppLocalizations l10n) {
    final rawType = (h['type'] ?? '').toString().toLowerCase();
    final isEarn = rawType == 'earn' || rawType == 'earned';
    final rawPoints = h['points'];
    final pointsValue =
        rawPoints is num ? rawPoints.toInt() : (int.tryParse('$rawPoints') ?? 0);
    final isPositive = isEarn || pointsValue > 0;
    final color = isPositive ? AppTheme.success : AppTheme.error;
    final label = isPositive ? l10n.earned : l10n.redeemed;
    final description = (h['description'] ?? '').toString();
    final createdAt = (h['created_at'] ?? '').toString();

    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (createdAt.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    createdAt,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${pointsValue.abs()} ${l10n.pointsAbbr}',
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
