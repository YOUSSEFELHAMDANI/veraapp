import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../services/vera_api_service.dart';
import '../../core/auth_gate.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with AuthGuard {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await VeraApiService.instance.fetchMyBookings();
      if (!mounted) return;
      setState(() {
        _appointments = bookings.map(_bookingToMap).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appointments = [];
        _isLoading = false;
        _error = null;
      });
    }
  }

  Map<String, dynamic> _bookingToMap(VeraBooking b) {
    return {
      'id': b.id,
      'clinic': b.providerName,
      'service': b.serviceName,
      'date': b.date,
      'time': b.time,
      'rawStatus': b.status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim(),
      'status': _capitalizeStatus(b.status),
      'statusColor': _colorForStatus(b.status),
      'icon': _iconForCategory(b.category),
      'category': b.category,
      'isCancelled': _isCancelled(b.status),
    };
  }

  bool _isCancelled(String status) {
    final s = status.toLowerCase();
    return s.contains('cancel') || s.contains('reject');
  }

  int _stepIndex(String rawStatus) {
    final s = rawStatus.toLowerCase();
    if (s.contains('cancel') || s.contains('reject')) return -1;
    if (s.contains('completed') || s.contains('done') || s.contains('fulfilled')) return 3;
    if (s.contains('in progress') || s.contains('inprogress') || s.contains('active') || s.contains('arrived')) return 2;
    if (s.contains('confirmed') || s.contains('booked') || s.contains('reserved')) return 1;
    return 0;
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Color _colorForStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'done') return const Color(0xFF34C759);
    if (s == 'confirmed' || s == 'upcoming') return const Color(0xFF5DADE2);
    if (s == 'cancelled' || s == 'canceled' || s.contains('reject')) return const Color(0xFFFF5C5C);
    return const Color(0xFFC8A96A);
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('clinic') || c.contains('medical')) return Icons.local_hospital_outlined;
    if (c.contains('salon') || c.contains('beauty') || c.contains('hair')) return Icons.content_cut_rounded;
    if (c.contains('dental') || c.contains('dentist')) return Icons.health_and_safety_outlined;
    if (c.contains('spa') || c.contains('massage')) return Icons.spa_rounded;
    if (c.contains('gym') || c.contains('fitness')) return Icons.fitness_center_rounded;
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
                      : _appointments.isEmpty
                          ? _buildEmpty(l10n)
                          : _buildList(l10n),
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
                  l10n.myAppointments,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  '${_appointments.length} ${l10n.t('appointments')}',
                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.grayText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
          Text(l10n.t('errorLoadAppointments'),
              style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
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
          Icon(Icons.calendar_today_outlined, size: 56, color: AppTheme.grayLight),
          const SizedBox(height: 12),
          Text(l10n.t('noAppointments'),
              style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.grayText)),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    final upcoming = _appointments.where((a) => !_isFinished(a['rawStatus'] as String)).toList();
    final past = _appointments.where((a) => _isFinished(a['rawStatus'] as String)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        if (upcoming.isNotEmpty) ...[
          Text(
            l10n.upcoming,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.grayText,
            ),
          ),
          const SizedBox(height: 10),
          ...upcoming.map((a) => _AppointmentCard(appointment: a, l10n: l10n)),
          const SizedBox(height: 20),
        ],
        if (past.isNotEmpty) ...[
          Text(
            l10n.past,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.grayText,
            ),
          ),
          const SizedBox(height: 10),
          ...past.map((a) => _AppointmentCard(appointment: a, l10n: l10n)),
        ],
      ],
    );
  }

  bool _isFinished(String rawStatus) {
    return rawStatus.contains('completed') ||
        rawStatus.contains('done') ||
        rawStatus.contains('cancel') ||
        rawStatus.contains('fulfilled');
  }
}

// ══════════════════════════════════════════════════════════════════
// APPOINTMENT CARD WITH STEPPER
// ══════════════════════════════════════════════════════════════════

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final AppLocalizations l10n;

  const _AppointmentCard({required this.appointment, required this.l10n});

  static const _stepIcons = [
    Icons.calendar_today_outlined,      // Booked
    Icons.check_circle_outline,         // Confirmed
    Icons.person_outline,              // Arrived
    Icons.emoji_events_outlined,        // Completed
  ];

  static const _stepIconsDone = [
    Icons.calendar_today_rounded,
    Icons.check_circle_rounded,
    Icons.person_rounded,
    Icons.emoji_events_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final cancelledRed = const Color(0xFFFF5C5C);
    final isCancelled = appointment['isCancelled'] as bool? ?? false;

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
          // ── Top: Icon + Info ──────────────────────────────
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
                        appointment['service'] as String? ?? '',
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
                        appointment['clinic'] as String? ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Date + Time ──────────────────────────────────
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
                Text(appointment['date'] ?? '', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.charcoal)),
                const SizedBox(width: 14),
                Icon(Icons.access_time_rounded, size: 14, color: AppTheme.grayText),
                const SizedBox(width: 6),
                Text(appointment['time'] ?? '', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.charcoal)),
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
    final icon = appointment['icon'] as IconData? ?? Icons.calendar_today_outlined;
    final statusColor = appointment['statusColor'] as Color? ?? AppTheme.warning;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: statusColor),
    );
  }

  Widget _buildStepper() {
    final green = const Color(0xFF34C759);
    final blue = const Color(0xFF5DADE2);
    final gray = AppTheme.grayLight;
    final rawStatus = appointment['rawStatus'] as String? ?? '';
    final currentStep = _stepIndex(rawStatus);

    final labels = [
      l10n.t('booked'),
      l10n.t('confirmed'),
      l10n.t('arrived'),
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
                      isDone ? _AppointmentCard._stepIconsDone[i] : _AppointmentCard._stepIcons[i],
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
    if (s.contains('in progress') || s.contains('active') || s.contains('arrived')) return 2;
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
