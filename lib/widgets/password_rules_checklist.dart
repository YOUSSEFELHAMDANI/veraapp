import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../core/app_localizations.dart';
import '../theme/app_theme.dart';

/// Password policy shared by the registration and password-reset flows.
///
/// A strong password must contain at least 8 characters, one uppercase
/// letter, one lowercase letter, one digit and one special symbol.
class PasswordRules {
  PasswordRules._();

  static final RegExp _special = RegExp(r"[!@#$%^&*()_+\-=\[\]{}|;:',.<>?/~`]");

  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasUppercase(String v) => v.contains(RegExp('[A-Z]'));
  static bool hasLowercase(String v) => v.contains(RegExp('[a-z]'));
  static bool hasDigit(String v) => v.contains(RegExp('[0-9]'));
  static bool hasSpecial(String v) => v.contains(_special);

  static bool isSatisfied(String v) =>
      hasMinLength(v) &&
      hasUppercase(v) &&
      hasLowercase(v) &&
      hasDigit(v) &&
      hasSpecial(v);

  /// Returns a localized message when the value does not meet every rule,
  /// otherwise null. An empty value is treated as "not yet filled".
  static String? validate(AppLocalizations l10n, String? v) {
    if (v == null || v.isEmpty) return null;
    if (!isSatisfied(v)) return l10n.pwInvalidMessage;
    return null;
  }
}

/// Live checklist that shows which password requirements are met while the
/// user types, and which ones are still missing.
class PasswordRulesChecklist extends StatefulWidget {
  const PasswordRulesChecklist({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<PasswordRulesChecklist> createState() => _PasswordRulesChecklistState();
}

class _PasswordRulesChecklistState extends State<PasswordRulesChecklist> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = widget.controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow(l10n.pwMinLength, PasswordRules.hasMinLength(value)),
        SizedBox(height: 0.6.h),
        _buildRow(l10n.pwUppercase, PasswordRules.hasUppercase(value)),
        SizedBox(height: 0.6.h),
        _buildRow(l10n.pwLowercase, PasswordRules.hasLowercase(value)),
        SizedBox(height: 0.6.h),
        _buildRow(l10n.pwNumber, PasswordRules.hasDigit(value)),
        SizedBox(height: 0.6.h),
        _buildRow(l10n.pwSpecial, PasswordRules.hasSpecial(value)),
      ],
    );
  }

  Widget _buildRow(String label, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 13.sp,
          color: met ? AppTheme.success : AppTheme.grayText,
        ),
        SizedBox(width: 1.5.w),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11.sp,
              color: met ? AppTheme.success : AppTheme.grayText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
