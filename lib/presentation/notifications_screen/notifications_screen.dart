import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../core/auth_gate.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/vera_api_service.dart';
import '../../widgets/app_back_button.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with AuthGuard {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  static const List<String> _filters = [
    'All',
    'Orders',
    'Bookings',
    'Offers',
    'System',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final apiNotifs = await VeraApiService.instance.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = apiNotifs.map(_notifToMap).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _notifToMap(VeraNotification n) {
    final type = _mapNotifType(n.type);
    return {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'time': n.createdAt,
      'type': type,
      'icon': _iconForType(type),
      'color': _colorForType(type),
      'iconColor': _iconColorForType(type),
      'isRead': n.isRead,
    };
  }

  Future<void> _markAllRead() async {
    await VeraApiService.instance.markAllNotificationsRead();
    if (!mounted) return;
    setState(() {
      for (final n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  String _mapNotifType(String type) {
    final t = type.toLowerCase();
    if (t.contains('order') || t.contains('ship') || t.contains('deliver')) {
      return 'Orders';
    }
    if (t.contains('book') || t.contains('appoint')) return 'Bookings';
    if (t.contains('offer') || t.contains('sale') || t.contains('promo')) {
      return 'Offers';
    }
    return 'System';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Orders':
        return Icons.local_shipping_outlined;
      case 'Bookings':
        return Icons.calendar_today_outlined;
      case 'Offers':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'Orders':
        return AppTheme.fashionBg;
      case 'Bookings':
        return AppTheme.clinicsBg;
      case 'Offers':
        return AppTheme.goldLight;
      default:
        return AppTheme.jobsBg;
    }
  }

  Color _iconColorForType(String type) {
    switch (type) {
      case 'Orders':
        return AppTheme.fashion;
      case 'Bookings':
        return AppTheme.clinics;
      case 'Offers':
        return AppTheme.goldAccent;
      default:
        return AppTheme.jobs;
    }
  }

  @override
  Widget build(BuildContext context) {
    return authPlaceholder(_buildGuardedContent(context));
  }

  Widget _buildGuardedContent(BuildContext context) {
    final filtered = _selectedFilter == 'All'
        ? _notifications
        : _notifications.where((n) => n['type'] == _selectedFilter).toList();

    final unreadCount = _notifications
        .where((n) => n['isRead'] == false)
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(unreadCount),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _buildNotificationCard(filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withAlpha(60),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    final cartCount = ref.watch(cartCountProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          AppBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPinkDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$unreadCount new',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
          // Cart icon with badge
          GestureDetector(
            onTap: () => context.push(AppRoutes.cartAndCheckoutScreen),
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: AppTheme.iconMd,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (cartCount > 0)
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryPinkDark,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: GoogleFonts.cairo(
                            fontSize: 7,
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
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: AppTheme.chipHeight + 16,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
         padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final isActive = _selectedFilter == _filters[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryPinkDark
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: isActive
                      ? AppTheme.primaryPinkDark
                      : AppTheme.borderLight,
                ),
              ),
              child: Text(
                _filters[i],
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
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final isRead = notif['isRead'] as bool? ?? true;
    final icon = notif['icon'] as IconData? ?? Icons.notifications_outlined;
    final color = notif['color'] as Color? ?? AppTheme.ivoryLight;
    final iconColor = notif['iconColor'] as Color? ?? AppTheme.primaryPinkDark;

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await VeraApiService.instance.markNotificationRead(
            notif['id'] as String? ?? '',
          );
          setState(() => notif['isRead'] = true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? Theme.of(context).cardColor
              : AppTheme.primaryPinkLight.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppTheme.borderLight
                : AppTheme.primaryPink.withAlpha(80),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] as String? ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                           maxLines: 3,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPinkDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.grayText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif['time'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.grayLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryPinkLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: AppTheme.primaryPinkDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noNotifications,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
          ),
        ],
      ),
    );
  }
}
