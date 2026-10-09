import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../services/vera_api_service.dart';
import 'widgets/booking_flow_sheet.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin, AuthGuard {
  late TabController _tabController;
  String _selectedCategory = 'All';
  int _bookingStep = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];
  List<String> _categories = ['All', 'Clinics', 'Salons', 'Spas', 'Gyms'];

  Map<String, dynamic>? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '';

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
  static const List<String> _unavailableSlots = [
    '9:30 AM',
    '11:00 AM',
    '3:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final apiServices = await VeraApiService.instance.fetchServices(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      if (!mounted) return;
      final cats = <String>{'All'};
      final mapped = apiServices.map((s) {
        cats.add(s.category.isNotEmpty ? s.category : 'Other');
        final priceStr = s.price > 0
            ? s.price.toStringAsFixed(
                s.price == s.price.roundToDouble() ? 0 : 2,
              )
            : '';
        return {
          'id': s.id,
          'name': s.name,
          'provider': s.provider,
          'category': s.category.isNotEmpty ? s.category : 'Other',
          'price': priceStr,
          'duration': s.duration,
          'rating': s.rating,
          'reviews': s.reviews,
          'image': s.imageUrl,
          'color': AppTheme.tintBlue,
          'icon': Icons.medical_services_outlined,
        };
      }).toList();
      setState(() {
        _services = mapped;
        _categories = cats.toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _services = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildServicesTab(), _buildMyBookingsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
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
                  l10n.clinicsAndSalons,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  l10n.t('bookYourAppointment'),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.ivoryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.charcoal,
        unselectedLabelColor: AppTheme.grayText,
        labelStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(text: l10n.t('bookService')),
          Tab(text: l10n.myBookings),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    final l10n = AppLocalizations.of(context);
    final filtered = _selectedCategory == 'All'
        ? _services
        : _services.where((s) => s['category'] == _selectedCategory).toList();

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final isActive = _selectedCategory == _categories[i];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = _categories[i]);
                  _loadServices();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.clinics : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppTheme.clinics : AppTheme.borderLight,
                    ),
                  ),
                  child: Text(
                    _categories[i],
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : AppTheme.charcoal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: 4,
                  itemBuilder: (_, __) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 48,
                        color: AppTheme.grayText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.t('noServicesFoundShort'),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _buildServiceCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final l10n = AppLocalizations.of(context);
    final icon =
        service['icon'] as IconData? ?? Icons.medical_services_outlined;
    final color = service['color'] as Color? ?? AppTheme.tintBlue;

    return GestureDetector(
      onTap: () => _startBookingFlow(service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: CustomImageWidget(
                imageUrl: service['image'] as String? ?? '',
                width: 100,
                height: 110,
                fit: BoxFit.cover,
                semanticLabel: l10n.serviceImageLabel(service['name'] as String? ?? ''),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service['category'] as String? ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service['name'] as String? ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['provider'] as String? ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.grayText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${service['rating']}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppTheme.grayText,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${service['duration']}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppTheme.grayText,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${service['price']} AED',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<VeraBooking>>(
      future: VeraApiService.instance.fetchMyBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: 3,
            itemBuilder: (_, __) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.clinicsBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    size: 32,
                    color: AppTheme.clinics,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('noBookingsYet'),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.t('bookToGetStarted'),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: bookings.length,
          itemBuilder: (context, i) {
            final b = bookings[i];
            final statusColor = b.status.toLowerCase() == 'completed'
                ? AppTheme.success
                : b.status.toLowerCase() == 'cancelled'
                ? AppTheme.error
                : AppTheme.warning;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: b.imageUrl.isNotEmpty
                        ? CustomImageWidget(
                            imageUrl: b.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            semanticLabel: l10n.t('bookingImage', args: {'name': b.serviceName}),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppTheme.clinicsBg,
                            child: const Icon(
                              Icons.medical_services_outlined,
                              color: AppTheme.clinics,
                              size: 28,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.serviceName,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.providerName,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.grayText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppTheme.grayText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${b.date} • ${b.time}',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppTheme.grayText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b.status,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${b.price.toStringAsFixed(0)} AED',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startBookingFlow(Map<String, dynamic> service) {
    setState(() {
      _selectedService = service;
      _bookingStep = 1;
      _selectedTime = '';
    });
    final l10n = AppLocalizations.of(context);
    final icon =
        service['icon'] as IconData? ?? Icons.medical_services_outlined;
    final color = service['color'] as Color? ?? AppTheme.tintBlue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.88,
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
                        onTap: () => Navigator.pop(ctx),
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
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 28, color: AppTheme.charcoal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['name'] as String? ?? '',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.charcoal,
                                    ),
                                  ),
                                  Text(
                                    service['provider'] as String? ?? '',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppTheme.grayText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${service['price']} AED',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (_, di) {
                            final date = DateTime.now().add(
                              Duration(days: di + 1),
                            );
                            final isSelected =
                                _selectedDate.day == date.day &&
                                _selectedDate.month == date.month;
                            final days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            return GestureDetector(
                              onTap: () =>
                                  setModalState(() => _selectedDate = date),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                width: 52,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.clinics
                                      : AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.clinics
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
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.grayText,
                                      ),
                                    ),
                                    Text(
                                      '${date.day}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                          final isUnavailable = _unavailableSlots.contains(
                            slot,
                          );
                          final isSelected = _selectedTime == slot;
                          return GestureDetector(
                            onTap: isUnavailable
                                ? null
                                : () =>
                                      setModalState(() => _selectedTime = slot),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isUnavailable
                                    ? AppTheme.ivoryLight
                                    : isSelected
                                    ? AppTheme.clinics
                                    : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isUnavailable
                                      ? AppTheme.borderLight
                                      : isSelected
                                      ? AppTheme.clinics
                                      : AppTheme.borderMedium,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isUnavailable
                                      ? AppTheme.grayLight
                                      : isSelected
                                      ? Colors.white
                                      : AppTheme.charcoal,
                                  decoration: isUnavailable
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _selectedTime.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                final priceStr =
                                    service['price']?.toString() ?? '0';
                                final price =
                                    double.tryParse(
                                      priceStr.replaceAll(
                                        RegExp(r'[^0-9.]'),
                                        '',
                                      ),
                                    ) ??
                                    0.0;
                                final result = await createBookingAndPay(
                                  serviceId:
                                      service['id'] as String? ?? '',
                                  date:
                                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                  time: _selectedTime,
                                  serviceName:
                                      service['name'] as String? ?? '',
                                  providerId: null,
                                  providerName:
                                      service['provider'] as String? ?? '',
                                  category:
                                      service['category'] as String? ?? '',
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
                                final status =
                                    result['status']?.toString() ?? '';
                                final paidAmount =
                                    double.tryParse(
                                      result['amount']?.toString() ?? '',
                                    ) ??
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
                                _showBookingConfirmation(service);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _selectedTime.isEmpty
                                ? null
                                : AppTheme.primaryGradient,
                            color: _selectedTime.isEmpty
                                ? AppTheme.borderLight
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              l10n.t('confirmBooking'),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _selectedTime.isEmpty
                                    ? AppTheme.grayText
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingConfirmation(Map<String, dynamic> service) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 36,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.t('bookingConfirmed'),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('bookingConfirmedMessage', args: {
                'name': service['name'] as String? ?? '',
                'date': '${_selectedDate.day}/${_selectedDate.month}',
                'time': _selectedTime,
              }),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppTheme.grayText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    l10n.done,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
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
    );
  }
}
