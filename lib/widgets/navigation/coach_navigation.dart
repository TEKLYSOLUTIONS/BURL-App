import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'floating_nav_bar.dart';

class CoachNavigation extends StatelessWidget {
  final Widget child;

  const CoachNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        items: const [
          Icons.home_rounded,
          Icons.event_available_rounded, // Availability
          Ionicons.calendar_outline, // Sessions
          Icons.attach_money_rounded, // Earnings
          Icons.person_rounded, // Profile
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/coach/home')) return 0;
    if (location.startsWith('/coach/availability')) return 1;
    if (location.startsWith('/coach/sessions')) return 2;
    if (location.startsWith('/coach/earnings')) return 3;
    if (location.startsWith('/coach/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/coach/home');
        break;
      case 1:
        context.go('/coach/availability');
        break;
      case 2:
        context.go('/coach/sessions');
        break;
      case 3:
        context.go('/coach/earnings');
        break;
      case 4:
        context.go('/coach/profile');
        break;
    }
  }
}
