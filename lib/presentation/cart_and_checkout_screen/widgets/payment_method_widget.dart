import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_localizations.dart';
import '../../../theme/app_theme.dart';

// Anatomy LOCKED: full-width card, logo/icon + label + radio, active=tinted border
class _PaymentMethod {
  final String name;
  final String subtitleKey;
  final IconData icon;
  final Color iconColor;

  const _PaymentMethod({
    required this.name,
    required this.subtitleKey,
    required this.icon,
    required this.iconColor,
  });
}

class _MethodDisplay {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _MethodDisplay({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

class PaymentMethodWidget extends StatelessWidget {
  final int index;
  final bool isSelected;
  final VoidCallback onSelect;

  const PaymentMethodWidget({
    required this.index,
    required this.isSelected,
    required this.onSelect,
    super.key,
  });

  static const List<_PaymentMethod> _methodsWithKeys = [
    _PaymentMethod(
      name: 'Tabby',
      subtitleKey: 'paymentTabbyDesc',
      icon: Icons.splitscreen_rounded,
      iconColor: Color(0xFF4CAF50),
    ),
    _PaymentMethod(
      name: 'VISA / Mastercard',
      subtitleKey: 'paymentCardDesc',
      icon: Icons.credit_card_rounded,
      iconColor: Color(0xFF1565C0),
    ),
    _PaymentMethod(
      name: 'VÉRA Wallet',
      subtitleKey: 'paymentWalletDesc',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppTheme.goldAccent,
    ),
    _PaymentMethod(
      name: 'Tamara',
      subtitleKey: 'paymentTamaraDesc',
      icon: Icons.calendar_month_outlined,
      iconColor: Color(0xFF7B1FA2),
    ),
  ];

  static List<_MethodDisplay> getMethods(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _methodsWithKeys.map((m) {
      return _MethodDisplay(name: m.name, subtitle: l10n.t(m.subtitleKey), icon: m.icon, iconColor: m.iconColor);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final method = getMethods(context)[index];

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPinkLight.withAlpha(128)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPink.withAlpha(26),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: method.iconColor.withAlpha(31),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(method.icon, size: 22, color: method.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    method.subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator — anatomy LOCKED
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryPink
                      : AppTheme.borderMedium,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryPink : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
