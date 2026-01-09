import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'floating_nav_bar.dart';

class PlayerNavigation extends StatelessWidget {
  final Widget child;

  const PlayerNavigation({super.key, required this.child});

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
          Ionicons.search_outline, // Book
          Ionicons.calendar_outline, // Sessions
          Icons.person_rounded,
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/player/home')) return 0;
    if (location.startsWith('/player/book')) return 1;
    if (location.startsWith('/player/sessions')) return 2;
    if (location.startsWith('/player/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/player/home');
        break;
      case 1:
        context.go('/player/book');
        break;
      case 2:
        context.go('/player/sessions');
        break;
      case 3:
        context.go('/player/profile');
        break;
    }
  }
}
