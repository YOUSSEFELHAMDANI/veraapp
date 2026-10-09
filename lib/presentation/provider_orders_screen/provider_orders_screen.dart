import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class ProviderOrdersScreen extends StatefulWidget {
  const ProviderOrdersScreen({super.key});

  @override
  State<ProviderOrdersScreen> createState() => _ProviderOrdersScreenState();
}

class _ProviderOrdersScreenState extends State<ProviderOrdersScreen>
    with ProviderGuard {
  List<VeraOrder> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusTabs = [
    {'key': 'all', 'label': ''},
    {'key': 'pending', 'label': ''},
    {'key': 'processing', 'label': ''},
    {'key': 'completed', 'label': ''},
    {'key': 'cancelled', 'label': ''},
  ];

  @override
  void initState() {
    super.initState();
    if (!guardProviderSession()) return;
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await VeraApiService.instance.fetchProviderOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
          l10n.t('myOrders'),
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatusTabs(l10n),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppTheme.goldAccent,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldAccent,
                      ),
                    )
                  : _orders.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      itemCount: _orders.length,
                      itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(AppLocalizations l10n) {
    final labelMap = {
      'all': l10n.t('all'),
      'pending': l10n.pending,
      'processing': l10n.t('processing'),
      'completed': l10n.completed,
      'cancelled': l10n.cancelled,
    };
    return Container(
      height: 6.h,
      color: AppTheme.backgroundLight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        itemCount: _statusTabs.length,
        itemBuilder: (_, i) {
          final tab = _statusTabs[i];
          final isSelected = _selectedStatus == tab['key'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedStatus = tab['key']!);
              _loadOrders();
            },
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldAccent : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldAccent
                      : AppTheme.borderLight,
                ),
              ),
              child: Text(
                labelMap[tab['key']] ?? tab['key']!,
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.grayText,
                ),
              ),
            ),
          );
        },
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
              color: AppTheme.ivoryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.goldAccent,
              size: 36,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.t('noOrdersFound'),
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            l10n.t('ordersAppearHere'),
            style: GoogleFonts.cairo(
              fontSize: 11.sp,
              color: AppTheme.grayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(VeraOrder order) {
    final l10n = AppLocalizations.of(context);
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (order.status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        statusColor = AppTheme.success;
        statusBg = AppTheme.tintGreen;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusBg = AppTheme.tintAmber;
        statusIcon = Icons.access_time_rounded;
        break;
      case 'processing':
        statusColor = AppTheme.info;
        statusBg = AppTheme.tintBlueSoft;
        statusIcon = Icons.autorenew_rounded;
        break;
      case 'cancelled':
        statusColor = AppTheme.error;
        statusBg = AppTheme.tintRed;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppTheme.grayText;
        statusBg = AppTheme.ivoryLight;
        statusIcon = Icons.info_outline_rounded;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  order.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    SizedBox(width: 1.w),
                    Text(
                      order.status,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.itemNames.isNotEmpty) ...[
            SizedBox(height: 0.8.h),
            Text(
              order.itemNames.join(', '),
              style: GoogleFonts.cairo(
                fontSize: 11.sp,
                color: AppTheme.grayText,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (order.date.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppTheme.grayText,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      order.date.length > 10
                          ? order.date.substring(0, 10)
                          : order.date,
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),
              Text(
                'AED ${order.total.toStringAsFixed(2)}',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldAccent,
                ),
              ),
            ],
          ),
          if (order.trackingNumber.isNotEmpty) ...[
            SizedBox(height: 0.8.h),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 12,
                  color: AppTheme.grayText,
                ),
                SizedBox(width: 1.w),
                Text(
                  l10n.t('tracking', args: {'number': order.trackingNumber}),
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
