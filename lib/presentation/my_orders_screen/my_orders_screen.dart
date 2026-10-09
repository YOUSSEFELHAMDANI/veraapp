import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../services/vera_api_service.dart';
import '../../core/auth_gate.dart';
import '../../routes/app_routes.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with AuthGuard {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _trackingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _openTracking() {
    final value = _trackingController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رقم الطلب أو رقم AWB')));
      return;
    }
    context.push('${AppRoutes.orderTrackingScreen}?orderId=${Uri.encodeComponent(value)}');
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orders = await VeraApiService.instance.fetchOrders();
      if (!mounted) return;
      final mapped = orders.map(_orderToMap).toList();
      setState(() {
        _orders = mapped;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orders = [];
        _isLoading = false;
        _error = null;
      });
    }
  }

  Map<String, dynamic> _orderToMap(VeraOrder o) {
    return {
      'rawId': o.id,
      'id': o.orderNumber.isNotEmpty ? o.orderNumber : '#${o.id}',
      'product': o.itemNames.isNotEmpty ? o.itemNames.join(', ') : o.category,
      'brand': o.deliveryProvider,
      'price':
          'AED ${o.total.toStringAsFixed(o.total == o.total.roundToDouble() ? 0 : 2)}',
      'date': o.date,
      'rawStatus': o.status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim(),
      'status': _displayStatus(o.status),
      'statusColor': _colorForStatus(o.status),
      'image': o.imageUrl,
      'isCancelled': _isCancelled(o.status),
      'trackingNumber': o.trackingNumber,
    };
  }

  bool _isCancellable(String status) {
    final s = status.toLowerCase();
    return s.contains('pending') ||
        s.contains('processing') ||
        s.contains('confirmed') ||
        s.contains('booked');
  }

  bool _isCancelled(String status) {
    final s = status.toLowerCase();
    return s.contains('cancel') || s.contains('reject');
  }

  int _stepIndex(String rawStatus) {
    final s = rawStatus.toLowerCase();
    if (s.contains('cancel') || s.contains('reject')) return -1;
    if (s.contains('delivered') || s.contains('completed') || s.contains('done')) return 3;
    if (s.contains('out for')) return 2;
    if (s.contains('transit') || s.contains('shipped')) return 2;
    if (s.contains('confirmed') || s.contains('booked') || s.contains('reserved')) return 1;
    if (s.contains('processing')) return 0;
    return 0;
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('cancelOrder')),
        content: Text(l10n.t('cancelOrderConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.t('yesCancel')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await VeraApiService.instance
        .cancelOrder(order['rawId'] as String? ?? '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.t('orderCancelled') : l10n.t('couldNotCancelOrder'),
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) _load();
  }

  Future<void> _showOrderDetails(Map<String, dynamic> order) async {
    final l10n = AppLocalizations.of(context);
    final rawId = order['rawId'] as String? ?? '';
    final details = rawId.isNotEmpty
        ? await VeraApiService.instance.fetchOrderById(rawId)
        : null;
    if (!mounted) return;
    final tracking = details?.trackingNumber ?? '';
    final delivery = details?.deliveryProvider ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('orderNumberLabel', args: {'number': order['id'] as String}),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 14),
              _detailRow(l10n.t('statusLabel'), l10n.localizeStatus(order['status'] as String)),
              _detailRow(l10n.date, order['date'] as String),
              _detailRow(l10n.total, l10n.localizePrice(order['price'] as String)),
              _detailRow(
                l10n.t('tracking'),
                tracking.isNotEmpty ? tracking : l10n.t('notAvailable'),
              ),
               _detailRow(
                 l10n.t('delivery'),
                 delivery.isNotEmpty ? delivery : l10n.t('notAvailable'),
               ),
              if (tracking.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () { Navigator.pop(ctx); context.push('${AppRoutes.orderTrackingScreen}?orderId=${Uri.encodeComponent(rawId)}'); },
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: Text('تتبع الشحنة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 13, color: Theme.of(context).hintColor)),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color)),
        ],
      ),
    );
  }

  String _displayStatus(String status) {
    final s = status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (s.isEmpty) return 'Processing';
    return s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  int _colorForStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('delivered') || s.contains('completed') || s.contains('done')) return 0xFF34C759;
    if (s.contains('transit') || s.contains('shipped') || s.contains('out for')) return 0xFF5DADE2;
    if (s.contains('processing') || s.contains('pending') || s.contains('confirmed')) return 0xFFC8A96A;
    if (s.contains('cancel')) return 0xFFFF5C5C;
    return 0xFF8A8A8A;
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildTrackingLookup(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError(l10n)
                      : _orders.isEmpty
                          ? _buildEmpty(l10n)
                          : _buildOrderList(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingLookup() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF211044), Color(0xFF4A2378)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_shipping_outlined, color: Colors.white),
          const SizedBox(width: 8),
          Text('تتبع شحنتك', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 5),
        Text('أدخل رقم الطلب أو رقم AWB لمتابعة الشحنة مباشرة', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _trackingController, textDirection: TextDirection.ltr, onSubmitted: (_) => _openTracking(), style: GoogleFonts.cairo(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: 'مثال: 1000027541091', hintStyle: GoogleFonts.cairo(color: Colors.white54, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11)))),
          const SizedBox(width: 8),
          FilledButton(onPressed: _openTracking, style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryPink, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('تتبع', style: GoogleFonts.cairo(fontWeight: FontWeight.w700))),
        ]),
      ]),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myOrders,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l10n.t('savedItemsCount', args: {'count': '${_orders.length}'}),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.grayText),
            const SizedBox(height: 12),
            Text(l10n.t(_error!),
                style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPinkDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l10n.retry,
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.grayLight),
          const SizedBox(height: 12),
          Text(l10n.t('noOrdersYet'),
              style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.grayText)),
        ],
      ),
    );
  }

  Widget _buildOrderList(AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _OrderCard(
        order: _orders[i],
        l10n: l10n,
        isCancellable: _isCancellable(_orders[i]['rawStatus'] as String),
        onCancel: () => _cancelOrder(_orders[i]),
        onTap: () => _showOrderDetails(_orders[i]),
        stepIndex: _stepIndex(_orders[i]['rawStatus'] as String),
            isCancelled: _orders[i]['isCancelled'] as bool,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ORDER CARD WITH STEPPER
// ══════════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final AppLocalizations l10n;
  final bool isCancellable;
  final VoidCallback onCancel;
  final VoidCallback onTap;
  final int stepIndex;
  final bool isCancelled;

  const _OrderCard({
    required this.order,
    required this.l10n,
    required this.isCancellable,
    required this.onCancel,
    required this.onTap,
    required this.stepIndex,
    required this.isCancelled,
  });

  static const _stepIcons = [
    Icons.inventory_2_outlined,   // Packing
    Icons.local_shipping_outlined, // Shipping
    Icons.delivery_dining_outlined, // Out for delivery
    Icons.home_outlined,          // Delivered
  ];

  static const _stepIconsDone = [
    Icons.inventory_2_rounded,
    Icons.local_shipping_rounded,
    Icons.delivery_dining_rounded,
    Icons.home_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final cancelledRed = const Color(0xFFFF5C5C);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCancelled ? cancelledRed.withAlpha(60) : AppTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: Image + Product Info + Cancel ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    VeraApiService.resolveAssetUrl(order['image'] as String),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppTheme.backgroundLight,
                      child: Icon(Icons.shopping_bag_outlined,
                          color: AppTheme.grayText, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['product'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order['id']} • ${order['date']}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            l10n.localizePrice(order['price'] as String),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const Spacer(),
                          if (isCancellable)
                            GestureDetector(
                              onTap: onCancel,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cancelledRed.withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.cancel,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: cancelledRed,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Stepper ────────────────────────────────────────
            isCancelled
                ? _buildCancelledBar(context)
                : _buildStepper(context),
            if ((order['trackingNumber'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.orderTrackingScreen}?orderId=${Uri.encodeComponent(order['rawId'] as String? ?? '')}',
                  ),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: Text(
                    'تتبع شحنتك  •  ${order['trackingNumber']}',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(BuildContext context) {
    final gold = const Color(0xFFC8A96A);
    final green = const Color(0xFF34C759);
    final blue = const Color(0xFF5DADE2);
    final gray = AppTheme.grayLight;
    final labels = [
      l10n.t('packing'),
      l10n.t('shipping'),
      l10n.t('outForDelivery'),
      l10n.t('delivered'),
    ];

    return Row(
      children: List.generate(4, (i) {
        final isDone = i < stepIndex;
        final isActive = i == stepIndex;
        final isPending = i > stepIndex;

        Color dotColor;
        if (isDone) {
          dotColor = green;
        } else if (isActive) {
          dotColor = blue;
        } else {
          dotColor = gray;
        }

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Dot + Line ────────────────────────────────
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? green : gray.withAlpha(100),
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone
                          ? green
                          : isActive
                              ? blue.withAlpha(30)
                              : gray.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: dotColor,
                        width: isActive ? 2 : 1.5,
                      ),
                    ),
                    child: Icon(
                      isDone
                          ? _OrderCard._stepIconsDone[i]
                          : _OrderCard._stepIcons[i],
                      size: 14,
                      color: dotColor,
                    ),
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? green : gray.withAlpha(100),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Label ─────────────────────────────────────
              Text(
                labels[i],
                style: GoogleFonts.cairo(
                  fontSize: 9,
                  fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                  color: isDone
                      ? green
                      : isActive
                          ? blue
                          : AppTheme.grayText,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCancelledBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C5C).withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFFF5C5C)),
          const SizedBox(width: 8),
          Text(
            l10n.cancelled,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF5C5C),
            ),
          ),
        ],
      ),
    );
  }
}
