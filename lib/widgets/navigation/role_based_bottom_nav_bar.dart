import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../config/palette.dart';
import '../../services/auth_service.dart';

class RoleBasedBottomNavBar extends StatefulWidget {
  const RoleBasedBottomNavBar({super.key});

  @override
  State<RoleBasedBottomNavBar> createState() => _RoleBasedBottomNavBarState();
}

class _RoleBasedBottomNavBarState extends State<RoleBasedBottomNavBar> {
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getUserRole();
    if (mounted) setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) return const SizedBox.shrink();
    switch (_role) {
      case 'player':
        return _buildPlayerNavBar();
      case 'guardian':
        return _buildGuardianNavBar();
      case 'coach':
        return _buildCoachNavBar();
      default:
        return const SizedBox.shrink();
    }
  }

  int _playerIndex() {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/player/home')) return 0;
    if (loc.startsWith('/player/sessions')) return 2;
    if (loc.startsWith('/player/profile')) return 3;
    return 1; // search / booking
  }

  int _guardianIndex() {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/guardian/home')) return 0;
    if (loc.startsWith('/guardian/players')) return 2;
    if (loc.startsWith('/guardian/sessions')) return 3;
    if (loc.startsWith('/guardian/profile')) return 4;
    return 1; // book / booking
  }

  Widget _buildPlayerNavBar() {
    return BottomNavigationBar(
      currentIndex: _playerIndex(),
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/player/home');
          case 1:
            context.go('/player/search');
          case 2:
            context.go('/player/sessions');
          case 3:
            context.go('/player/profile');
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppPalette.orangeAccent,
      unselectedItemColor: AppPalette.textDisabled,
      backgroundColor: Theme.of(context).cardTheme.color,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: ''),
        BottomNavigationBarItem(
          icon: Icon(Ionicons.calendar_outline),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ''),
      ],
    );
  }

  Widget _buildGuardianNavBar() {
    return BottomNavigationBar(
      currentIndex: _guardianIndex(),
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/guardian/home');
          case 1:
            context.go('/guardian/book');
          case 2:
            context.go('/guardian/players');
          case 3:
            context.go('/guardian/sessions');
          case 4:
            context.go('/guardian/profile');
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppPalette.orangeAccent,
      unselectedItemColor: AppPalette.textDisabled,
      backgroundColor: Theme.of(context).cardTheme.color,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
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
      ],
    );
  }

  Widget _buildCoachNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/coach/home');
          case 1:
            context.go('/coach/availability');
          case 2:
            context.go('/coach/sessions');
          case 3:
            context.go('/coach/earnings');
          case 4:
            context.go('/coach/profile');
        }
      },
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
}
