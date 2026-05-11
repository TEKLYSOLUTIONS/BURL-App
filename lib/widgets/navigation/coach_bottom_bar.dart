import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../config/palette.dart';

class CoachBottomBar extends StatelessWidget {
  const CoachBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _calculateSelectedIndex(context),
      onTap: (int idx) => _onItemTapped(idx, context),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppPalette.orangeAccent,
      unselectedItemColor: AppPalette.textDisabled,
      backgroundColor: Theme.of(context).cardTheme.color,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
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
      ],
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/coach/home')) {
      return 0;
    }
    if (location.startsWith('/coach/availability')) {
      return 1;
    }
    if (location.startsWith('/coach/sessions')) {
      return 2;
    }
    // Highlight 'Sessions' tab for session details and reports
    if (location.startsWith('/session-details') ||
        location.startsWith('/coach/session-report') ||
        location.startsWith('/coach/player-report')) {
      return 2;
    }
    if (location.startsWith('/coach/earnings') || location.startsWith('/coach-connect')) {
      return 3;
    }
    if (location.startsWith('/coach/profile') || location.startsWith('/edit-profile')) {
      return 4;
    }
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
