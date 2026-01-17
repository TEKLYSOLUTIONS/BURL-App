import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
<<<<<<< HEAD
import '../../config/palette.dart';
=======
import 'floating_nav_bar.dart';
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba

class PlayerNavigation extends StatelessWidget {
  final Widget child;

  const PlayerNavigation({super.key, required this.child});

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
            icon: Icon(Ionicons.calendar_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.notifications_outline),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ''),
=======
          Icons.home_rounded,
          Ionicons.search_outline, // Book
          Ionicons.calendar_outline, // Sessions
          Icons.person_rounded,
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/player/home')) return 0;
    if (location.startsWith('/player/sessions')) return 1;
    if (location.startsWith('/player/notifications')) return 2;
    if (location.startsWith('/player/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/player/home');
        break;
      case 1:
        context.go('/player/sessions');
        break;
      case 2:
        context.go('/player/notifications');
        break;
      case 3:
        context.go('/player/profile');
        break;
    }
  }
}
