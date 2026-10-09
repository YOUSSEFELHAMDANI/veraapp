import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';
import '../../routes/app_routes.dart';
import '../category_screen/category_screen.dart';

class RealEstateHomeScreen extends StatelessWidget {
  const RealEstateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildHeroCard(context, l10n),
                    const SizedBox(height: 28),
                    Text(
                      l10n.t('browseByType'),
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context,
                      l10n: l10n,
                      titleKey: 'allProperties',
                      subtitleKey: 'allPropertiesDesc',
                      icon: Icons.apartment_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD898AA), Color(0xFFC8A96A)],
                      ),
                      topTab: -1,
                    ),
                    const SizedBox(height: 14),
                    _buildOptionCard(
                      context,
                      l10n: l10n,
                      titleKey: 'forSale',
                      subtitleKey: 'forSaleDesc',
                      icon: Icons.sell_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF30B350)],
                      ),
                      topTab: 0,
                    ),
                    const SizedBox(height: 14),
                    _buildOptionCard(
                      context,
                      l10n: l10n,
                      titleKey: 'forRent',
                      subtitleKey: 'forRentDesc',
                      icon: Icons.key_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5DADE2), Color(0xFF4A90D9)],
                      ),
                      topTab: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.t('realEstate'),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD898AA), Color(0xFFC8A96A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD898AA).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('catFindYourDreamHome'),
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('propertiesAvailable'),
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.white.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required AppLocalizations l10n,
    required String titleKey,
    required String subtitleKey,
    required IconData icon,
    required Gradient gradient,
    required int topTab,
  }) {
    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.realEstateListingScreen,
          extra: {'initialTopTab': topTab},
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderLight.withAlpha(80),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t(titleKey),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.t(subtitleKey),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    );
  }
}
