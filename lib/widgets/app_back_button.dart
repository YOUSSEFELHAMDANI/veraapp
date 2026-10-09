import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Unified circular back button used across all screen headers.
// Fixed 40x40, radius 12, arrow_back_ios_new_rounded 16.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBackButton({this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: AppTheme.backButtonSize,
        height: AppTheme.backButtonSize,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: AppTheme.iconXs,
          color: AppTheme.charcoal,
        ),
      ),
    );
  }
}
