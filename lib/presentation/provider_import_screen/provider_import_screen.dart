import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class ProviderImportScreen extends StatefulWidget {
  const ProviderImportScreen({super.key});
  @override
  State<ProviderImportScreen> createState() => _ProviderImportScreenState();
}

class _ProviderImportScreenState extends State<ProviderImportScreen> with ProviderGuard {
  final List<_ImportRow> _rows = [];
  bool _reading = false;
  bool _importing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx', 'xls']);
    final file = result?.files.single;
    final path = file?.path;
    if (path == null) return;
    setState(() { _reading = true; _rows.clear(); });
    try {
      final bytes = await File(path).readAsBytes();
      final List<List<String>> values;
      if (file?.extension?.toLowerCase() == 'csv') {
        values = const LineSplitter()
            .convert(utf8.decode(bytes))
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.split(',').map((cell) => cell.trim()).toList())
            .toList();
      } else {
        final workbook = Excel.decodeBytes(bytes);
        final sheet = workbook.tables.values.first;
        values = sheet.rows
            .map((row) => row.map((cell) => cell?.value.toString().trim() ?? '').toList())
            .toList();
      }
      if (values.isEmpty) throw const FormatException('empty');
      final headers = values.first.map((c) => c.toLowerCase()).toList();
      final nameIndex = _index(headers, ['name', 'product name', 'product_name']);
      final priceIndex = _index(headers, ['price', 'price aed', 'price_aed']);
      final categoryIndex = _index(headers, ['category', 'category name', 'category_name']);
      final parsed = <_ImportRow>[];
      for (var i = 1; i < values.length; i++) {
        final row = values[i];
        final name = _cell(row, nameIndex);
        final price = _cell(row, priceIndex);
        final category = _cell(row, categoryIndex);
        final issues = <String>[];
        if (name.isEmpty) issues.add('name');
        if (double.tryParse(price) == null) issues.add('price');
        if (category.isEmpty) issues.add('category');
        parsed.add(_ImportRow({'name': name, 'price': double.tryParse(price) ?? 0, 'category': category}, issues));
      }
      if (!mounted) return;
      setState(() { _rows.addAll(parsed); _reading = false; });
    } catch (_) {
      if (mounted) setState(() { _reading = false; _rows.add(_ImportRow({}, ['file'])); });
    }
  }

  int _index(List<String> headers, List<String> names) => headers.indexWhere(names.contains);
  String _cell(List<String> row, int index) => index >= 0 && index < row.length ? row[index].trim() : '';

  Future<void> _import() async {
    final valid = _rows.where((r) => r.issues.isEmpty).toList();
    if (valid.isEmpty) return;
    setState(() => _importing = true);
    for (final row in valid) {
      await VeraApiService.instance.createProviderProduct(row.data);
    }
    if (!mounted) return;
    setState(() => _importing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('importCompleted'))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ready = _rows.where((r) => r.issues.isEmpty).length;
    final review = _rows.where((r) => r.issues.isNotEmpty && !r.issues.contains('file')).length;
    final errors = _rows.where((r) => r.issues.contains('file')).length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l.t('importExcelCsv'), style: GoogleFonts.cairo(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('importValidationHint'), style: GoogleFonts.cairo(color: Theme.of(context).hintColor)),
          const SizedBox(height: 14),
          Row(children: [_stat(l.t('ready'), ready, AppTheme.success), _stat(l.t('needReview'), review, AppTheme.warning), _stat(l.t('error'), errors, AppTheme.error)]),
        ])),
        Expanded(child: _reading ? const Center(child: CircularProgressIndicator()) : _rows.isEmpty ? _empty(l) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _rows.length, itemBuilder: (_, i) => _rowCard(_rows[i], i + 1, l))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 18), child: Row(children: [Expanded(child: OutlinedButton(onPressed: _reading ? null : _pickFile, child: Text(l.t('chooseFile')))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: _importing || ready == 0 ? null : _import, child: _importing ? const CircularProgressIndicator(color: Colors.white) : Text(l.t('importReady'))))])),
      ]),
    );
  }

  Widget _stat(String label, int value, Color color) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$value', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: color)), Text(label, style: GoogleFonts.cairo(fontSize: 11, color: color))])));
  Widget _empty(AppLocalizations l) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_file_outlined, size: 52, color: AppTheme.grayText), const SizedBox(height: 12), Text(l.t('chooseFileToValidate'), style: GoogleFonts.cairo(color: AppTheme.grayText))]));
  Widget _rowCard(_ImportRow row, int number, AppLocalizations l) { final isError = row.issues.contains('file'); final color = isError ? AppTheme.error : row.issues.isEmpty ? AppTheme.success : AppTheme.warning; final status = isError ? l.t('error') : row.issues.isEmpty ? l.t('ready') : l.t('needReview'); return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withAlpha(70))), child: Row(children: [CircleAvatar(radius: 17, backgroundColor: color.withAlpha(20), child: Text('$number', style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(row.data['name']?.toString().isNotEmpty == true ? row.data['name'].toString() : l.t('invalidRow'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)), if (row.issues.isNotEmpty) Text(row.issues.join(', '), style: GoogleFonts.cairo(fontSize: 11, color: color))])), Text(status, style: GoogleFonts.cairo(fontSize: 11, color: color, fontWeight: FontWeight.w700))])); }
}

class _ImportRow {
  final Map<String, dynamic> data;
  final List<String> issues;
  const _ImportRow(this.data, this.issues);
}
