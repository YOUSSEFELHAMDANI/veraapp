import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/custom_image_widget.dart';

class AllProvidersScreen extends StatefulWidget {
  const AllProvidersScreen({super.key});

  @override
  State<AllProvidersScreen> createState() => _AllProvidersScreenState();
}

class _AllProvidersScreenState extends State<AllProvidersScreen> {
  List<VeraProvider> _providers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final providers = await VeraApiService.instance.fetchTopProviders(limit: 100);
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _loading = false;
    });
  }

  void _open(VeraProvider p) {
    context.push(AppRoutes.publicProviderProfileScreen, extra: {
      'id': p.id, 'name': p.name, 'category': p.category, 'city': p.city,
      'rating': p.rating, 'reviews': p.reviewCount, 'imageUrl': p.imageUrl,
      'isVerified': p.isVerified, 'email': p.email, 'followers': p.followers,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: AppBackButton(onTap: () => context.pop()),
        title: Text(l10n.topProviders, style: GoogleFonts.cairo(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.charcoal)),
      ),
      body: RefreshIndicator(
        color: AppTheme.goldAccent,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent))
            : _providers.isEmpty
                ? Center(child: Text(l10n.t('noProvidersFound'), style: GoogleFonts.cairo(color: AppTheme.grayText)))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 3.h),
                    itemCount: _providers.length,
                    separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
                    itemBuilder: (_, i) {
                      final p = _providers[i];
                      return InkWell(
                        onTap: () => _open(p),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: p.imageUrl.isEmpty
                                  ? Container(width: 16.w, height: 16.w, color: AppTheme.primaryPinkLight, child: const Icon(Icons.store_rounded, color: AppTheme.primaryPinkDark))
                                  : CustomImageWidget(imageUrl: p.imageUrl, width: 16.w, height: 16.w, fit: BoxFit.cover, semanticLabel: p.name),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.charcoal)),
                              SizedBox(height: .4.h),
                              Text(p.city.isEmpty ? p.category : '${p.category} • ${p.city}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.grayText)),
                              SizedBox(height: .6.h),
                              Row(children: [const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFC107)), const SizedBox(width: 3), Text('${p.rating.toStringAsFixed(1)} (${p.reviewCount})', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.grayText))]),
                            ])),
                            Icon(Icons.chevron_left_rounded, color: AppTheme.grayText),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
