import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../services/vera_api_service.dart';

class ProfileStatsWidget extends StatefulWidget {
  const ProfileStatsWidget({super.key});

  @override
  State<ProfileStatsWidget> createState() => _ProfileStatsWidgetState();
}

class _ProfileStatsWidgetState extends State<ProfileStatsWidget> {
  String _orders = '—';
  String _bookings = '—';
  String _points = '—';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Fetch all in parallel
    final results = await Future.wait([
      VeraApiService.instance.fetchProfile(),
      VeraApiService.instance.fetchLoyalty(),
      VeraApiService.instance.fetchOrders(),
      VeraApiService.instance.fetchMyBookings(),
    ]);

    if (!mounted) return;

    final user = results[0] as VeraUser?;
    final loyalty = results[1] as VeraLoyalty?;
    final orders = results[2] as List<VeraOrder>;
    final bookings = results[3] as List<VeraBooking>;

    setState(() {
      // Orders count (exclude cancelled)
      final activeOrders = orders
          .where((o) => !o.status.toLowerCase().contains('cancel'))
          .toList();
      if (activeOrders.isNotEmpty) {
        _orders = '${activeOrders.length}';
      } else if (user != null && user.ordersCount > 0) {
        _orders = '${user.ordersCount}';
      } else {
        _orders = '0';
      }

      // Bookings count (exclude cancelled)
      final activeBookings = bookings
          .where((b) => !b.status.toLowerCase().contains('cancel'))
          .toList();
      if (activeBookings.isNotEmpty) {
        _bookings = '${activeBookings.length}';
      } else if (user != null && user.bookingsCount > 0) {
        _bookings = '${user.bookingsCount}';
      } else {
        _bookings = '0';
      }

      // Loyalty points — prefer dedicated loyalty endpoint
      if (loyalty != null && loyalty.points > 0) {
        _points = loyalty.points >= 1000
            ? '${(loyalty.points / 1000).toStringAsFixed(1)}k'
            : '${loyalty.points}';
      } else if (user != null && user.loyaltyPoints > 0) {
        _points = user.loyaltyPoints >= 1000
            ? '${(user.loyaltyPoints / 1000).toStringAsFixed(1)}k'
            : '${user.loyaltyPoints}';
      } else {
        _points = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
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
          _StatItem(
            value: _orders,
            label: l10n.orders,
            icon: Icons.shopping_bag_outlined,
            color: AppTheme.primaryPinkDark,
          ),
          _Divider(),
          _StatItem(
            value: _bookings,
            label: l10n.bookings,
            icon: Icons.calendar_today_outlined,
            color: AppTheme.clinics,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.charcoal,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.grayText),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: AppTheme.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
