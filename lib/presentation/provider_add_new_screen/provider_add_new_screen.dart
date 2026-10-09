import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';

class ProviderAddNewScreen extends StatelessWidget {
  const ProviderAddNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = [
      _Option(Icons.shopping_bag_outlined, l.t('product'), l.t('physicalProductDesc'), AppRoutes.providerProductWizardScreen),
      _Option(Icons.calendar_today_outlined, l.t('serviceAppointment'), l.t('bookableServiceDesc'), AppRoutes.providerServiceWizardScreen),
      _Option(Icons.groups_outlined, l.t('classSession'), l.t('scheduledClassDesc'), AppRoutes.providerServiceWizardScreen),
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8), child: AppBackButton(onTap: () => context.pop())),
        title: Text(l.t('addNew'), style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(l.t('whatWouldYouLikeToAdd'), style: GoogleFonts.cairo(fontSize: 14, color: Theme.of(context).hintColor)),
          const SizedBox(height: 22),
          ...options.map((o) => _optionCard(context, o)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => context.push(AppRoutes.providerImportScreen),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderLight)),
              child: Row(children: [
                const Icon(Icons.upload_file_outlined, size: 34, color: AppTheme.goldAccent),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.t('importExcelCsv'), style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(l.t('bulkImportDesc'), style: GoogleFonts.cairo(fontSize: 12, color: Theme.of(context).hintColor)),
                ])),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(BuildContext context, _Option option) => InkWell(
        onTap: () => context.push(option.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderLight)),
          child: Row(children: [
            Icon(option.icon, size: 36, color: AppTheme.primaryPinkDark),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(option.title, style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(option.subtitle, style: GoogleFonts.cairo(fontSize: 12, color: Theme.of(context).hintColor)),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      );

}

class _Option {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _Option(this.icon, this.title, this.subtitle, this.route);
}
