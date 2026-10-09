import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';

class ProviderProductWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const ProviderProductWizardScreen({super.key, this.initialData});
  @override
  State<ProviderProductWizardScreen> createState() => _ProviderProductWizardScreenState();
}

class _ProviderProductWizardScreenState extends State<ProviderProductWizardScreen> with ProviderGuard {
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  List<VeraCategory> _categories = [];
  List<VeraCategory> _subcategories = [];
  String? _category;
  String? _subcategory;
  String _sizeType = 'oneSize';
  bool _delivery = false;
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _stock = TextEditingController();
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final Map<String, TextEditingController> _sizeStock = {};
  final List<String> _selectedSizes = [];
  final List<String> _customSizes = [];
  final List<String> _colors = [];
  final List<XFile> _photos = [];

  @override
  bool get _isEditMode => widget.initialData != null;

  void initState() { super.initState(); final data = widget.initialData; if (data != null) { _name.text = data['title']?.toString() ?? data['name']?.toString() ?? ''; _brand.text = data['brand']?.toString() ?? ''; _description.text = data['description']?.toString() ?? ''; final rawPrice = data['priceNumeric'] ?? data['price']; if (rawPrice != null) { final numVal = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0; _price.text = numVal > 0 ? numVal.toStringAsFixed(numVal == numVal.roundToDouble() ? 0 : 2) : ''; } _stock.text = data['stock']?.toString() ?? ''; _salePrice.text = data['salePrice']?.toString() ?? ''; _weight.text = (data['shipping_weight_kg'] ?? data['weight'])?.toString() ?? ''; _length.text = data['package_length_cm']?.toString() ?? data['length']?.toString() ?? ''; _width.text = data['package_width_cm']?.toString() ?? data['width']?.toString() ?? ''; _height.text = data['package_height_cm']?.toString() ?? data['height']?.toString() ?? ''; _location.text = data['location']?.toString() ?? data['address']?.toString() ?? ''; _phone.text = data['phone']?.toString() ?? ''; _category = data['categorySlug']?.toString() ?? data['category']?.toString(); _subcategory = data['subcategorySlug']?.toString() ?? data['subcategory']?.toString(); if (data['colors'] is List) for (final c in data['colors'] as List) _colors.add(c.toString()); } if (!guardProviderSession()) return; _loadCategories(); }
  @override
  void dispose() { for (final c in [_name, _brand, _description, _price, _salePrice, _stock, _weight, _length, _width, _height, _location, _phone]) c.dispose(); for (final c in _sizeStock.values) c.dispose(); super.dispose(); }

  Future<void> _loadCategories() async {
    final data = await VeraApiService.instance.fetchCategories();
    if (!mounted) return;
    setState(() {
      _categories = data.where(_isFashion).toList();
      _loading = false;
    });
  }
  bool _isFashion(VeraCategory c) {
    final s = '${c.slug} ${c.name} ${c.enName}'.toLowerCase();
    return s.contains('fashion') || s.contains('أزياء') || s.contains('ملابس');
  }
  bool _excluded(VeraCategory c) { final s = '${c.slug} ${c.name} ${c.enName}'.toLowerCase(); return ['clinic', 'salon', 'beauty', 'gym', 'fitness', 'job', 'career'].any(s.contains); }
  bool get _isRealEstate { final s = (_category ?? '').toLowerCase(); return s.contains('real') || s.contains('property') || s.contains('عق'); }
  Future<void> _selectCategory(String? value) async {
    setState(() { _category = value; _subcategory = null; _subcategories = []; });
    if (value == null) return;
    final withSubs = await VeraApiService.instance.fetchCategoryWithSubs(value);
    final subs = withSubs?.subs ?? await VeraApiService.instance.fetchSubCategories(categoryId: value);
    if (!mounted || _category != value) return;
    setState(() => _subcategories = subs.where((c) => !_excluded(c)).toList());
  }

  Future<void> _pickPhoto() async { if (_photos.length >= 3) return; final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 78, maxWidth: 1600, maxHeight: 1600); if (picked != null && mounted) setState(() => _photos.add(picked)); }
  void _next() {
    final missing = switch (_step) {
      0 => _category == null || _subcategory == null,
      1 => _name.text.trim().isEmpty || _brand.text.trim().isEmpty || _description.text.trim().isEmpty || _price.text.trim().isEmpty || _stock.text.trim().isEmpty,
      2 => _photos.isEmpty && (widget.initialData?['imageUrl'] == null && widget.initialData?['image_url'] == null),
       5 => _delivery && (_weight.text.trim().isEmpty || _length.text.trim().isEmpty || _width.text.trim().isEmpty || _height.text.trim().isEmpty || (_isRealEstate && _location.text.trim().isEmpty)),
      _ => false,
    };
    if (missing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }
    if (_step < 7) setState(() => _step++); else _publish();
  }
  void _back() { if (_step == 0) context.pop(); else setState(() => _step--); }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      final uploadedImages = <String>[];
      for (final photo in _photos) {
        try {
          final url = await VeraApiService.instance.uploadImageBytes(await photo.readAsBytes(), filename: photo.name, type: 'product');
          if (url != null && url.isNotEmpty) uploadedImages.add(url);
        } catch (_) {}
      }
       final actualWeight = double.tryParse(_weight.text) ?? 0;
       final length = double.tryParse(_length.text) ?? 0;
       final width = double.tryParse(_width.text) ?? 0;
       final height = double.tryParse(_height.text) ?? 0;
       final volumetricWeight = length * width * height / 5000;
       final payload = {'title': _name.text.trim(), 'brand': _brand.text.trim(), 'description': _description.text.trim(), 'price': double.tryParse(_price.text) ?? 0, 'salePrice': double.tryParse(_salePrice.text), 'stock': int.tryParse(_stock.text) ?? 0, 'category': _category, 'subcategory': _subcategory, 'sizeType': _sizeType, 'sizes': {for (final s in _selectedSizes) s: int.tryParse(_sizeStock[s]?.text ?? '0') ?? 0}, 'colors': _colors, 'deliveryAvailable': _delivery, 'weight': actualWeight, 'shippingWeight': actualWeight, 'length': length, 'width': width, 'height': height, 'volumetricWeight': volumetricWeight, 'chargeableWeight': actualWeight > volumetricWeight ? actualWeight : volumetricWeight, 'deliveryService': 'NEXT_DAY', 'location': _location.text.trim(), 'phone': _phone.text.trim().isNotEmpty ? _phone.text.trim() : null, 'imageUrl': uploadedImages.isNotEmpty ? uploadedImages.first : null, 'gallery': uploadedImages.length > 1 ? uploadedImages.sublist(1) : null};
      final existingId = widget.initialData?['id']?.toString();
      final result = existingId != null && existingId.isNotEmpty
          ? (await VeraApiService.instance.updateProviderProduct(existingId, payload) ? {'success': true} : null)
          : await VeraApiService.instance.createProviderProduct(payload);
      if (!mounted) return;
      setState(() => _saving = false);
      if (result != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('publishedSuccessfully')))); context.pop(); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('publishFailed')))); }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('publishFailed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final titles = [l.t('category'), l.t('productDetails'), l.t('photos'), l.t('variants'), l.t('colors'), l.t('delivery'), l.t('preview'), l.t('publish')];
    return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: SafeArea(child: Column(children: [
      _header(l, titles[_step]),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: _page(l))),
      _footer(l),
    ])));
  }

  Widget _header(AppLocalizations l, String title) => Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [AppBackButton(onTap: _back), const SizedBox(width: 12), Expanded(child: Text(_isEditMode ? l.t('editProduct') : l.t('addProduct'), style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800)))]), Text('${l.t('step')} ${_step + 1} ${l.t('of')} 8', style: GoogleFonts.cairo(color: Theme.of(context).hintColor)), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (_step + 1) / 8, minHeight: 7, backgroundColor: AppTheme.tintPinkLight, color: AppTheme.primaryPinkDark)), const SizedBox(height: 18), Text(title, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800))]));

  Widget _page(AppLocalizations l) { switch (_step) { case 0: return _categoryPage(l); case 1: return _detailsPage(l); case 2: return _photosPage(l); case 3: return _sizesPage(l); case 4: return _colorsPage(l); case 5: return _deliveryPage(l); case 6: return _previewPage(l); default: return _previewPage(l); } }

  Widget _categoryPage(AppLocalizations l) => Column(children: [_dropdown(l.t('category'), _category, _categories.map((c) => DropdownMenuItem(value: c.slug, child: Text(l.isArabic ? c.name : c.enName))).toList(), _selectCategory), const SizedBox(height: 18), _dropdown(l.t('subcategory'), _subcategory, _subcategories.map((c) => DropdownMenuItem(value: c.slug, child: Text(l.isArabic ? c.name : c.enName))).toList(), (v) => setState(() => _subcategory = v), enabled: _category != null && _subcategories.isNotEmpty)]);
  Widget _detailsPage(AppLocalizations l) => Column(children: [_field(l.t('productName'), _name), _field(l.t('brand'), _brand), _field(l.description, _description, maxLines: 4), Row(children: [Expanded(child: _field(l.t('priceAed'), _price, number: true)), const SizedBox(width: 12), Expanded(child: _field(l.t('salePriceAed'), _salePrice, number: true))]), _field(l.t('stockQuantity'), _stock, number: true)]);
  Widget _photosPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l.t('upToThreePhotos'), style: GoogleFonts.cairo(color: Theme.of(context).hintColor)), const SizedBox(height: 16), Wrap(spacing: 10, runSpacing: 10, children: [..._photos.asMap().entries.map((e) => Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(e.value.path), width: 100, height: 120, fit: BoxFit.cover)), Positioned(right: 4, top: 4, child: InkWell(onTap: () => setState(() => _photos.removeAt(e.key)), child: const CircleAvatar(radius: 12, backgroundColor: Colors.black87, child: Icon(Icons.close, size: 14, color: Colors.white))))])), if (_photos.length < 3) InkWell(onTap: _pickPhoto, child: Container(width: 100, height: 120, decoration: BoxDecoration(border: Border.all(color: AppTheme.borderMedium), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_rounded, size: 32)))])]);
  Widget _sizesPage(AppLocalizations l) {
    final productType = '${_category ?? ''} ${_subcategory ?? ''}'.toLowerCase();
    final isShoes = productType.contains('shoe') || productType.contains('footwear') || productType.contains('أحذية') || productType.contains('حذاء');
    final isBag = productType.contains('bag') || productType.contains('حقيبة') || productType.contains('حقائب');
    final isPerfume = productType.contains('perfume') || productType.contains('fragrance') || productType.contains('عطر') || productType.contains('عطور');
    if (isBag || isPerfume) {
      _sizeType = 'oneSize';
      _selectedSizes
        ..clear()
        ..add('One Size');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBag ? (l.isArabic ? 'الحقائب لا تحتاج إلى مقاسات' : 'Bags do not require sizes') : (l.isArabic ? 'العطور لا تحتاج إلى مقاسات' : 'Perfumes do not require sizes'),
            style: GoogleFonts.cairo(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 18),
          CheckboxListTile(
            value: true,
            onChanged: null,
            activeColor: AppTheme.primaryPinkDark,
            checkColor: Colors.white,
            title: Text(
              l.t('oneSize'),
              style: GoogleFonts.cairo(
                color: AppTheme.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    final types = {
      'letters': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      'numbers': [for (var n = 36; n <= 46; n++) '$n'],
      'oneSize': ['One Size'],
      'custom': ['Custom'],
    };
    if (isShoes) _sizeType = 'numbers';
    final sizes = types[_sizeType]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isShoes) _segmented(l, {
          'letters': l.t('letterSizes'),
          'numbers': l.t('numericSizes'),
          'oneSize': l.t('oneSize'),
          'custom': l.t('custom'),
        }),
        if (isShoes) Text(l.isArabic ? 'مقاسات الأحذية' : 'Shoe sizes', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        ...[...sizes, ..._customSizes].map((s) => CheckboxListTile(
               value: _selectedSizes.contains(s),
               activeColor: AppTheme.primaryPinkDark,
               checkColor: Colors.white,
               title: Text(
                 s,
                 style: GoogleFonts.cairo(
                   color: AppTheme.charcoal,
                   fontWeight: FontWeight.w600,
                 ),
               ),
              secondary: SizedBox(
                width: 80,
                child: TextField(
                  controller: _sizeStock.putIfAbsent(s, TextEditingController.new),
                  keyboardType: TextInputType.number,
                  enabled: _selectedSizes.contains(s),
                  decoration: InputDecoration(
                    hintText: l.t('quantity'),
                    isDense: true,
                  ),
                ),
              ),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedSizes.add(s);
                } else {
                  _selectedSizes.remove(s);
                }
              }),
            )),
        if (isShoes)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: _addCustomSize,
              icon: const Icon(Icons.add_rounded),
              label: Text(l.isArabic ? 'إضافة مقاسك' : 'Add your size'),
            ),
          ),
      ],
    );
  }

  Future<void> _addCustomSize() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add your size'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 47')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty && !_customSizes.contains(value) && mounted) {
      setState(() => _customSizes.add(value));
    }
  }
  Widget _colorsPage(AppLocalizations l) { final c = TextEditingController(); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l.t('colorsOptional'), style: GoogleFonts.cairo(color: Theme.of(context).hintColor)), const SizedBox(height: 14), Row(children: [Expanded(child: TextField(controller: c, decoration: InputDecoration(hintText: l.t('enterColor')))), IconButton(onPressed: () { if (c.text.trim().isNotEmpty) { setState(() => _colors.add(c.text.trim())); c.clear(); } }, icon: const Icon(Icons.add_circle, color: AppTheme.primaryPinkDark))]), Wrap(spacing: 8, children: _colors.map((x) => Chip(label: Text(x), onDeleted: () => setState(() => _colors.remove(x)))).toList())]); }
  double get _volumetricWeight { final l = double.tryParse(_length.text) ?? 0; final w = double.tryParse(_width.text) ?? 0; final h = double.tryParse(_height.text) ?? 0; return l * w * h / 5000; }
  Widget _deliveryPage(AppLocalizations l) => Column(children: [if (_isRealEstate) ...[ _field('Contact Phone', _phone)], SwitchListTile(value: _delivery, onChanged: (v) => setState(() => _delivery = v), title: Text(l.t('availableForDelivery')), subtitle: Text(l.t('deliveryOptional'))), if (_delivery) ...[_field(l.t('shippingWeight'), _weight, number: true), Row(children: [Expanded(child: _field('Length (cm)', _length, number: true)), const SizedBox(width: 8), Expanded(child: _field('Width (cm)', _width, number: true)), const SizedBox(width: 8), Expanded(child: _field('Height (cm)', _height, number: true))]), if (_length.text.isNotEmpty && _width.text.isNotEmpty && _height.text.isNotEmpty) Align(alignment: AlignmentDirectional.centerStart, child: Text('Volumetric Weight: ${_volumetricWeight.toStringAsFixed(2)} kg\nDelivery: Next Day (Remote Areas calculated automatically)', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.grayText))), if (_isRealEstate) ...[_field(l.t('storeBranchLocation'), _location), Container(height: 150, decoration: BoxDecoration(color: AppTheme.tintBlue, borderRadius: BorderRadius.circular(14)), child: const Center(child: Icon(Icons.location_on_rounded, size: 42, color: AppTheme.primaryPinkDark)))]]]);
  Widget _previewPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_summary(l.t('productName'), _name.text), _summary(l.t('category'), '${_category ?? '-'} / ${_subcategory ?? '-'}'), _summary(l.t('priceAed'), _price.text.isEmpty ? '-' : '${_price.text} AED'), _summary(l.t('stockQuantity'), _stock.text.isEmpty ? '-' : _stock.text), _summary(l.t('delivery'), _delivery ? l.t('yes') : l.t('no')), const SizedBox(height: 12), Text(l.t('reviewBeforePublish'), style: GoogleFonts.cairo(color: Theme.of(context).hintColor))]);
  Widget _summary(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: GoogleFonts.cairo(color: Theme.of(context).hintColor)), Flexible(child: Text(b, textAlign: TextAlign.end, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)))]));
  Widget _footer(AppLocalizations l) => Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 18), child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _saving ? null : _next, child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(_step == 7 ? l.t('publish') : l.t('continue'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)))));
  Widget _field(String label, TextEditingController c, {bool number = false, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(controller: c, onChanged: (_) => setState(() {}), maxLines: maxLines, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null, inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null, decoration: InputDecoration(labelText: label)));
  Widget _dropdown(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged, {bool enabled = true}) => DropdownButtonFormField<String>(value: value, items: items, onChanged: enabled ? onChanged : null, decoration: InputDecoration(labelText: label));
  Widget _segmented(AppLocalizations l, Map<String, String> values) => Wrap(spacing: 8, children: values.entries.map((e) => ChoiceChip(label: Text(e.value), selected: _sizeType == e.key, onSelected: (_) => setState(() { _sizeType = e.key; _selectedSizes.clear(); }))).toList());
}
