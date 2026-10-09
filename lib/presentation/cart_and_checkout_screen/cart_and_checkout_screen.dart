import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../core/auth_gate.dart';
import '../../theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import './widgets/cart_item_widget.dart';
import './widgets/order_summary_widget.dart';
import './widgets/payment_method_widget.dart';
import './widgets/promo_code_widget.dart';

class CartAndCheckoutScreen extends ConsumerStatefulWidget {
  const CartAndCheckoutScreen({super.key});

  @override
  ConsumerState<CartAndCheckoutScreen> createState() =>
      _CartAndCheckoutScreenState();
}

class _CartAndCheckoutScreenState extends ConsumerState<CartAndCheckoutScreen>
    with SingleTickerProviderStateMixin, AuthGuard {
  late TabController _tabController;
  int _currentPhase = 0;
  int _selectedPaymentIndex = 0;
  String _promoCode = '';
  bool _promoApplied = false;
  bool _isCheckingOut = false;
  double _emxDeliveryFee = 25.0;

  // Payment & order state
  bool _showConfirmation = false;
  bool _paymentFailed = false;
  String? _orderId;
  String? _paymentId;
  String? _checkoutIdempotencyKey;
  final TextEditingController _addressController = TextEditingController(text: 'Dubai Marina, Dubai, UAE');
  String _checkoutStatus = '';
  List<Map<String, dynamic>> _lastCartSnapshot = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmxRate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _cartItems {
    return ref.watch(cartProvider).map((item) => item.toMap()).toList();
  }

  double get _subtotal => ref
      .watch(cartProvider)
      .fold(0, (sum, item) => sum + item.price * item.quantity);
  double get _discount => _promoApplied ? _subtotal * 0.1 : 0;
  double get _delivery => _emxDeliveryFee;
  double get _total => _subtotal - _discount + _delivery;

  Future<void> _loadEmxRate() async {
    final items = _cartItems;
    final weight = items.fold<double>(0, (sum, item) => sum + (double.tryParse(item['weightKg']?.toString() ?? '') ?? 1) * (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1));
    final volume = items.fold<double>(0, (sum, item) => sum + (double.tryParse(item['lengthCm']?.toString() ?? '') ?? 10) * (double.tryParse(item['widthCm']?.toString() ?? '') ?? 10) * (double.tryParse(item['heightCm']?.toString() ?? '') ?? 10) * (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1));
    final side = volume > 0 ? math.pow(volume, 1 / 3).toDouble() : 10.0;
    final rate = await VeraApiService.instance.calculateEmxShippingRate(weightKg: weight, lengthCm: side, widthCm: side, heightCm: side);
    if (!mounted) return;
    setState(() { if (rate != null && rate >= 0) _emxDeliveryFee = rate; });
  }

  void _removeItem(String id) {
    ref.read(cartProvider.notifier).removeItem(id);
  }

  void _updateQuantity(String id, int delta) {
    ref.read(cartProvider.notifier).updateQuantity(id, delta);
  }

  void _applyPromo(String code) async {
    final l10n = AppLocalizations.of(context);
    final result = await VeraApiService.instance.validatePromoCode(code);
    final isValid = result != null
        ? (result['valid'] == true ||
              result['success'] == true ||
              result['discount'] != null)
        : code.toUpperCase() == 'VERA10';

    setState(() {
      _promoCode = code;
      _promoApplied = isValid;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _promoApplied ? l10n.t('discountApplied') : l10n.t('invalidPromoCode'),
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: _promoApplied ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleCheckout() async {
    if (_isCheckingOut) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isCheckingOut = true;
      _paymentFailed = false;
      _checkoutStatus = l10n.t('placingYourOrder');
    });

    // Must match PaymentMethodWidget.methods order: Tabby, Card, Wallet, Tamara
    final paymentMethods = ['tabby', 'card', 'wallet', 'tamara'];
    final method =
        paymentMethods[_selectedPaymentIndex % paymentMethods.length];

    try {
      final checkout = await VeraApiService.instance.createCheckoutSession(
        idempotencyKey: _checkoutIdempotencyKey ??= 'checkout-${DateTime.now().microsecondsSinceEpoch}',
        paymentMethod: method,
        total: _total,
        items: _cartItems,
        promoCode: _promoApplied ? _promoCode : null,
        subtotal: _subtotal,
        discount: _discount,
        deliveryFee: _delivery,
        currency: 'AED',
        address: _addressController.text,
      );
      final session = checkout?['checkout_session'] as Map<String, dynamic>?;
      final checkoutSessionId = session?['id']?.toString();
      if (checkoutSessionId == null || checkoutSessionId.isEmpty) {
        throw StateError('Checkout session was not created');
      }
      setState(() {
        _checkoutStatus = l10n.t('initiatingPayment');
      });

      var confirmed = false;
      if (method == 'wallet') {
        final walletResult = await VeraApiService.instance
            .payWithWallet(checkoutSessionId: checkoutSessionId);
        if (walletResult != null && walletResult['success'] == true) {
          _orderId = walletResult['orderId']?.toString() ?? _orderId;
          confirmed = true;
        } else {
          final walletError =
              walletResult?['error']?.toString() ?? l10n.walletInsufficient;
          throw StateError(walletError);
        }
      } else {
        final paymentInitResult = await VeraApiService.instance.initiatePayment(
          amount: _total,
          method: method,
          checkoutSessionId: checkoutSessionId,
          currency: 'AED',
        );

        final resolvedPaymentId = paymentInitResult != null
            ? (paymentInitResult['payment_id']?.toString() ??
                  paymentInitResult['id']?.toString() ??
                  paymentInitResult['data']?['payment_id']?.toString() ??
                  '')
            : '';
        if (resolvedPaymentId.isEmpty) {
          throw StateError('Payment session was not created');
        }

        setState(() {
          _paymentId = resolvedPaymentId;
          _checkoutStatus = l10n.t('verifyingPayment');
        });

        final checkoutUrl = paymentInitResult?['checkout_url']?.toString() ??
            paymentInitResult?['checkoutUrl']?.toString() ??
            '';
        if (checkoutUrl.isNotEmpty) {
          final opened = await _openCheckoutUrl(checkoutUrl);
          if (!mounted) return;
          if (opened) {
            setState(() => _checkoutStatus = l10n.t('confirmPaymentInBrowser'));
            confirmed = await _pollPaymentConfirmation(
              paymentId: resolvedPaymentId,
              checkoutSessionId: checkoutSessionId,
            );
          }
        }

        if (!confirmed) {
          final verifyResult = await VeraApiService.instance.verifyPayment(
            paymentId: resolvedPaymentId,
            checkoutSessionId: checkoutSessionId,
            extraData: {'amount': _total},
          );
          confirmed = verifyResult?['verified'] == true;
        }
      }

      if (!mounted) return;

      if (confirmed) {
        _lastCartSnapshot = ref
            .read(cartProvider)
            .map((item) => item.toMap())
            .toList();
        ref.read(cartProvider.notifier).clearCart();
        setState(() {
          _isCheckingOut = false;
          _showConfirmation = true;
          _paymentFailed = false;
        });
      } else {
        setState(() {
          _isCheckingOut = false;
          _paymentFailed = true;
          _checkoutStatus = l10n.t('paymentNotConfirmed');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
          _paymentFailed = true;
          _checkoutStatus = e is StateError &&
                  e.message.isNotEmpty &&
                  e.message != 'Payment session was not created' &&
                  e.message != 'Checkout session was not created'
              ? e.message
              : l10n.somethingWentWrong;
        });
      }
    }
  }

  Future<bool> _openCheckoutUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _pollPaymentConfirmation({
    required String paymentId,
    required String checkoutSessionId,
  }) async {
    final l10n = AppLocalizations.of(context);
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      final result = await VeraApiService.instance.verifyPayment(
        paymentId: paymentId,
        checkoutSessionId: checkoutSessionId,
      );
      final verified = result?['verified'] == true;
      setState(() {
        _checkoutStatus = verified
            ? l10n.t('paymentConfirmed')
            : l10n.t('waitingPaymentConfirmation', args: {'count': '${i + 1}', 'total': '20'});
      });
      if (verified) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cartItems = ref.watch(cartProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    if (_showConfirmation) {
      return _buildConfirmationScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.charcoal),
        ),
        title: Text(
          _currentPhase == 0 ? l10n.t('myCart') : l10n.checkout,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentPhase == 0)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
              child: Text(
                l10n.t('clear'),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.ivoryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _PhaseTab(
                  label:
                      '${l10n.cart} (${cartItems.fold(0, (s, i) => s + i.quantity)})',
                  isActive: _currentPhase == 0,
                  onTap: () => setState(() => _currentPhase = 0),
                ),
                _PhaseTab(
                  label: l10n.checkout,
                  isActive: _currentPhase == 1,
                  onTap: () => setState(() => _currentPhase = 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: isTablet
          ? _buildTabletLayout()
          : (_currentPhase == 0 ? _buildCartView() : _buildCheckoutView()),
    );
  }

  Widget _buildConfirmationScreen() {
    final l10n = AppLocalizations.of(context);
    final cartSnapshot = _orderId != null
        ? _lastCartSnapshot
        : <Map<String, dynamic>>[];
    final estimatedDelivery = DateTime.now().add(const Duration(days: 3));
    final deliveryStr =
        '${estimatedDelivery.day} ${_monthName(estimatedDelivery.month)} ${estimatedDelivery.year}';
    final displayOrderId =
        _orderId ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}';

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
                    // Success icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPink.withAlpha(77),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.t('orderPlaced'),
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('orderConfirmedMessage'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppTheme.grayText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order info card
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
                            label: l10n.t('orderNumber'),
                            value: displayOrderId,
                            valueColor: AppTheme.primaryPinkDark,
                            isBold: true,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                          ),
                          _infoRow(
                            icon: Icons.local_shipping_outlined,
                            label: l10n.t('estimatedDelivery'),
                            value: deliveryStr,
                            valueColor: AppTheme.charcoal,
                            isBold: true,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                          ),
                          _infoRow(
                            icon: Icons.location_on_outlined,
                            label: l10n.deliveryAddress,
                            value: 'Dubai Marina, Dubai, UAE',
                            valueColor: AppTheme.charcoal,
                            isBold: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Items breakdown
                    if (cartSnapshot.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.t('itemsOrdered'),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            ...cartSnapshot.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              final isLast = idx == cartSnapshot.length - 1;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            VeraApiService.resolveAssetUrl(
                                              item['imageUrl']?.toString() ?? '',
                                            ),
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme
                                                        .primaryPinkLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: AppTheme
                                                        .primaryPinkDark,
                                                    size: 22,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name']?.toString() ??
                                                    'Item',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.charcoal,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                item['provider']?.toString() ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color: AppTheme.grayText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${((item['price'] as num?) ?? 0).toStringAsFixed(0)} AED',
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.charcoal,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppTheme.primaryPinkLight,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'x${item['quantity'] ?? 1}',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppTheme.primaryPinkDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: AppTheme.borderLight,
                                    ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Price breakdown
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          l10n.t('priceBreakdown'),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          _priceRow(l10n.subtotal, _subtotal),
                          if (_discount > 0) ...[
                            const SizedBox(height: 10),
                            _priceRow(
                              l10n.t('promoDiscount'),
                              -_discount,
                              valueColor: AppTheme.success,
                            ),
                          ],
                          const SizedBox(height: 10),
                          _priceRow(l10n.t('deliveryFee'), _delivery),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.t('totalPaid'),
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              Text(
                                '${_total.toStringAsFixed(2)} AED',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryPinkDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.homeScreen),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.t('continueShopping'),
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.myBookingsScreen),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryPink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.t('trackMyOrder'),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPinkDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required bool isBold,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryPinkLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryPinkDark, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppTheme.grayText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, double amount, {Color? valueColor}) {
    final isNegative = amount < 0;
    final display = isNegative
        ? '-${amount.abs().toStringAsFixed(2)} AED'
        : '${amount.toStringAsFixed(2)} AED';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
        ),
        Text(
          display,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 55, child: _buildCartView()),
        Container(width: 1, color: AppTheme.borderLight),
        Expanded(flex: 45, child: _buildCheckoutView()),
      ],
    );
  }

  Widget _buildCartView() {
    final l10n = AppLocalizations.of(context);
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryPinkLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: AppTheme.primaryPinkDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.t('yourCartIsEmpty'),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('addToGetStarted'),
              style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.grayText),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.homeScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.t('exploreServices'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            children: [
              ..._cartItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CartItemWidget(
                    item: item,
                    onRemove: () => _removeItem(item['id'] as String),
                    onQuantityChange: (delta) =>
                        _updateQuantity(item['id'] as String, delta),
                  ),
                ),
              ),
              PromoCodeWidget(
                onApply: _applyPromo,
                isApplied: _promoApplied,
                code: _promoCode,
              ),
              const SizedBox(height: 16),
              OrderSummaryWidget(
                subtotal: _subtotal,
                discount: _discount,
                delivery: _delivery,
                total: _total,
                promoApplied: _promoApplied,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => setState(() => _currentPhase = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.t('proceedToCheckout'),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${_total.toStringAsFixed(0)} AED',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(217),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutView() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            children: [
              // Delivery address section
              _buildSectionHeader(l10n.deliveryAddress),
              _buildAddressCard(),
              const SizedBox(height: 20),

              // Payment method
              _buildSectionHeader(l10n.paymentMethod),
              ...List.generate(
                PaymentMethodWidget.getMethods(context).length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PaymentMethodWidget(
                    index: i,
                    isSelected: _selectedPaymentIndex == i,
                    onSelect: () => setState(() => _selectedPaymentIndex = i),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Order summary
              _buildSectionHeader(l10n.orderSummary),
              OrderSummaryWidget(
                subtotal: _subtotal,
                discount: _discount,
                delivery: _delivery,
                total: _total,
                promoApplied: _promoApplied,
              ),

              // Payment failure message
              if (_paymentFailed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _checkoutStatus,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Processing status
              if (_isCheckingOut) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPinkLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryPinkDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _checkoutStatus,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppTheme.primaryPinkDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isCheckingOut ? null : _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isCheckingOut
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.placeOrder,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${_total.toStringAsFixed(0)} AED',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(217),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.charcoal,
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryPinkLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppTheme.primaryPinkDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.home,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                SizedBox(height: 42, child: TextField(controller: _addressController, maxLines: 2, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.grayText), decoration: InputDecoration(border: InputBorder.none, hintText: 'أدخل عنوان التوصيل', hintStyle: GoogleFonts.cairo(fontSize: 12, color: AppTheme.grayText)))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _addressController.selection = TextSelection(baseOffset: 0, extentOffset: _addressController.text.length),
            child: Text(
              l10n.t('change'),
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppTheme.primaryPinkDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PhaseTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.charcoal : AppTheme.grayText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
