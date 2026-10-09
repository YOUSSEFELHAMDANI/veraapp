import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/place_autocomplete_field.dart';

class ProviderServiceWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const ProviderServiceWizardScreen({super.key, this.initialData});
  @override
  State<ProviderServiceWizardScreen> createState() => _ProviderServiceWizardScreenState();
}

class _ProviderServiceWizardScreenState extends State<ProviderServiceWizardScreen> with ProviderGuard {
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _longDescription = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController(text: '30');
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  double? _selectedLat;
  double? _selectedLng;
  String _existingImage = '';
  List<String> _existingGallery = const [];
  String? _jobType;
  final _salary = TextEditingController();
  String? _listingType;
  List<VeraCategory> _categories = [];
  String? _selectedCategory;
  String? _selectedSubcategory;
  List<VeraCategory> _subcategories = [];
  final List<XFile> _photos = [];
  final Map<String, bool> _workingDays = {
    'Sunday': true, 'Monday': true, 'Tuesday': true,
    'Wednesday': true, 'Thursday': true, 'Friday': false, 'Saturday': false,
  };
  final Map<String, TimeOfDay> _openTimes = {
    'Sunday': const TimeOfDay(hour: 9, minute: 0),
    'Monday': const TimeOfDay(hour: 9, minute: 0),
    'Tuesday': const TimeOfDay(hour: 9, minute: 0),
    'Wednesday': const TimeOfDay(hour: 9, minute: 0),
    'Thursday': const TimeOfDay(hour: 9, minute: 0),
    'Friday': const TimeOfDay(hour: 10, minute: 0),
    'Saturday': const TimeOfDay(hour: 10, minute: 0),
  };
  final Map<String, TimeOfDay> _closeTimes = {
    'Sunday': const TimeOfDay(hour: 21, minute: 0),
    'Monday': const TimeOfDay(hour: 21, minute: 0),
    'Tuesday': const TimeOfDay(hour: 21, minute: 0),
    'Wednesday': const TimeOfDay(hour: 21, minute: 0),
    'Thursday': const TimeOfDay(hour: 21, minute: 0),
    'Friday': const TimeOfDay(hour: 22, minute: 0),
    'Saturday': const TimeOfDay(hour: 22, minute: 0),
  };

  bool get _isEditMode => widget.initialData != null;
  bool get _isRealEstate { final s = (_selectedCategory ?? '').toLowerCase(); return s.contains('real') || s.contains('property') || s.contains('عق'); }
  bool get _isJobs { final s = (_selectedCategory ?? '').toLowerCase(); return s.contains('job') || s.contains('career') || s.contains('وظ') || s.contains('توظ'); }

  @override
  void initState() {
    super.initState();
    _price.addListener(_formatPriceInput);
    if (!guardProviderSession()) return;
    _loadCategories().then((_) => _prefillIfEditing());
  }

  @override
  void dispose() {
    _price.removeListener(_formatPriceInput);
    for (final c in [_name, _description, _longDescription, _price, _duration, _address, _city, _phone, _salary]) c.dispose();
    super.dispose();
  }

  void _formatPriceInput() {
    final raw = _price.text.replaceAll(',', '');
    if (raw.isEmpty || raw == '.') return;
    final parts = raw.split('.');
    final integer = parts.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final grouped = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final formatted = parts.length > 1 ? '$grouped.${parts.sublist(1).join('.')}' : grouped;
    if (formatted != _price.text) {
      _price.value = _price.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _loadCategories() async {
    final categories = await VeraApiService.instance.fetchCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories.where((c) {
        final s = '${c.slug} ${c.name} ${c.enName}'.toLowerCase();
        return !s.contains('fashion') && !s.contains('أزياء') && !s.contains('ملابس');
      }).toList();
      _loading = false;
    });
  }

  void _prefillIfEditing() {
    final d = widget.initialData;
    if (d == null) return;
    _name.text = d['title']?.toString() ?? d['name']?.toString() ?? '';
    _description.text = d['description']?.toString() ?? '';
    _longDescription.text = d['longDescription']?.toString() ?? d['long_description']?.toString() ?? '';
    final rawPrice = d['priceNumeric'] ?? d['price'];
    if (rawPrice != null) {
      final numVal = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0;
      _price.text = numVal > 0 ? numVal.toStringAsFixed(numVal == numVal.roundToDouble() ? 0 : 2) : '';
    }
    final dur = d['durationMinutes']?.toString() ?? d['duration_minutes']?.toString() ?? '30';
    _duration.text = dur.replaceAll(RegExp(r'[^0-9]'), '') == '' ? '30' : dur.replaceAll(RegExp(r'[^0-9]'), '');
    _address.text = d['address']?.toString() ?? '';
    _city.text = d['city']?.toString() ?? d['location']?.toString() ?? '';
    _phone.text = d['phone']?.toString() ?? '';
    final latV = d['latitude'];
    final lngV = d['longitude'];
    if (latV != null) _selectedLat = latV is num ? latV.toDouble() : double.tryParse(latV.toString());
    if (lngV != null) _selectedLng = lngV is num ? lngV.toDouble() : double.tryParse(lngV.toString());
    final img = d['image']?.toString() ?? d['imageUrl']?.toString() ?? '';
    if (img.isNotEmpty) _existingImage = img;
    final gal = d['gallery'];
    if (gal is List) {
      _existingGallery = gal.map((g) => g is String ? g : (g is Map ? (g['url'] ?? g['path'] ?? '').toString() : '')).where((s) => s.isNotEmpty).toList();
    } else if (d['images'] is List) {
      _existingGallery = (d['images'] as List).skip(1).map((g) => g is String ? g : (g is Map ? (g['url'] ?? g['path'] ?? '').toString() : '')).where((s) => s.isNotEmpty).toList();
    }
    final catSlug = d['categorySlug']?.toString() ?? d['category']?.toString();
    if (catSlug != null) {
      _selectedCategory = catSlug;
      _onCategoryChanged(catSlug);
    }
    final subSlug = d['subcategorySlug']?.toString();
    if (subSlug != null) _selectedSubcategory = subSlug;
    _listingType = d['listing_type']?.toString() ?? d['listingType']?.toString();
    final hours = d['workingHours'] ?? d['working_hours'];
    if (hours is Map<String, dynamic>) {
      for (final entry in hours.entries) {
        final day = entry.key;
        if (_workingDays.containsKey(day)) {
          _workingDays[day] = true;
          final o = entry.value;
          if (o is Map) {
            if (o['open'] != null) {
              final parts = o['open'].toString().split(':');
              if (parts.length == 2) _openTimes[day] = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
            }
            if (o['close'] != null) {
              final parts = o['close'].toString().split(':');
              if (parts.length == 2) _closeTimes[day] = TimeOfDay(hour: int.tryParse(parts[0]) ?? 21, minute: int.tryParse(parts[1]) ?? 0);
            }
          }
        }
      }
    }
  }

  Future<void> _onCategoryChanged(String? value) async {
    setState(() { _selectedCategory = value; _selectedSubcategory = null; _subcategories = []; });
    if (value == null) return;
    final withSubs = await VeraApiService.instance.fetchCategoryWithSubs(value);
    final subs = withSubs?.subs ?? await VeraApiService.instance.fetchSubCategories(categoryId: value);
    if (!mounted || _selectedCategory != value) return;
    setState(() => _subcategories = subs);
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked != null && mounted) setState(() => _photos.add(picked));
  }

  int get _totalSteps => 7;
  void _next() {
    final missing = switch (_step) {
      0 => _selectedCategory == null || _selectedSubcategory == null || (_isRealEstate && _listingType == null),
      1 => _name.text.trim().isEmpty || _description.text.trim().isEmpty || (_isJobs && (_jobType == null || _salary.text.trim().isEmpty)),
      2 => _photos.isEmpty && _existingImage.isEmpty,
      3 => _city.text.trim().isEmpty || _address.text.trim().isEmpty || (_isRealEstate && _phone.text.trim().isEmpty),
      5 => _price.text.trim().isEmpty || double.tryParse(_price.text.replaceAll(',', '')) == null || (!_isRealEstate && _duration.text.trim().isEmpty),
      _ => false,
    };
    if (missing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }
    if (_step < _totalSteps - 1) setState(() => _step++); else _publish();
  }
  void _back() { if (_step == 0) context.pop(); else setState(() => _step--); }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(Map<String, TimeOfDay> map, String day, {bool isOpen = true}) async {
    final current = isOpen ? _openTimes[day]! : _closeTimes[day]!;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null && mounted) setState(() { if (isOpen) _openTimes[day] = picked; else _closeTimes[day] = picked; });
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      final uploadedImages = <String>[];
      for (final photo in _photos) {
        try {
          final url = await VeraApiService.instance.uploadImageBytes(
            await photo.readAsBytes(),
            filename: photo.name,
            type: 'services',
          );
          if (url == null || url.isEmpty) {
            throw StateError('Image upload returned no public URL');
          }
          uploadedImages.add(url);
        } catch (e) {
          throw StateError('Image upload failed: $e');
        }
      }
      final hours = <String, dynamic>{};
      for (final day in _workingDays.keys) {
        if (_workingDays[day]!) {
          hours[day] = {'open': _formatTime(_openTimes[day]!), 'close': _formatTime(_closeTimes[day]!)};
        }
      }
      final existingImages = <String>[
        if (_existingImage.isNotEmpty) _existingImage,
        ..._existingGallery,
      ];
      final allImages = <String>[...existingImages, ...uploadedImages];
      final payload = <String, dynamic>{
        'title': _name.text.trim(),
        'price': double.tryParse(_price.text.replaceAll(',', '')) ?? 0,
        'description': _description.text.trim(),
        'longDescription': _longDescription.text.trim().isNotEmpty ? _longDescription.text.trim() : null,
        'category': _selectedCategory,
        'category_slug': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'subcategory_slug': _selectedSubcategory,
        if (_isRealEstate && _listingType != null) 'listing_type': _listingType,
        if (!_isRealEstate) 'durationMinutes': int.tryParse(_duration.text) ?? 30,
        'address': _address.text.trim().isNotEmpty ? _address.text.trim() : null,
        'city': _city.text.trim().isNotEmpty ? _city.text.trim() : null,
        'phone': _phone.text.trim().isNotEmpty ? _phone.text.trim() : null,
        if (_selectedLat != null) 'latitude': _selectedLat,
        if (_selectedLng != null) 'longitude': _selectedLng,
        'workingHours': hours.isNotEmpty ? hours : null,
        'imageUrl': allImages.isNotEmpty ? allImages.first : null,
        'image_url': allImages.isNotEmpty ? allImages.first : null,
        'gallery': allImages.length > 1 ? allImages.sublist(1) : null,
        'images': allImages,
        if (_isJobs) ...{
          if (_jobType != null) 'job_type': _jobType,
          if (_salary.text.trim().isNotEmpty) 'salary': _salary.text.trim(),
        },
      };
      bool ok;
      if (_isEditMode) {
        print('[wizard] PATCH id=${widget.initialData!['id']} payload=$payload');
        ok = await VeraApiService.instance.updateProviderService(widget.initialData!['id'].toString(), payload);
      } else {
        print('[wizard] POST payload=$payload');
        final result = await VeraApiService.instance.createProviderService(payload);
        ok = result != null;
        print('[wizard] POST result=$result ok=$ok');
      }
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t(ok ? 'publishedSuccessfully' : 'publishFailed'))));
      if (ok) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).t('publishFailed')}\n$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final titles = [l.t('category'), l.t('serviceInformation'), l.t('photos'), l.t('location'), l.t('workingHours'), _isRealEstate ? l.t('price') : l.t('priceAndDuration'), l.t('preview')];
    return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: SafeArea(child: Column(children: [
      _header(l, titles[_step]),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: _page(l))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 18), child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
        onPressed: _saving ? null : _next,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPinkDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(_step == _totalSteps - 1 ? (_isEditMode ? l.t('updateService') : l.t('publish')) : l.t('continueText'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: Colors.white)),
      ))),
    ])));
  }

  Widget _header(AppLocalizations l, String title) => Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [AppBackButton(onTap: _back), const SizedBox(width: 12), Expanded(child: Text(_isEditMode ? l.t('editService') : l.t('addService'), style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800)))]),
    Text('${l.t('step')} ${_step + 1} ${l.t('of')} $_totalSteps', style: GoogleFonts.cairo(color: Theme.of(context).hintColor)),
    const SizedBox(height: 12),
    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (_step + 1) / _totalSteps, minHeight: 7, backgroundColor: AppTheme.tintPinkLight, color: AppTheme.primaryPinkDark)),
    const SizedBox(height: 18),
    Text(title, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800)),
  ]));

  Widget _page(AppLocalizations l) { switch (_step) { case 0: return _categoryPage(l); case 1: return _detailsPage(l); case 2: return _photosPage(l); case 3: return _locationPage(l); case 4: return _hoursPage(l); case 5: return _pricePage(l); default: return _previewPage(l); } }

  Widget _categoryPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l.t('category'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15)),
    const SizedBox(height: 12),
    _dropdown(l.t('category'), _selectedCategory, _categories.map((c) => DropdownMenuItem(value: c.slug, child: Text(l.isArabic ? c.name : c.enName))).toList(), _onCategoryChanged),
    const SizedBox(height: 14),
    if (_subcategories.isNotEmpty)
      _dropdown(l.t('subcategory'), _selectedSubcategory, _subcategories.map((c) => DropdownMenuItem(value: c.slug, child: Text(l.isArabic ? c.name : c.enName))).toList(), (v) => setState(() => _selectedSubcategory = v)),
    if (_isRealEstate) ...[
      const SizedBox(height: 14),
      _dropdown(
        l.isArabic ? 'نوع العرض' : 'Listing type',
        _listingType,
        [
          DropdownMenuItem(value: 'sale', child: Text(l.isArabic ? 'للبيع' : 'For sale')),
          DropdownMenuItem(value: 'rent', child: Text(l.isArabic ? 'للإيجار' : 'For rent')),
        ],
        (v) => setState(() => _listingType = v),
      ),
    ],
  ]);

  Widget _detailsPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _field(l.t('serviceName'), _name),
    _field(l.description, _description, maxLines: 2),
    _field('Detailed description (optional)', _longDescription, maxLines: 6),
    if (_isJobs) ...[
      _dropdown('Employment Type', _jobType, const [
        DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
        DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
        DropdownMenuItem(value: 'Contract', child: Text('Contract')),
        DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
        DropdownMenuItem(value: 'Internship', child: Text('Internship')),
        DropdownMenuItem(value: 'Remote', child: Text('Remote')),
      ], (v) => setState(() => _jobType = v)),
      _field('Salary Range (optional)', _salary),
    ],
  ]);

  Widget _photosPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Add up to 3 photos', style: GoogleFonts.cairo(color: Theme.of(context).hintColor, fontSize: 13)),
    const SizedBox(height: 16),
    Wrap(spacing: 10, runSpacing: 10, children: [
      ..._photos.asMap().entries.map((e) => Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(e.value.path), width: 100, height: 120, fit: BoxFit.cover)),
        Positioned(right: 4, top: 4, child: GestureDetector(onTap: () => setState(() => _photos.removeAt(e.key)), child: const CircleAvatar(radius: 12, backgroundColor: Colors.black87, child: Icon(Icons.close, size: 14, color: Colors.white)))),
      ])),
      if (_photos.length < 3) GestureDetector(onTap: _pickPhoto, child: Container(width: 100, height: 120, decoration: BoxDecoration(border: Border.all(color: AppTheme.borderMedium, width: 2), borderRadius: BorderRadius.circular(12)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, size: 28, color: AppTheme.goldAccent), SizedBox(height: 4), Text('Add', style: TextStyle(fontSize: 11, color: AppTheme.goldAccent))]))),
    ]),
  ]);

  Widget _locationPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _field('City', _city),
    PlaceAutocompleteField(
      controller: _address,
      hintText: 'Search address (e.g. Sheikh Zayed Road, Dubai)...',
      country: 'ae',
      onSelected: (result) {
        setState(() {
          _selectedLat = result?.lat;
          _selectedLng = result?.lng;
          if (result?.city != null && _city.text.isEmpty) {
            _city.text = result!.city!;
          }
        });
      },
    ),
    const SizedBox(height: 14),
    if (_isRealEstate) _field('Contact Phone', _phone),
    const SizedBox(height: 16),
    Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.tintBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _selectedLat != null && _selectedLng != null
            ? _buildMiniMap()
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_on_rounded, size: 42, color: AppTheme.primaryPinkDark),
                const SizedBox(height: 8),
                Text('Search address to see on map', style: GoogleFonts.cairo(color: AppTheme.grayText, fontSize: 12)),
                if (_address.text.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8, left: 16, right: 16), child: Text(_address.text, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.charcoal), textAlign: TextAlign.center)),
              ]),
      ),
    ),
  ]);

  Widget _buildMiniMap() {
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(_selectedLat!, _selectedLng!), zoom: 15),
        markers: {
          Marker(markerId: const MarkerId('selected'), position: LatLng(_selectedLat!, _selectedLng!)),
        },
        zoomControlsEnabled: false,
        scrollGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        myLocationEnabled: false,
        liteModeEnabled: true,
      );
    } catch (e) {
      return Center(child: Text('Map unavailable', style: GoogleFonts.cairo(color: AppTheme.grayText)));
    }
  }

  Widget _hoursPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l.t('workingDays'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15)),
    const SizedBox(height: 12),
    ..._workingDays.keys.map((day) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
      child: Row(children: [
        Switch(
          value: _workingDays[day]!,
          onChanged: (v) => setState(() => _workingDays[day] = v),
          activeColor: AppTheme.primaryPinkDark,
        ),
        const SizedBox(width: 8),
        SizedBox(width: 65, child: Text(day.substring(0, 3), style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13))),
        const Spacer(),
        if (_workingDays[day]!) ...[
          GestureDetector(
            onTap: () => _pickTime(_openTimes, day, isOpen: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.tintPinkLight, borderRadius: BorderRadius.circular(6)),
              child: Text(_formatTime(_openTimes[day]!), style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('-', style: GoogleFonts.cairo(fontWeight: FontWeight.w700))),
          GestureDetector(
            onTap: () => _pickTime(_closeTimes, day, isOpen: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.tintPinkLight, borderRadius: BorderRadius.circular(6)),
              child: Text(_formatTime(_closeTimes[day]!), style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    )),
  ]);

  Widget _pricePage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _field('Price (AED)', _price, number: true),
    if (!_isRealEstate) _field('Duration (minutes)', _duration, number: true),
  ]);

  Widget _previewPage(AppLocalizations l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _summary('Category', _selectedCategory ?? '-'),
    _summary('Name', _name.text),
    _summary('Description', _description.text),
    if (_longDescription.text.isNotEmpty) _summary('Long description', _longDescription.text.length > 60 ? '${_longDescription.text.substring(0, 60)}...' : _longDescription.text),
    _summary('Price', 'AED ${_price.text}'),
    if (!_isRealEstate) _summary('Duration', '${_duration.text} min'),
    if (_isRealEstate && _listingType != null)
      _summary('Listing type', _listingType == 'sale' ? 'For sale' : 'For rent'),
    if (_city.text.isNotEmpty) _summary('City', _city.text),
    if (_address.text.isNotEmpty) _summary('Address', _address.text),
    _summary('Photos', '${_photos.length}'),
    _summary('Working days', _workingDays.entries.where((e) => e.value).map((e) => e.key.substring(0, 3)).join(', ')),
    const SizedBox(height: 16),
    Text(l.t('reviewBeforePublish'), style: GoogleFonts.cairo(color: Theme.of(context).hintColor)),
  ]);

  Widget _summary(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(a, style: GoogleFonts.cairo(color: Theme.of(context).hintColor, fontSize: 13)),
    Flexible(child: Text(b.isEmpty ? '-' : b, textAlign: TextAlign.end, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13))),
  ]));

  Widget _field(String label, TextEditingController c, {bool number = false, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(
    controller: c, maxLines: maxLines,
    keyboardType: number ? TextInputType.number : null,
    inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
    decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 12)),
  ));

  Widget _dropdown(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
    value: value, items: items, onChanged: onChanged,
    decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
  );
}
