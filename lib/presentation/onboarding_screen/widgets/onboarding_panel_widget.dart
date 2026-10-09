import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_localizations.dart';
import '../../../theme/app_theme.dart';

class OnboardingPanelWidget extends StatelessWidget {
  final dynamic slide;
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final bool isLast;

  const OnboardingPanelWidget({
    required this.slide,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.isLast,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final headline = l10n.t(slide.headlineKey as String);
    final subheadline = l10n.t(slide.subheadlineKey as String);
    // White rounded-top panel — anatomy LOCKED
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // Headline — H1 bold, anatomy LOCKED
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              headline,
              key: ValueKey(headline),
              style: GoogleFonts.cairo(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              subheadline,
              key: ValueKey(subheadline),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppTheme.grayText,
                height: 1.5,
              ),
            ),
          ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Page dots — anatomy LOCKED
              Row(
                children: List.generate(totalPages, (i) {
                  final isActive = i == currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 6),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryPink
                          : AppTheme.borderMedium,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                }),
              ),
              // Next/Get Started FAB — anatomy LOCKED
              isLast
                  ? ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(140, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.getStarted,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: onNext,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withAlpha(89),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
