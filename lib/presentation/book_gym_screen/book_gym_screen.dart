import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../core/auth_gate.dart';
import '../booking_screen/widgets/booking_flow_sheet.dart';

class BookGymScreen extends StatefulWidget {
  final Map<String, dynamic>? gymData;
  const BookGymScreen({super.key, this.gymData});

  @override
  State<BookGymScreen> createState() => _BookGymScreenState();
}

class _BookGymScreenState extends State<BookGymScreen> with AuthGuard {
  int _currentStep = 0;

  // Step 1 — Session
  String? _selectedPlan;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;

  // Step 2 — Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedGoal;

  final List<String> _timeSlots = [
    '6:00 AM',
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '2:00 PM',
    '4:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

  final List<String> _goals = [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Flexibility',
    'General Fitness',
    'Sports Training',
  ];

  String _goalLabel(String goal) {
    final l10n = AppLocalizations.of(context);
    return switch (goal) {
      'Weight Loss' => l10n.t('weightLoss'),
      'Muscle Gain' => l10n.t('muscleGain'),
      'Endurance' => l10n.t('endurance'),
      'Flexibility' => l10n.t('flexibility'),
      'General Fitness' => l10n.t('generalFitness'),
      'Sports Training' => l10n.t('sportsTraining'),
      _ => goal,
    };
  }

  Map<String, dynamic> get _gym => widget.gymData ?? const {};

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
                  l10n.t('bookASession'),
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  _gym['name'] as String? ?? '',
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
    final steps = [l10n.t('sessionLabel'), l10n.t('detailsLabel'), l10n.confirm];
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
                              ? const Color(0xFF5DADE2)
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
                              ? const Color(0xFF5DADE2)
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
    final plans =
        (_gym['plans'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
        [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.h),
        Text(
          l10n.t('chooseAPlan'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        if (plans.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 40,
                    color: AppTheme.grayText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('noPlansAvailable'),
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
          ...plans.map((plan) {
          final isSelected = _selectedPlan == plan['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedPlan = plan['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5DADE2).withAlpha(15)
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5DADE2)
                      : AppTheme.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5DADE2)
                            : AppTheme.borderLight,
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFF5DADE2)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'] as String? ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        Text(
                          plan['desc'] as String? ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.localizePrice(plan['price'] as String? ?? ''),
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF5DADE2)
                          : AppTheme.goldAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: 1.5.h),
        Text(
          l10n.t('selectDate'),
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index + 1));
              final isSelected =
                  _selectedDate.day == date.day &&
                  _selectedDate.month == date.month;
              final dayNames = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ];
              final dayName = dayNames[date.weekday - 1];
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF5DADE2)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF5DADE2)
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: isSelected
                              ? Colors.white70
                              : AppTheme.grayText,
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
        ),
        SizedBox(height: 1.5.h),
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
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5DADE2)
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5DADE2)
                        : AppTheme.borderLight,
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
        const SizedBox(height: 12),
        _buildTextField(
          controller: _nameController,
          label: l10n.fullName,
          hint: l10n.t('enterYourFullName'),
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _phoneController,
          label: l10n.phoneNumber,
          hint: '+971 XX XXX XXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          label: l10n.email,
          hint: 'your@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 1.5.h),
        Text(
          l10n.t('fitnessGoal'),
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
          children: _goals.map((goal) {
            final isSelected = _selectedGoal == goal;
            return GestureDetector(
              onTap: () => setState(() => _selectedGoal = goal),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5DADE2).withAlpha(20)
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5DADE2)
                        : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  _goalLabel(goal),
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF5DADE2)
                        : AppTheme.charcoal,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, size: 18, color: AppTheme.grayText),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppTheme.charcoal,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      color: AppTheme.grayText,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final l10n = AppLocalizations.of(context);
    final monthNames = [
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                Icons.fitness_center_rounded,
                l10n.t('facilityLabel'),
                _gym['name'] as String? ?? '',
              ),
              if ((_gym['providerName']?.toString() ?? _gym['provider']?.toString() ?? '').isNotEmpty) ...[
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.person_outline_rounded,
                  l10n.t('trainer'),
                  _gym['providerName']?.toString() ?? _gym['provider']?.toString() ?? '',
                ),
              ],
              const Divider(height: 20),
              _buildSummaryRow(
                Icons.card_membership_rounded,
                l10n.t('planLabel'),
                _selectedPlan ?? l10n.t('notSelected'),
              ),
              const Divider(height: 20),
              _buildSummaryRow(
                Icons.calendar_today_rounded,
                l10n.date,
                '${_selectedDate.day} ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
              ),
              const Divider(height: 20),
              _buildSummaryRow(
                Icons.access_time_rounded,
                l10n.time,
                _selectedTime ?? l10n.t('notSelected'),
              ),
              if (_nameController.text.isNotEmpty) ...[
                const Divider(height: 20),
                _buildSummaryRow(
                  Icons.person_outline_rounded,
                  l10n.fullName,
                  _nameController.text,
                ),
              ],
              if (_selectedGoal != null) ...[
                const Divider(height: 20),
                _buildSummaryRow(Icons.flag_outlined, l10n.t('goalLabel'), _goalLabel(_selectedGoal!)),
              ],
            ],
          ),
        ),
        SizedBox(height: 1.5.h),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF5DADE2).withAlpha(15),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFF5DADE2).withAlpha(60)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF5DADE2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.t('freeCancellationGym'),
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

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.gymBg,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF5DADE2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  color: AppTheme.grayText,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final l10n = AppLocalizations.of(context);
    final isLastStep = _currentStep == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  l10n.back,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLastStep) {
                  _showSuccessDialog();
                } else {
                  setState(() => _currentStep++);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5DADE2), Color(0xFF2E86C1)],
                  ),
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5DADE2).withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isLastStep ? l10n.t('confirmBooking') : l10n.continueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    final l10n = AppLocalizations.of(context);
    final plans =
        (_gym['plans'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
        [];
    final selectedPlan = plans.firstWhere(
      (p) => p['name'] == _selectedPlan,
      orElse: () => const {},
    );
    final serviceId = (selectedPlan['id'] as String?) ?? (_gym['id'] as String?);
    final serviceName =
        (selectedPlan['name'] as String?) ?? (_gym['name'] as String?);
    final providerId =
        (_gym['providerId'] as String?) ?? (_gym['provider_id'] as String?);
    final providerName = (_gym['providerName'] as String?) ??
        (_gym['provider'] as String?) ??
        'Véra';
    final priceStr =
        (selectedPlan['price'] ?? _gym['price'] ?? '0').toString();
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
        category: 'Gym',
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF5DADE2).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: Color(0xFF5DADE2),
                ),
              ),
              const SizedBox(height: 16),
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
                l10n.t('gymBookingSuccess', args: {'name': _gym['name'] as String? ?? ''}),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppTheme.grayText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go('/home-screen');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5DADE2), Color(0xFF2E86C1)],
                    ),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Center(
                    child: Text(
                      l10n.done,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
