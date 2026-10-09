import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen>
    with AuthGuard {
  int _selectedCard = 0;
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = true;

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF1A1A2E), Color(0xFF16213E)],
    [Color(0xFF2D1B69), Color(0xFF11998E)],
    [Color(0xFFB24592), Color(0xFFF15F79)],
  ];

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final methods = await VeraApiService.instance.fetchPaymentMethods();
      if (!mounted) return;
      final cards = <Map<String, dynamic>>[];
      final wallets = <Map<String, dynamic>>[];
      for (final m in methods) {
        final type =
            (m['type'] ?? m['method'] ?? m['kind'] ?? '').toString().toLowerCase();
        if (type.contains('card') ||
            type.contains('visa') ||
            type.contains('master') ||
            type.contains('credit') ||
            type.contains('debit') ||
            type.contains('amex')) {
          cards.add(_cardFromMethod(m, cards.length));
        } else {
          wallets.add(_walletFromMethod(m));
        }
      }
      setState(() {
        _cards = cards;
        _wallets = wallets;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _cardFromMethod(Map<String, dynamic> m, int index) {
    final gradient = _cardGradients[index % _cardGradients.length];
    return {
      'type': _brandOf(m),
      'last4': _last4Of(m),
      'expiry': m['expiry']?.toString() ?? m['expiration']?.toString() ?? '',
      'holder': m['holder']?.toString() ??
          m['card_holder']?.toString() ??
          m['name']?.toString() ??
          '',
      'color1': gradient[0],
      'color2': gradient[1],
      'isDefault': _asBool(m['is_default'] ?? m['default'] ?? m['isDefault']),
    };
  }

  Map<String, dynamic> _walletFromMethod(Map<String, dynamic> m) {
    final type =
        (m['type'] ?? m['method'] ?? m['name'] ?? '').toString().toLowerCase();
    return {
      'name': m['name']?.toString() ??
          m['wallet_name']?.toString() ??
          m['title']?.toString() ??
          'Wallet',
      'icon': _walletIcon(type),
      'connected': _asBool(m['connected'] ?? m['is_connected'] ?? m['linked']),
      'balance': m['balance']?.toString() ?? m['wallet_balance']?.toString(),
    };
  }

  String _brandOf(Map<String, dynamic> m) {
    final raw =
        (m['type'] ?? m['brand'] ?? m['card_type'] ?? '').toString().trim();
    final t = raw.toLowerCase();
    if (t.contains('visa')) return 'Visa';
    if (t.contains('master')) return 'Mastercard';
    if (t.contains('amex') || t.contains('american')) return 'Amex';
    if (raw.isEmpty) return 'Card';
    return raw;
  }

  String _last4Of(Map<String, dynamic> m) {
    final l4 = m['last4'] ?? m['last_four'] ?? m['last_four_digits'];
    if (l4 != null) return '$l4';
    final number =
        (m['number'] ?? m['card_number'] ?? m['pan'] ?? '').toString();
    final digits = number.replaceAll(' ', '');
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return '';
  }

  IconData _walletIcon(String type) {
    if (type.contains('apple')) return Icons.apple;
    if (type.contains('google')) return Icons.g_mobiledata_rounded;
    if (type.contains('paypal')) return Icons.payment_rounded;
    return Icons.account_balance_wallet_outlined;
  }

  bool _asBool(Object? v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v != 0;
    return false;
  }

  Widget _buildEmptyHint(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
        ),
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.ivoryLight,
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
                  Text(
                    l10n.t('paymentMethods'),
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddCardSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPinkLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppTheme.primaryPinkDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryPinkDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      children: [
                        // Cards section
                        Text(
                          l10n.t('savedCards'),
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Card carousel
                        if (_cards.isEmpty)
                          _buildEmptyHint('No saved cards yet.')
                        else
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _cards.length,
                              itemBuilder: (_, i) {
                                final card = _cards[i];
                                final isSelected = _selectedCard == i;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedCard = i),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    width: 280,
                                    margin: EdgeInsets.only(
                                      right: 16,
                                      bottom: isSelected ? 0 : 8,
                                      top: isSelected ? 0 : 8,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          card['color1'] as Color,
                                          card['color2'] as Color,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (card['color1'] as Color)
                                              .withAlpha(
                                                80,
                                              ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              card['type'] as String,
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (card['isDefault'] as bool)
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withAlpha(40),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    20,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Default',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Text(
                                          '**** **** **** ${card['last4']}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n.t('cardHolder'),
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 10,
                                                    color: Colors.white
                                                        .withAlpha(160),
                                                  ),
                                                ),
                                                Text(
                                                  card['holder'] as String,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  l10n.t('expires'),
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 10,
                                                    color: Colors.white
                                                        .withAlpha(160),
                                                  ),
                                                ),
                                                Text(
                                                  card['expiry'] as String,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Card actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  l10n.t('remove'),
                                  style: GoogleFonts.cairo(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                  side: const BorderSide(
                                    color: AppTheme.error,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: const Size(0, 42),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  l10n.t('setDefault'),
                                  style: GoogleFonts.cairo(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: const Size(0, 42),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Digital wallets
                        Text(
                          l10n.t('digitalWallets'),
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (_wallets.isEmpty)
                          _buildEmptyHint('No digital wallets connected.')
                        else
                          ..._wallets.map(
                            (w) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.ivoryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      w['icon'] as IconData,
                                      size: 22,
                                      color: AppTheme.charcoal,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w['name'] as String,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.charcoal,
                                          ),
                                        ),
                                        if (w['balance'] != null)
                                          Text(
                                            'Balance: ${w['balance']}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: AppTheme.grayText,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (w['connected'] as bool)
                                          ? AppTheme.jobsBg
                                          : AppTheme.primaryPinkLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (w['connected'] as bool)
                                          ? 'Connected'
                                          : 'Connect',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: (w['connected'] as bool)
                                            ? AppTheme.success
                                            : AppTheme.primaryPinkDark,
                                      ),
                                    ),
                                  ),
                                ],
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

  void _showAddCardSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add New Card',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 20),
              _buildInput(
                l10n.t('cardNumber'),
                '0000 0000 0000 0000',
                Icons.credit_card_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      l10n.t('expiryDate'),
                      'MM/YY',
                      Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      'CVV',
                      '•••',
                      Icons.lock_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInput(
                l10n.t('cardHolder'),
                l10n.fullName,
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    l10n.t('addCard'),
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, String hint, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.grayText),
        filled: true,
        fillColor: AppTheme.ivoryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
        hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayLight),
      ),
    );
  }
}
