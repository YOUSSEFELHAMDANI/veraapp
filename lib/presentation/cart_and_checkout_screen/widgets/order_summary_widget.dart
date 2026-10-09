import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_localizations.dart';
import '../../../theme/app_theme.dart';

class OrderSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double delivery;
  final double total;
  final bool promoApplied;

  const OrderSummaryWidget({
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.total,
    required this.promoApplied,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderSummary,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: l10n.subtotal,
            value: '${subtotal.toStringAsFixed(2)} AED',
          ),
          if (promoApplied)
            _SummaryRow(
              label: l10n.t('discountPercent', args: {'percent': '10'}),
              value: '- ${discount.toStringAsFixed(2)} AED',
              valueColor: AppTheme.success,
            ),
          _SummaryRow(
            label: l10n.t('delivery'),
            value: '${delivery.toStringAsFixed(2)} AED',
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppTheme.borderLight, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.total,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} AED',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryPinkDark,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Trust badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TrustBadge(
                icon: Icons.security_rounded,
                label: l10n.t('securePayment'),
              ),
              _TrustBadge(
                icon: Icons.local_shipping_outlined,
                label: l10n.t('fastDelivery'),
              ),
              _TrustBadge(icon: Icons.replay_rounded, label: l10n.t('easyReturns')),
              _TrustBadge(
                icon: Icons.support_agent_rounded,
                label: l10n.t('support247'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.charcoal,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryPinkDark),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: AppTheme.grayText,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
