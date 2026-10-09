import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../services/vera_api_service.dart';
import '../../core/auth_gate.dart';
import '../../routes/app_routes.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with AuthGuard {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final allBookings = await VeraApiService.instance.fetchMyBookings();
      if (!mounted) return;
      final upcoming = <Map<String, dynamic>>[];
      final past = <Map<String, dynamic>>[];
      for (final b in allBookings) {
        final mapped = _bookingToMap(b);
        final rawStatus = mapped['rawStatus'] as String;
        final isPast = rawStatus.contains('completed') ||
            rawStatus.contains('done') ||
            rawStatus.contains('cancel');
        if (isPast) {
          past.add(mapped);
        } else {
          upcoming.add(mapped);
        }
      }
      setState(() {
        _upcomingBookings = upcoming;
        _pastBookings = past;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _upcomingBookings = [];
        _pastBookings = [];
        _isLoading = false;
        _error = null;
      });
    }
  }

  Map<String, dynamic> _bookingToMap(VeraBooking b) {
    return {
      'id': b.id,
      'service': b.serviceName,
      'provider': b.providerName,
      'date': b.date,
      'time': b.time,
      'rawStatus': b.status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim(),
      'status': _capitalizeStatus(b.status),
      'statusColor': _colorForStatus(b.status),
      'price': b.price,
      'category': b.category,
      'categoryColor': _bgColorForCategory(b.category),
      'icon': _iconForCategory(b.category),
      'image': b.imageUrl,
      'canCancel': _isCancellableStatus(b.status),
      'isCancelled': _isCancelled(b.status),
    };
  }

  bool _isCancellableStatus(String status) {
    final s = status.toLowerCase();
    return s.contains('pending') || s.contains('confirmed') || s.contains('booked');
  }

  bool _isCancelled(String status) {
    final s = status.toLowerCase();
    return s.contains('cancel') || s.contains('reject');
  }

  int _stepIndex(String rawStatus) {
    final s = rawStatus.toLowerCase();
    if (s.contains('cancel') || s.contains('reject')) return -1;
    if (s.contains('completed') || s.contains('done') || s.contains('fulfilled')) return 3;
    if (s.contains('in progress') || s.contains('inprogress') || s.contains('active')) return 2;
    if (s.contains('confirmed') || s.contains('booked') || s.contains('reserved')) return 1;
    return 0;
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
      case 'done':
        return AppTheme.success;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  Color _bgColorForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('clinic') || c.contains('medical')) return AppTheme.clinicsBg;
    if (c.contains('salon') || c.contains('beauty')) return AppTheme.salonsBg;
    if (c.contains('gym') || c.contains('fitness')) return AppTheme.gymBg;
    if (c.contains('spa')) return AppTheme.salonsBg;
    return AppTheme.fashionBg;
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('clinic') || c.contains('medical')) return Icons.medical_services_outlined;
    if (c.contains('salon') || c.contains('beauty')) return Icons.face_retouching_natural;
    if (c.contains('gym') || c.contains('fitness')) return Icons.fitness_center_rounded;
    if (c.contains('spa')) return Icons.self_improvement_rounded;
    return Icons.calendar_today_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError(l10n)
                      : _buildContent(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.charcoal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myBookings,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l10n.t('manageYourAppointments'),
                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.grayText),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.bookingScreen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.clinicsBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: AppTheme.clinics),
                  const SizedBox(width: 4),
                  Text(
                    l10n.t('book'),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.clinics,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final all = [..._upcomingBookings, ..._pastBookings];
    if (all.isEmpty) {
      return _buildEmpty(l10n);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        if (_upcomingBookings.isNotEmpty) ...[
          Text(
            l10n.upcoming,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.grayText,
            ),
          ),
          const SizedBox(height: 10),
          ..._upcomingBookings.map(
            (b) => _BookingCard(
              booking: b,
              l10n: l10n,
              onCancel: () => _cancelBooking(b, l10n),
              onReschedule: () {},
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_pastBookings.isNotEmpty) ...[
          Text(
            l10n.past,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.grayText,
            ),
          ),
          const SizedBox(height: 10),
          ..._pastBookings.map(
            (b) => _BookingCard(booking: b, l10n: l10n),
          ),
        ],
      ],
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.grayText),
          const SizedBox(height: 12),
          Text(l10n.t('errorLoadBookings'),
              style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadBookings,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryPinkDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(l10n.retry,
                  style: GoogleFonts.cairo(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppTheme.clinicsBg, shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today_outlined, size: 32, color: AppTheme.clinics),
          ),
          const SizedBox(height: 16),
          Text(l10n.t('noUpcomingBookings'),
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
          const SizedBox(height: 6),
          Text(l10n.t('bookToGetStarted'),
              style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText)),
        ],
      ),
    );
  }

  void _cancelBooking(Map<String, dynamic> booking, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.t('cancelBooking'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text(l10n.t('cancelBookingConfirm', args: {'service': booking['service'] ?? ''}),
            style: GoogleFonts.cairo(color: AppTheme.grayText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.t('keep'), style: GoogleFonts.cairo(color: AppTheme.grayText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.t('cancelBooking'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await VeraApiService.instance.cancelBooking(booking['id'] as String? ?? '');
    setState(() {
      _upcomingBookings.removeWhere((b) => b['id'] == booking['id']);
      final cancelled = Map<String, dynamic>.from(booking);
      cancelled['status'] = 'Cancelled';
      cancelled['rawStatus'] = 'cancelled';
      cancelled['statusColor'] = AppTheme.error;
      cancelled['canCancel'] = false;
      cancelled['isCancelled'] = true;
      _pastBookings.insert(0, cancelled);
    });
  }
}

// ══════════════════════════════════════════════════════════════════
// BOOKING CARD WITH STEPPER
// ══════════════════════════════════════════════════════════════════

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final AppLocalizations l10n;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const _BookingCard({
    required this.booking,
    required this.l10n,
    this.onCancel,
    this.onReschedule,
  });

  static const _stepIcons = [
    Icons.calendar_today_outlined,      // Booked
    Icons.check_circle_outline,         // Confirmed
    Icons.play_circle_outline,          // In Progress
    Icons.emoji_events_outlined,        // Completed
  ];

  static const _stepIconsDone = [
    Icons.calendar_today_rounded,
    Icons.check_circle_rounded,
    Icons.play_circle_rounded,
    Icons.emoji_events_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final cancelledRed = const Color(0xFFFF5C5C);
    final isCancelled = booking['isCancelled'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled ? cancelledRed.withAlpha(60) : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: Icon + Service Info ──────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['service'] as String? ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking['provider'] as String? ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            l10n.currencyAed(booking['price']?.toString() ?? '0'),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const Spacer(),
                          if (onCancel != null)
                            GestureDetector(
                              onTap: onCancel,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cancelledRed.withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.cancel,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: cancelledRed,
                                  ),
                                ),
                              ),
                            ),
                          if (onReschedule != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: onReschedule,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.t('reschedule'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Date + Time row ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withAlpha(8)
                : AppTheme.ivoryLight,
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.grayText),
                const SizedBox(width: 6),
                Text(booking['date'] ?? '', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.charcoal)),
                const SizedBox(width: 14),
                Icon(Icons.access_time_rounded, size: 14, color: AppTheme.grayText),
                const SizedBox(width: 6),
                Text(booking['time'] ?? '', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.charcoal)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Stepper ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: isCancelled
                ? _buildCancelledBar()
                : _buildStepper(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final categoryColor = booking['categoryColor'] as Color? ?? AppTheme.clinicsBg;
    final icon = booking['icon'] as IconData? ?? Icons.calendar_today_outlined;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: categoryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: AppTheme.charcoal),
    );
  }

  Widget _buildStepper() {
    final green = const Color(0xFF34C759);
    final blue = const Color(0xFF5DADE2);
    final gray = AppTheme.grayLight;
    final rawStatus = booking['rawStatus'] as String? ?? '';
    final currentStep = _stepIndex(rawStatus);

    final labels = [
      l10n.t('booked'),
      l10n.t('confirmed'),
      l10n.t('inProgress'),
      l10n.t('completed'),
    ];

    return Row(
      children: List.generate(4, (i) {
        final isDone = i < currentStep;
        final isActive = i == currentStep;

        Color dotColor;
        if (isDone) {
          dotColor = green;
        } else if (isActive) {
          dotColor = blue;
        } else {
          dotColor = gray;
        }

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? green : gray.withAlpha(100),
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone
                          ? green
                          : isActive
                              ? blue.withAlpha(30)
                              : gray.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(color: dotColor, width: isActive ? 2 : 1.5),
                    ),
                    child: Icon(
                      isDone ? _BookingCard._stepIconsDone[i] : _BookingCard._stepIcons[i],
                      size: 14,
                      color: dotColor,
                    ),
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? green : gray.withAlpha(100),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: GoogleFonts.cairo(
                  fontSize: 9,
                  fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                  color: isDone ? green : isActive ? blue : AppTheme.grayText,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  int _stepIndex(String rawStatus) {
    final s = rawStatus.toLowerCase();
    if (s.contains('cancel') || s.contains('reject')) return -1;
    if (s.contains('completed') || s.contains('done') || s.contains('fulfilled')) return 3;
    if (s.contains('in progress') || s.contains('inprogress') || s.contains('active')) return 2;
    if (s.contains('confirmed') || s.contains('booked') || s.contains('reserved')) return 1;
    return 0;
  }

  Widget _buildCancelledBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C5C).withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFFF5C5C)),
          const SizedBox(width: 8),
          Text(
            l10n.cancelled,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF5C5C),
            ),
          ),
        ],
      ),
    );
  }
}
