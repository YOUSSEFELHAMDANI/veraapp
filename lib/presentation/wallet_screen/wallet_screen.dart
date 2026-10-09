import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with AuthGuard {
  bool _isLoading = true;
  double _balance = 0;
  String _currency = 'AED';
  List<VeraWalletTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final wallet = await VeraApiService.instance.fetchWallet();
    if (!mounted) return;
    setState(() {
      _balance = wallet?.balance ?? 0;
      _currency = wallet?.currency ?? 'AED';
      _transactions = wallet?.transactions ?? [];
      _isLoading = false;
    });
  }

  Future<void> _showTopUpDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: '50');
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.topUp,
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.cairo(fontSize: 15.sp, color: AppTheme.charcoal),
          decoration: InputDecoration(
            labelText: l10n.topUpAmount,
            labelStyle: GoogleFonts.cairo(color: AppTheme.grayText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderLight),
            ),
          ),
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
                .pop(double.tryParse(controller.text.trim()) ?? 0),
            child: Text(
              l10n.confirm,
              style: GoogleFonts.cairo(
                color: AppTheme.primaryPinkDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    if (amount < 1) {
      _showMessage(l10n.topUpMinError, AppTheme.warning);
      return;
    }
    await _doTopUp(amount);
  }

  Future<void> _doTopUp(double amount) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    final result = await VeraApiService.instance
        .topUpWallet(amount: amount, paymentMethod: 'wallet');
    if (!mounted) return;
    setState(() => _isLoading = false);

    final url = result?['url']?.toString() ?? '';
    if (url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
    if (result != null &&
        (result['success'] == true ||
            result['demo'] == true ||
            result['paid'] == true)) {
      _showMessage(l10n.topUpSuccess, AppTheme.success);
      await _load();
    } else {
      _showMessage(l10n.topUpFailed, AppTheme.error);
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

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _txLabel(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'topup':
      case 'credit':
      case 'refund':
        return l10n.t('topup');
      case 'debit':
      case 'payment':
      case 'purchase':
        return l10n.t('paid');
      default:
        return type;
    }
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
          l10n.walletTitle,
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
                  _buildBalanceCard(l10n),
                  SizedBox(height: 2.h),
                  _buildTopUpButton(l10n),
                  SizedBox(height: 3.h),
                  _buildSectionTitle(l10n),
                  SizedBox(height: 1.h),
                  if (_transactions.isEmpty)
                    _buildEmptyState(l10n)
                  else
                    ..._transactions.map((t) => _buildTxTile(t, l10n)),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8A96A), Color(0xFFEFA9B8)],
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
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  l10n.walletBalanceTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '$_currency ${_formatAmount(_balance)}',
            style: GoogleFonts.cairo(
              fontSize: 30.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            l10n.payWithWalletTitle,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpButton(AppLocalizations l10n) {
    return InkWell(
      onTap: _showTopUpDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.6.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryPinkDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: Colors.white, size: 20.sp),
            SizedBox(width: 2.w),
            Text(
              l10n.topUp,
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
            'assets/icons/empty_wallet.svg',
            width: 20.w,
            height: 20.w,
            placeholderBuilder: (_) => Icon(
              Icons.wallet_outlined,
              size: 60.sp,
              color: AppTheme.grayLight,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.walletNoTransactions,
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

  Widget _buildTxTile(VeraWalletTransaction t, AppLocalizations l10n) {
    final isCredit = t.type.toLowerCase() == 'credit' ||
        t.type.toLowerCase() == 'topup' ||
        t.type.toLowerCase() == 'refund';
    final color = isCredit ? AppTheme.success : AppTheme.error;
    final icon = isCredit
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
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
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description.isNotEmpty
                      ? t.description
                      : _txLabel(t.type, l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (t.createdAt.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    t.createdAt,
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
            '${isCredit ? '+' : '-'}$_currency ${_formatAmount(t.amount)}',
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
