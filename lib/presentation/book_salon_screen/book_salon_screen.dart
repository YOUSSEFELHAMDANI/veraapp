import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../core/auth_gate.dart';
import '../booking_screen/widgets/booking_flow_sheet.dart';

class BookSalonScreen extends StatefulWidget {
  final Map<String, dynamic>? salonData;
  const BookSalonScreen({super.key, this.salonData});

  @override
  State<BookSalonScreen> createState() => _BookSalonScreenState();
}

class _BookSalonScreenState extends State<BookSalonScreen> with AuthGuard {
  int _currentStep = 0;

  // Step 1 — Service & Time
  String? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;

  // Step 2 — Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _timeSlots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

  Map<String, dynamic> get _salon => widget.salonData ?? const {};

  List<Map<String, dynamic>> get _services =>
      (_salon['services'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList() ??
      [];

  String get _selectedServicePrice {
    if (_selectedService == null) {
      return (_salon['price'] as String?) ?? '';
    }
    final s = _services.firstWhere(
      (s) => s['name'] == _selectedService,
      orElse: () => const {},
    );
    return (s['price'] as String?) ?? ((_salon['price'] as String?) ?? '');
  }

  @override
  void initState() {
    super.initState();
    final preselected = _salon['preselectedService'] as String?;
    if (preselected != null) _selectedService = preselected;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                    ? _buildStep2()
                    : _buildStep3(),
              ),
            ),
            _buildBottomActions(),
            ],
          ),
        ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bookAppointment,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  _salon['name'] as String? ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.grayText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final l10n = AppLocalizations.of(context);
    final steps = [l10n.t('serviceLabel'), l10n.t('detailsLabel'), l10n.confirm];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppTheme.salons
                              : AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? AppTheme.salons
                              : isDone
                              ? AppTheme.charcoal
                              : AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.h),
        Text(
          l10n.t('chooseAService'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        if (_services.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.cleaning_services_outlined,
                    size: 40,
                    color: AppTheme.grayText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('noServicesAvailable'),
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._services.map((service) {
          final isSelected = _selectedService == service['name'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedService = service['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.salonsBg : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isSelected ? AppTheme.salons : AppTheme.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.salons : AppTheme.salonsBg,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      size: 20,
                      color: isSelected ? Colors.white : AppTheme.salons,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        Text(
                          service['duration'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.localizePrice(service['price'] as String),
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.salons : AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isSelected ? AppTheme.salons : AppTheme.grayLight,
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: 2.h),
        Text(
          l10n.t('selectDate'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        _buildDatePicker(),
        SizedBox(height: 2.h),
        Text(
          l10n.t('selectTime'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = time),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.salons : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isSelected ? AppTheme.salons : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  time,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.charcoal,
            ),
          ),
        ),
      );
    }).toList(),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildDatePicker() {
    final now = DateTime.now();
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = now.add(Duration(days: index + 1));
          final isSelected =
              _selectedDate.day == date.day &&
              _selectedDate.month == date.month &&
              _selectedDate.year == date.year;
          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final dayName = dayNames[(date.weekday - 1) % 7];
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 52,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.salons : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? AppTheme.salons : AppTheme.borderLight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: isSelected ? Colors.white70 : AppTheme.grayText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
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

  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.h),
        Text(
          l10n.t('yourInformation'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        _buildTextField(
          _nameController,
          l10n.fullName,
          Icons.person_outline_rounded,
        ),
        SizedBox(height: 1.h),
        _buildTextField(
          _phoneController,
          l10n.phoneNumber,
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 1.h),
        _buildTextField(
          _emailController,
          l10n.email,
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 1.h),
        _buildTextField(
          _notesController,
          l10n.t('specialRequestsOptional'),
          Icons.notes_rounded,
          maxLines: 3,
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.cairo(fontSize: 13.sp, color: AppTheme.charcoal),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
            fontSize: 13.sp,
            color: AppTheme.grayText,
          ),
          prefixIcon: Icon(icon, size: 18, color: AppTheme.grayText),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    final l10n = AppLocalizations.of(context);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.h),
        Text(
          l10n.t('bookingSummary'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        SizedBox(height: 1.5.h),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              _buildSummaryRow(l10n.t('salonLabel'), _salon['name'] as String? ?? ''),
              Divider(color: AppTheme.borderLight, height: 20),
              _buildSummaryRow(l10n.t('serviceLabel'), _selectedService ?? l10n.t('notSelected')),
              Divider(color: AppTheme.borderLight, height: 20),
              _buildSummaryRow(
                l10n.t('dateAndTime'),
                '${_selectedDate.day} ${months[_selectedDate.month - 1]} · ${_selectedTime ?? l10n.t('notSelected')}',
              ),
              Divider(color: AppTheme.borderLight, height: 20),
              _buildSummaryRow(
                l10n.fullName,
                _nameController.text.isEmpty ? '—' : _nameController.text,
              ),
              Divider(color: AppTheme.borderLight, height: 20),
              _buildSummaryRow(
                l10n.t('phoneShort'),
                _phoneController.text.isEmpty ? '—' : _phoneController.text,
              ),
              Divider(color: AppTheme.borderLight, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.total,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Text(
                    _selectedServicePrice,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.salons,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 1.5.h),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.salonsBg,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppTheme.salons.withAlpha(60)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppTheme.salons,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.t('confirmationSmsEmail'),
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.charcoal,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 12.sp, color: AppTheme.grayText),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoal,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final l10n = AppLocalizations.of(context);
    final isLastStep = _currentStep == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 12, 4.w, 3.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppTheme.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (isLastStep) {
                  _showConfirmationDialog();
                } else {
                  setState(() => _currentStep++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.salons,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                isLastStep ? l10n.t('confirmBooking') : l10n.continueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    final l10n = AppLocalizations.of(context);
    final selectedService = _services.firstWhere(
      (s) => s['name'] == _selectedService,
      orElse: () => const {},
    );
    final serviceId =
        (selectedService['id'] as String?) ?? (_salon['id'] as String?);
    final serviceName = (selectedService['name'] as String?) ??
        (_salon['name'] as String?);
    final providerId = (_salon['providerId'] as String?) ??
        (_salon['provider_id'] as String?);
    final providerName = (_salon['providerName'] as String?) ??
        (_salon['provider'] as String?) ??
        'Véra';
    final priceStr =
        (selectedService['price'] ?? _salon['price'] ?? '0').toString();
    final price =
        double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final date =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final time = _selectedTime;
    if (serviceId == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('couldNotConfirmBooking')),
        ),
      );
      return;
    }
    try {
      final result = await createBookingAndPay(
        serviceId: serviceId,
        date: date,
        time: time,
        serviceName: serviceName,
        providerId: providerId,
        providerName: providerName,
        category: 'Salons',
        amount: price,
      );
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('couldNotConfirmBooking')),
          ),
        );
        return;
      }
      final status = result['status']?.toString() ?? '';
      final paidAmount =
          double.tryParse(result['amount']?.toString() ?? '') ?? 0.0;
      if (status != 'confirmed' && paidAmount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.t('completePaymentInBrowser'),
            ),
          ),
        );
        return;
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('couldNotConfirmBooking')),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
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
                  color: AppTheme.salonsBg,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 36,
                  color: AppTheme.salons,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('bookingConfirmed'),
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('salonBookingSuccess', args: {'name': _salon['name'] as String? ?? ''}),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/home-screen');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.salons,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  l10n.done,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
