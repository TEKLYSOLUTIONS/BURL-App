import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
<<<<<<< HEAD
import '../../config/palette.dart';
=======
import 'floating_nav_bar.dart';
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba

class CoachNavigation extends StatelessWidget {
  final Widget child;

  const CoachNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppPalette.orangeAccent,
        unselectedItemColor: AppPalette.textDisabled,
        backgroundColor: Theme.of(context).cardTheme.color,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
<<<<<<< HEAD
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.calendar_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_rounded),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ''),
=======
          Icons.home_rounded,
          Icons.event_available_rounded, // Availability
          Ionicons.calendar_outline, // Sessions
          Icons.attach_money_rounded, // Earnings
          Icons.person_rounded, // Profile
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
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
