import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../services/vera_api_service.dart';
import '../../../theme/app_theme.dart';

class BookingFlowSheetArgs {
  const BookingFlowSheetArgs({
    required this.serviceId,
    required this.serviceName,
    required this.category,
    this.providerId,
    this.providerName,
    this.price = 0,
  });

  final String serviceId;
  final String serviceName;
  final String category;
  final String? providerId;
  final String? providerName;
  final double price;
}

/// Creates only a checkout session. The backend creates the booking after a
/// verified payment webhook.
Future<Map<String, dynamic>?> createBookingAndPay({
  required String serviceId,
  required String date,
  required String time,
  String? notes,
  String? serviceName,
  String? providerId,
  String? providerName,
  String? category,
  double? amount,
}) async {
  final sessionResult = await VeraApiService.instance.createCheckoutSession(
    idempotencyKey: 'booking-${serviceId}-${date}-${time}-${DateTime.now().microsecondsSinceEpoch}',
    paymentMethod: 'card',
    total: amount ?? 0,
    items: const [],
    kind: 'booking',
    booking: {
      'service_id': serviceId,
      'service_name': serviceName,
      'provider_id': providerId,
      'provider_name': providerName,
      'service_category': category,
      'booking_date': date,
      'booking_time': time,
      'notes': notes,
    },
  );
  final session = sessionResult?['checkout_session'] as Map<String, dynamic>?;
  final sessionId = session?['id']?.toString();
  if (sessionId == null || sessionId.isEmpty) return sessionResult;
  final init = await VeraApiService.instance.initiatePayment(
    amount: amount ?? 0,
    method: 'card',
    checkoutSessionId: sessionId,
    currency: 'AED',
  );
  final url = init?['checkout_url']?.toString() ??
      init?['checkoutUrl']?.toString() ??
      '';
  if (url.isNotEmpty) {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
  return {
    ...?sessionResult,
    'checkout_session': session,
    'payment': init,
  };
}

/// Reusable booking bottom sheet: date/time selection -> Confirm & Pay.
Future<void> showBookingFlowSheet(
  BuildContext context, {
  required BookingFlowSheetArgs args,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingFlowSheet(args: args),
  );
}

class _BookingFlowSheet extends StatefulWidget {
  const _BookingFlowSheet({required this.args});

  final BookingFlowSheetArgs args;

  @override
  State<_BookingFlowSheet> createState() => _BookingFlowSheetState();
}

class _BookingFlowSheetState extends State<_BookingFlowSheet> {
  static const List<String> _timeSlots = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
    '4:30 PM',
  ];

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    l10n.bookAppointment,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  _serviceCard(),
                  const SizedBox(height: 20),
                  Text(
                    l10n.t('selectDate'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _datePicker(),
                  const SizedBox(height: 20),
                  Text(
                    l10n.t('selectTime'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeSlots.map((slot) {
                      final isSelected = _selectedTime == slot;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryPinkDark
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryPinkDark
                                  : AppTheme.borderLight,
                            ),
                          ),
                          child: Text(
                            slot,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.charcoal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _confirmButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryPinkLight.withAlpha(60),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_services_outlined,
              size: 28, color: AppTheme.charcoal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.args.serviceName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                if ((widget.args.providerName ?? '').isNotEmpty)
                  Text(
                    widget.args.providerName!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.grayText,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.args.price > 0)
            Text(
              '${widget.args.price.toStringAsFixed(widget.args.price == widget.args.price.roundToDouble() ? 0 : 2)} AED',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryPinkDark,
              ),
            )
          else
            Text(
              AppLocalizations.of(context).t('freeLabel'),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
        ],
      ),
    );
  }

  Widget _datePicker() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (_, di) {
          final date = DateTime.now().add(Duration(days: di + 1));
          final isSelected =
              _selectedDate.day == date.day && _selectedDate.month == date.month;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryPinkDark
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryPinkDark
                      : AppTheme.borderLight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[date.weekday - 1],
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppTheme.grayText,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _submitting ? null : _confirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPinkDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                widget.args.price > 0 ? AppLocalizations.of(context).t('confirmAndPay') : AppLocalizations.of(context).t('confirmBooking'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('pleaseSelectTimeSlot'))),
      );
      return;
    }
    setState(() => _submitting = true);
    final date = _formatDate(_selectedDate);
    final result = await createBookingAndPay(
      serviceId: widget.args.serviceId,
      date: date,
      time: _selectedTime,
      serviceName: widget.args.serviceName,
      providerId: widget.args.providerId,
      providerName: widget.args.providerName,
      category: widget.args.category,
      amount: widget.args.price,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('couldNotConfirmBooking'))),
      );
      return;
    }

    final payment = result['payment'] as Map<String, dynamic>?;
    final checkoutUrl = payment?['checkout_url']?.toString() ??
        payment?['checkoutUrl']?.toString() ??
        '';
    if (checkoutUrl.isNotEmpty) {
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('couldNotConfirmBooking'))),
    );
    /* showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPinkLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 36,
                    color: AppTheme.primaryPinkDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('bookingConfirmed'),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.t('appointmentBookedSuccess'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.grayText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (ctx.mounted) {
                        ctx.go(AppRoutes.myAppointmentsScreen);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPinkDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(l10n.t('viewMyAppointments')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      return;
    }

    // Paid booking: Stripe opened in browser; deep link returns the user.
    Navigator.pop(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.t('completePaymentInBrowser')),
      ),
      ); */
    }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
