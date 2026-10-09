import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum BadgeStatus {
  pending,
  processing,
  confirmed,
  delivered,
  cancelled,
  active,
  expired,
  draft,
}

class StatusBadgeWidget extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;
  final double fontSize;

  const StatusBadgeWidget({
    required this.status,
    this.customLabel,
    this.fontSize = 11,
    super.key,
  });

  _BadgeStyle _getStyle() {
    switch (status) {
      case BadgeStatus.pending:
        return _BadgeStyle(
          AppTheme.warning.withAlpha(38),
          AppTheme.warning,
          'Pending',
        );
      case BadgeStatus.processing:
        return _BadgeStyle(
          AppTheme.info.withAlpha(38),
          AppTheme.info,
          'Processing',
        );
      case BadgeStatus.confirmed:
        return _BadgeStyle(
          AppTheme.success.withAlpha(38),
          AppTheme.success,
          'Confirmed',
        );
      case BadgeStatus.delivered:
        return _BadgeStyle(
          AppTheme.success.withAlpha(38),
          AppTheme.success,
          'Delivered',
        );
      case BadgeStatus.cancelled:
        return _BadgeStyle(
          AppTheme.error.withAlpha(38),
          AppTheme.error,
          'Cancelled',
        );
      case BadgeStatus.active:
        return _BadgeStyle(
          AppTheme.success.withAlpha(38),
          AppTheme.success,
          'Active',
        );
      case BadgeStatus.expired:
        return _BadgeStyle(
          AppTheme.grayText.withAlpha(38),
          AppTheme.grayText,
          'Expired',
        );
      case BadgeStatus.draft:
        return _BadgeStyle(
          AppTheme.warning.withAlpha(38),
          AppTheme.warning,
          'Draft',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        customLabel ?? style.label,
        style: GoogleFonts.cairo(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: style.textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color textColor;
  final String label;
  const _BadgeStyle(this.bg, this.textColor, this.label);
}
