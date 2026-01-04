import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'floating_nav_bar.dart';

class GuardianNavigation extends StatelessWidget {
  final Widget child;

  const GuardianNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow behind the floating navbar
      body: child,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        items: const [
          Icons.home_rounded,
          Icons.calendar_month_outlined, // Book
          Icons.people_alt_rounded, // My Players
          Icons.sports_cricket_rounded, // Sessions
          Icons.person_rounded,
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
