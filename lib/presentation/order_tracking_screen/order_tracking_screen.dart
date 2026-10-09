import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? tracking;
  String? error;
  bool loading = true;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final result = await VeraApiService.instance.fetchOrderTracking(widget.orderId);
    if (!mounted) return;
    setState(() { tracking = result; error = result == null ? 'تعذر تحميل حالة الطلب' : null; loading = false; });
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.backgroundLight,
    appBar: AppBar(title: Text('تتبع الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)), backgroundColor: AppTheme.backgroundLight, elevation: 0),
    body: loading ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink)) : error != null ? Center(child: Text(error!, style: GoogleFonts.cairo())) : _body(),
  );

  Widget _body() {
    final data = tracking!['data'] is Map ? tracking!['data'] as Map : tracking!;
    final timeline = data['timeline'] is List ? data['timeline'] as List : <dynamic>[];
    final carrier = data['carrierTracking'] is Map ? data['carrierTracking'] as Map : null;
    final carrierEvents = carrier?['events'] is List ? carrier!['events'] as List : <dynamic>[];
    final awb = data['tracking_number'] ?? data['trackingNumber'] ?? data['awb'] ?? '';
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
      _card('رقم الطلب', widget.orderId, Icons.receipt_long_outlined),
      if (awb.toString().isNotEmpty) _card('رقم الشحنة AWB', awb.toString(), Icons.local_shipping_outlined),
      _card('الحالة', (data['statusLabel'] ?? data['status'] ?? 'قيد المعالجة').toString(), Icons.track_changes_outlined),
      const SizedBox(height: 18),
      Text('تحديثات التوصيل', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      if (timeline.isEmpty) Text('لا توجد تحديثات بعد', style: GoogleFonts.cairo(color: AppTheme.grayText)),
      ...timeline.map((item) { final event = item is Map ? item : <dynamic, dynamic>{}; return ListTile(contentPadding: EdgeInsets.zero, leading: Icon(event['done'] == true ? Icons.check_circle : Icons.radio_button_unchecked, color: event['done'] == true ? AppTheme.primaryPink : AppTheme.grayText), title: Text((event['label'] ?? event['description'] ?? event['status'] ?? '').toString(), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)), subtitle: Text((event['time'] ?? event['date'] ?? '').toString(), style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.grayText))); }),
      ...carrierEvents.map((item) { final event = item is Map ? item : <dynamic, dynamic>{}; return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.local_shipping_outlined, color: AppTheme.primaryPink), title: Text((event['description'] ?? event['status'] ?? event['Status'] ?? '').toString(), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)), subtitle: Text((event['date'] ?? event['time'] ?? '').toString(), style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.grayText))); }),
    ]));
  }

  Widget _card(String label, String value, IconData icon) => Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: ListTile(leading: Icon(icon, color: AppTheme.primaryPink), title: Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.grayText)), subtitle: Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700))));
}
