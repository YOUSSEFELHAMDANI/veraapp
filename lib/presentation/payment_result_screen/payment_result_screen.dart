import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({
    super.key,
    this.kind = 'order',
    this.status = 'success',
    this.orderId,
    this.planId,
    this.provider,
  });

  final String kind;
  final String status;
  final String? orderId;
  final String? planId;
  final String? provider;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _verified = false;

  bool get isSuccess => widget.status != 'cancelled' && _verified;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (widget.kind == 'order' && widget.status == 'success') {
      final orderId = widget.orderId;
      if (orderId != null && orderId.isNotEmpty) {
        final order = await VeraApiService.instance.fetchPublicOrder(orderId);
        if (mounted) {
          setState(() {
            _order = order;
            _verified = order != null && ['paid', 'authorized', 'completed', 'confirmed', 'shipped'].contains(order['payment_status']?.toString().toLowerCase());
            _loading = false;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 20),
                    Text(
                      _title(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppTheme.grayText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isOrderSuccess()) ..._buildOrderCard(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  bool _isOrderSuccess() =>
      widget.kind == 'order' && widget.status == 'success';

  bool get _isBookingOrder {
    final order = _order;
    if (order == null) return false;
    final orderType = order['order_type']?.toString() ?? '';
    if (orderType.toLowerCase() == 'book' ||
        orderType.toLowerCase() == 'booking') {
      return true;
    }
    final items = order['items'];
    if (items is List) {
      for (final item in items) {
        if (item is Map &&
            (item['booking_id'] != null ||
                (item['type']?.toString().toLowerCase() == 'service'))) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildIcon() {
    final isSuccess = this.isSuccess;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: isSuccess
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.success, Color(0xFF2FB04F)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.warning, Color(0xFFF0A11C)],
              ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? AppTheme.success : AppTheme.warning)
                .withAlpha(77),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        isSuccess ? Icons.check_rounded : Icons.close_rounded,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  String _title() {
    final cancelled = widget.status == 'cancelled';
    if (widget.kind == 'subscription') {
      return isSuccess ? 'تم تفعيل اشتراكك بنجاح!' : cancelled ? 'تم إلغاء الاشتراك' : 'جاري التحقق من الدفع';
    }
    return isSuccess ? 'شكراً لك! تم تأكيد طلبك' : cancelled ? 'تم إلغاء الدفع' : 'جاري التحقق من الدفع';
  }

  String _subtitle() {
    final cancelled = widget.status == 'cancelled';
    if (widget.kind == 'subscription') {
      return isSuccess
          ? 'شكراً لك! تم تفعيل اشتراكك وسيتم تطبيقه فوراً على حسابك.'
          : cancelled ? 'لم يتم إتمام الدفع. يمكنك إعادة المحاولة في أي وقت.' : 'لم يؤكد الخادم الدفع بعد. لا تغلق الصفحة حتى يتم التحقق.';
    }
    return isSuccess
        ? 'تم استلام طلبك بنجاح وسيتم تجهيزه قريباً.'
        : cancelled ? 'لم يتم إتمام الدفع. يمكنك إكمال الدفع لاحقاً من صفحة الطلبات.' : 'لم يؤكد الخادم الدفع بعد. سيتم تحديث الحالة تلقائياً.';
  }

  List<Widget> _buildOrderCard() {
    final orderId = widget.orderId ?? '—';
    final order = _order;
    final total = order?['total_amount']?.toString() ??
        order?['total']?.toString() ??
        '';
    final paymentStatus = order?['payment_status']?.toString() ?? '';

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            _infoRow(
              icon: Icons.receipt_long_outlined,
              label: 'رقم الطلب',
              value: orderId,
              isBold: true,
            ),
            if (paymentStatus.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppTheme.borderLight),
              ),
              _infoRow(
                icon: Icons.verified_outlined,
                label: 'حالة الدفع',
                value: paymentStatus == 'paid' ||
                        paymentStatus == 'confirmed' ||
                        paymentStatus == 'completed'
                    ? 'مدفوع'
                    : 'قيد التأكيد',
                isBold: false,
              ),
            ],
            if (total.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppTheme.borderLight),
              ),
              _infoRow(
                icon: Icons.payments_outlined,
                label: 'الإجمالي',
                value: '$total AED',
                isBold: true,
              ),
            ],
          ],
        ),
      ),
      if (_loading) ...[
        const SizedBox(height: 16),
        const CircularProgressIndicator(
          color: AppTheme.primaryPinkDark,
          strokeWidth: 2.5,
        ),
      ],
    ];
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isBold,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.grayText, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppTheme.grayText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: _isOrderSuccess()
              ? [
                  _primaryButton('العودة للرئيسية', () {
                    context.go(AppRoutes.homeScreen);
                  }),
                  const SizedBox(height: 10),
                  _secondaryButton(
                    _isBookingOrder ? 'عرض الحجوزات' : 'عرض الطلبات',
                    () {
                      context.go(
                        _isBookingOrder
                            ? AppRoutes.myAppointmentsScreen
                            : AppRoutes.myOrdersScreen,
                      );
                    },
                  ),
                ]
              : widget.kind == 'subscription'
                  ? [
                      _primaryButton(
                        isSuccess ? 'الذهاب للوحة التحكم' : 'الذهاب للاشتراكات',
                        () {
                          context.go(
                            isSuccess
                                ? AppRoutes.providerDashboardScreen
                                : AppRoutes.providerSubscriptionsScreen,
                          );
                        },
                      ),
                    ]
                  : [
                      _primaryButton('العودة للرئيسية', () {
                        context.go(AppRoutes.homeScreen);
                      }),
                      const SizedBox(height: 10),
                      _secondaryButton('إعادة المحاولة', () {
                        context.go(AppRoutes.cartAndCheckoutScreen);
                      }),
                    ],
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPinkDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryPinkDark,
          side: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
