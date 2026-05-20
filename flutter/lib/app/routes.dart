import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/l10n.dart';
import '../features/home/home_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/leave_optimizer/leave_optimizer_screen.dart';
import '../features/colleague_mode/colleague_mode_screen.dart';
import '../features/salary_predictor/salary_predictor_screen.dart';

/// 自定义页面过渡动画：从右滑入 + 淡入
Page<dynamic> _buildPageWithTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => _onTabTapped(context, index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.homeTab),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: l10n.calendarTab),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.profileTab),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/calendar')) return 1;
    if (path.startsWith('/profile')) return 2;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/calendar');
      case 2: context.go('/profile');
    }
  }
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(child: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', pageBuilder: (context, state) => _buildPageWithTransition(key: state.pageKey, child: const HomeScreen()))]),
        StatefulShellBranch(routes: [GoRoute(path: '/calendar', pageBuilder: (context, state) => _buildPageWithTransition(key: state.pageKey, child: const CalendarScreen()))]),
        StatefulShellBranch(routes: [GoRoute(path: '/profile', pageBuilder: (context, state) => _buildPageWithTransition(key: state.pageKey, child: const ProfileScreen()))]),
      ],
    ),
    GoRoute(path: '/leave-optimizer', pageBuilder: (context, state) => _buildPageWithTransition(key: state.pageKey, child: const LeaveOptimizerScreen())),
    GoRoute(path: '/colleague-mode', pageBuilder: (context, state) => _buildPageWithTransition(key: state.pageKey, child: const ColleagueModeScreen())),
    GoRoute(path: '/salary-predictor', pageBuilder: (context, state) => _buildPageWithTransition(key: state.pageKey, child: const SalaryPredictorScreen())),
  ],
);
