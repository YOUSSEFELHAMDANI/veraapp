import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class ProviderCatalogScreen extends StatefulWidget {
  const ProviderCatalogScreen({super.key});
  @override
  State<ProviderCatalogScreen> createState() => _ProviderCatalogScreenState();
}

class _ProviderCatalogScreenState extends State<ProviderCatalogScreen> with ProviderGuard {
  bool _loading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() { super.initState(); if (!guardProviderSession()) return; _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await VeraApiService.instance.fetchProviderProducts();
    if (!mounted) return;
    setState(() { _products = products; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8), child: IconButton(onPressed: () => context.go(AppRoutes.providerDashboardScreen), icon: const Icon(Icons.arrow_back_ios_new_rounded))),
        title: Text(l.t('myCatalog'), style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _products.isEmpty ? _empty(l) : _productList(l),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push(AppRoutes.providerProductWizardScreen).then((_) => _load()), icon: const Icon(Icons.add_rounded), label: Text(l.t('add'))),
    );
  }

  Widget _productList(AppLocalizations l) {
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.fromLTRB(20, 8, 20, 90), itemCount: _products.length, itemBuilder: (_, i) {
      final p = _products[i];
      return _card(l, p['title']?.toString() ?? p['name']?.toString() ?? '-', p['category']?.toString() ?? '', p['status'] ?? 'pending', p['price']?.toString() ?? '', () => _deleteProduct(p['id']?.toString() ?? ''), () => context.push(AppRoutes.providerProductWizardScreen, extra: p).then((_) => _load()));
    }));
  }

  Widget _card(AppLocalizations l, String title, String category, dynamic rawStatus, String price, VoidCallback onDelete, VoidCallback onEdit) {
    final status = rawStatus.toString().toLowerCase();
    final color = status.contains('reject') ? AppTheme.error : status.contains('approv') || status.contains('publish') ? AppTheme.success : AppTheme.warning;
    final label = status.contains('reject') ? l.t('rejected') : status.contains('approv') || status.contains('publish') ? l.t('approved') : l.t('pendingApproval');
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.shopping_bag_outlined, color: color)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)), Text(category, style: GoogleFonts.cairo(fontSize: 12, color: Theme.of(context).hintColor)), if (price.isNotEmpty) Text('AED $price', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.goldAccent))])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)), child: Text(label, style: GoogleFonts.cairo(fontSize: 10, color: color, fontWeight: FontWeight.w700))), PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'delete') onDelete(); }, itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text(l.t('edit'))), PopupMenuItem(value: 'delete', child: Text(l.t('delete')))])]));
  }

  Widget _empty(AppLocalizations l) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 52, color: AppTheme.grayLight), const SizedBox(height: 12), Text(l.t('noProductsYet'), style: GoogleFonts.cairo(color: AppTheme.grayText)), const SizedBox(height: 16), ElevatedButton(onPressed: () => context.push(AppRoutes.providerProductWizardScreen), child: Text(l.t('add')))]));

  Future<void> _deleteProduct(String id) async {
    if (id.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).t('delete'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this product?', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(ctx).t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(ctx).t('delete'), style: const TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm == true && await VeraApiService.instance.deleteProviderProduct(id)) _load();
  }
}
