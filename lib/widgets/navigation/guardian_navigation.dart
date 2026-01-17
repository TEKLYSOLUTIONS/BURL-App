import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
<<<<<<< HEAD
import '../../config/palette.dart';
=======
import 'floating_nav_bar.dart';
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba

class GuardianNavigation extends StatelessWidget {
  final Widget child;

  const GuardianNavigation({super.key, required this.child});

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
            icon: Icon(Ionicons.search_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.calendar_outline),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ''),
=======
          Icons.home_rounded,
          Ionicons.search_outline, // Book
          Icons.people_alt_rounded, // My Players
          Ionicons.calendar_outline, // Sessions
          Icons.person_rounded,
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/guardian/home')) return 0;
    if (location.startsWith('/guardian/book')) return 1;
    if (location.startsWith('/guardian/players')) return 2;
    if (location.startsWith('/guardian/sessions')) return 3;
    if (location.startsWith('/guardian/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/guardian/home');
        break;
      case 1:
        context.go('/guardian/book');
        break;
      case 2:
        context.go('/guardian/players');
        break;
      case 3:
        context.go('/guardian/sessions');
        break;
      case 4:
        context.go('/guardian/profile');
        break;
    }
  }
}
