import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_localizations.dart';
import '../core/auth_gate.dart';
import '../theme/app_theme.dart';

// V2 — Floating Pill BottomNav
// LOCKED: Detached pill bar floating above content, BoxShadow, extendBody: true

class _TabSpec {
  final String label;
  final String labelKey;
  final IconData icon;
  final IconData activeIcon;
  final int? branchIndex; // null = stub tab

  const _TabSpec({
    required this.label,
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;
  final int initialVisualIndex;

  const AppNavigation({this.navigationShell, this.initialVisualIndex = 0, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  // TODO: Replace with Riverpod/Bloc for production
  int _selectedVisualIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedVisualIndex = widget.initialVisualIndex;
  }

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Home',
      labelKey: 'navHome',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Explore',
      labelKey: 'navExplore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Offers',
      labelKey: 'navOffers',
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Favorites',
      labelKey: 'navFavorites',
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
      branchIndex:
          null, // stub — navigates to favorites screen via context.push
    ),
    _TabSpec(
      label: 'Profile',
      labelKey: 'navProfile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      branchIndex: 3,
    ),
  ];

  Future<void> _onTabTap(int visualIndex) async {
    final tab = _tabs[visualIndex];
    if (tab.label == 'Profile' || tab.label == 'Favorites') {
      // Account-related tabs require a signed-in user.
      if (!await requireAuth(context)) return;
    }
    if (tab.branchIndex == null) {
      // Stub tabs — navigate to specific screens
      if (!mounted) return;
      if (tab.label == 'Favorites') {
        if (widget.navigationShell == null && _selectedVisualIndex == visualIndex) {
          return;
        }
        context.push('/favorites-screen');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _selectedVisualIndex = visualIndex);
    final shell = widget.navigationShell;
    if (shell != null) {
      shell.goBranch(
        tab.branchIndex!,
        initialLocation: tab.branchIndex == shell.currentIndex,
      );
    } else {
      final routes = [
        '/home-screen',
        '/search-screen',
        '/offers-screen',
        '/profile-screen',
      ];
      context.go(routes[tab.branchIndex!]);
    }
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync visual selection with shell
    final shell = widget.navigationShell;
    if (shell == null) return;
    final currentBranchIndex = shell.currentIndex;
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].branchIndex == currentBranchIndex) {
        if (_selectedVisualIndex != i) {
          setState(() => _selectedVisualIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // V2 Floating Pill — detached, NOT in bottomNavigationBar slot
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 8),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(31),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppTheme.primaryPink.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.borderLight, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final isActive = _selectedVisualIndex == i;
            final isStub = tab.branchIndex == null;

            return Expanded(
              child: GestureDetector(
                onTap: () => _onTabTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryPinkLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          key: ValueKey('${tab.label}_$isActive'),
                          size: 22,
                          color: isActive
                              ? AppTheme.primaryPinkDark
                              : AppTheme.grayText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.t(tab.labelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppTheme.primaryPinkDark
                              : AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
