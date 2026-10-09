import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../core/auth_gate.dart';
import '../booking_screen/widgets/booking_flow_sheet.dart';

class BookPropertyScreen extends StatefulWidget {
  final Map<String, dynamic>? propertyData;
  const BookPropertyScreen({super.key, this.propertyData});

  @override
  State<BookPropertyScreen> createState() => _BookPropertyScreenState();
}

class _BookPropertyScreenState extends State<BookPropertyScreen> with AuthGuard {
  int _currentStep = 0;
  DateTime? _selectedDate;
  String _selectedTime = '10:00 AM';
  String _visitType = 'In-Person';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _submitted = false;

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];
  final List<String> _visitTypes = ['In-Person', 'Virtual Tour'];

  Map<String, dynamic> get _property => widget.propertyData ?? const {};

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
    final l10n = AppLocalizations.of(context);
    if (_submitted) return _buildSuccessScreen();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppTheme.charcoal,
            ),
          ),
        ),
        title: Text(
          l10n.bookViewing,
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _currentStep == 0
                  ? _buildDateTimeStep()
                  : _currentStep == 1
                  ? _buildPersonalInfoStep()
                  : _buildReviewStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final l10n = AppLocalizations.of(context);
    final steps = [l10n.t('scheduleLabel'), l10n.t('detailsLabel'), l10n.t('reviewLabel')];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.success
                            : isActive
                            ? AppTheme.primaryPinkDark
                            : AppTheme.borderLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.grayText,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 9.sp,
                        color: isActive
                            ? AppTheme.primaryPinkDark
                            : AppTheme.grayText,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDone ? AppTheme.success : AppTheme.borderLight,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateTimeStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildPropertySummary(),
        const SizedBox(height: 16),
        Text(
          l10n.t('visitType'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _visitTypes.map((type) {
            final isSelected = _visitType == type;
            final displayType = type == 'In-Person' ? l10n.t('inPerson') : l10n.t('virtualTour');
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _visitType = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPinkDark
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPinkDark
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == 'In-Person'
                            ? Icons.directions_walk_rounded
                            : Icons.videocam_outlined,
                        size: 16,
                        color: isSelected ? Colors.white : AppTheme.grayText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayType,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.t('selectDate'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _selectedDate != null
                    ? AppTheme.primaryPinkDark
                    : AppTheme.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: _selectedDate != null
                      ? AppTheme.primaryPinkDark
                      : AppTheme.grayText,
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : l10n.t('chooseADate'),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: _selectedDate != null
                        ? AppTheme.charcoal
                        : AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.t('selectTime'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((t) {
            final isSelected = _selectedTime == t;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = t),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryPinkDark
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryPinkDark
                        : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.grayText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.t('yourInformation'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          l10n.fullName,
          _nameController,
          Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          l10n.phoneNumber,
          _phoneController,
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          l10n.email,
          _emailController,
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          l10n.t('notesOptional'),
          _notesController,
          Icons.note_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.cairo(fontSize: 13.sp, color: AppTheme.charcoal),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 18, color: AppTheme.grayText)
                : null,
            hintText: label,
            hintStyle: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppTheme.grayText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildPropertySummary(),
        const SizedBox(height: 16),
        Text(
          l10n.t('bookingSummary'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              _buildReviewRow(l10n.t('visitType'), l10n.t(_visitType == 'In-Person' ? 'inPerson' : 'virtualTour')),
              _buildReviewRow(
                l10n.date,
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : l10n.t('notSelected'),
              ),
              _buildReviewRow(l10n.time, _selectedTime),
              _buildReviewRow(l10n.fullName, _nameController.text),
              _buildReviewRow(l10n.t('phoneShort'), _phoneController.text),
              _buildReviewRow(l10n.email, _emailController.text),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppTheme.grayText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySummary() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryPinkLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.home_rounded,
            size: 20,
            color: AppTheme.primaryPinkDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _property['title'] as String? ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _property['location'] as String? ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppTheme.grayText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            l10n.localizePrice(_property['price'] as String? ?? ''),
            style: GoogleFonts.cairo(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.goldAccent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 12, 4.w, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPinkDark,
                  side: const BorderSide(color: AppTheme.primaryPinkDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  l10n.back,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  final serviceId = _property['id'] as String?;
                  final date = _selectedDate == null
                      ? null
                      : '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
                  if (serviceId == null || date == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.t('couldNotConfirmBooking'),
                        ),
                      ),
                    );
                    return;
                  }
                  try {
                    final priceStr = _property['price']?.toString() ?? '0';
                    final price =
                        double.tryParse(
                          priceStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                        ) ??
                        0.0;
                    final result = await createBookingAndPay(
                      serviceId: serviceId,
                      date: date,
                      time: _selectedTime,
                      serviceName: _property['name'] as String? ?? 'Property',
                      providerId: _property['providerId']?.toString() ??
                          _property['provider_id']?.toString(),
                      providerName: (_property['providerName'] as String?) ??
                          (_property['provider'] as String?) ??
                          'Véra',
                      category: 'Properties',
                      amount: price,
                    );
                    if (!mounted) return;
                    if (result == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.t('couldNotConfirmBooking'),
                          ),
                        ),
                      );
                      return;
                    }
                    final status = result['status']?.toString() ?? '';
                    final paidAmount =
                        double.tryParse(result['amount']?.toString() ?? '') ??
                        0.0;
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
                        content: Text(
                          l10n.t('couldNotConfirmBooking'),
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _submitted = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPinkDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                minimumSize: Size.zero,
                elevation: 0,
              ),
              child: Text(
                _currentStep == 2 ? l10n.t('confirmBooking') : l10n.next,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.t('bookingConfirmed'),
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('propertyBookingSuccess'),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPinkLight,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Column(
                  children: [
                    _buildReviewRow(
                      l10n.date,
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : '-',
                    ),
                    _buildReviewRow(l10n.time, _selectedTime),
                    _buildReviewRow(l10n.t('typeLabel'), l10n.t(_visitType == 'In-Person' ? 'inPerson' : 'virtualTour')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.myBookingsScreen),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPinkDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.t('viewMyAppointments'),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.homeScreen),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPinkDark,
                  side: const BorderSide(color: AppTheme.primaryPinkDark),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  l10n.t('backToHome'),
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
