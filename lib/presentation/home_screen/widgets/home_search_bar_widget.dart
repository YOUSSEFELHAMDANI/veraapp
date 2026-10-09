import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_localizations.dart';
import '../../../theme/app_theme.dart';

// Anatomy LOCKED: outlined field, mic icon + camera icon right
class HomeSearchBarWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const HomeSearchBarWidget({
    this.onTap,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppTheme.searchBarHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppTheme.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: AppTheme.grayText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.searchHintHome,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppTheme.grayText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
