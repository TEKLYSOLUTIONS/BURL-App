import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/onboarding/app_onboarding_screen.dart'; // New Import
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/sessions/create_session_screen.dart'; // New Import // New Import
import '../screens/coach/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/player/home_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/sessions/my_sessions_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/guardian/my_players_screen.dart';
import '../screens/profile/coach_profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/sessions/session_details_screen.dart';
import '../widgets/navigation/guardian_navigation.dart';
import '../widgets/navigation/coach_navigation.dart';
import '../widgets/navigation/player_navigation.dart';
import '../screens/guardian/home_screen.dart';

// New Imports for Missing Pages
import '../screens/guardian/add_player_screen.dart';
import '../screens/guardian/player_details_screen.dart';
import '../screens/guardian/edit_player_screen.dart';
import '../screens/coach/students_screen.dart';
import '../screens/coach/earning_history_screen.dart';
import '../screens/coach/availability_screen.dart';
import '../screens/coach/session_report_screen.dart';
import '../screens/settings/settings_screen.dart';

// Placeholder screens for other tabs
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
    );
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const AppOnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(role: state.uri.queryParameters['role']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterScreen(role: state.uri.queryParameters['role']),
      ),

      GoRoute(
        path: '/coach-details/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CoachProfileScreen(coachId: state.pathParameters['id'] ?? '1'),
      ),

      GoRoute(
        path: '/session-details/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            SessionDetailsScreen(sessionId: state.pathParameters['id'] ?? '1'),
      ),

      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: '/coach/session-report',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SessionReportScreen(),
      ),

      GoRoute(
        path: '/coach/create-session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateSessionScreen(),
      ),

      GoRoute(
        path: '/guardian/add-player',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddPlayerScreen(),
      ),

      GoRoute(
        path: '/guardian/player-details/:id',
        builder: (context, state) =>
            PlayerDetailsScreen(playerId: state.pathParameters['id'] ?? '1'),
      ),

      GoRoute(
        path: '/guardian/edit-player',
        builder: (context, state) => const EditPlayerScreen(),
      ),

      // Coach Shell Route (6 Tabs)
      ShellRoute(
        builder: (context, state, child) {
          return CoachNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/coach/home',
            builder: (context, state) => const CoachHomeScreen(),
          ),
          GoRoute(
            path: '/coach/availability',
            builder: (context, state) => const CoachAvailabilityScreen(),
          ),
          GoRoute(
            path: '/coach/sessions',
            builder: (context, state) => const MySessionsScreen(),
          ),
          GoRoute(
            path: '/coach/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/coach/earnings',
            builder: (context, state) => const EarningHistoryScreen(),
          ),
          GoRoute(
            path: '/coach/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Player Shell Route (4 Tabs)
      ShellRoute(
        builder: (context, state, child) {
          return PlayerNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/player/home',
            builder: (context, state) => const PlayerHomeScreen(),
          ),
          GoRoute(
            path: '/player/book',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/player/sessions',
            builder: (context, state) => const MySessionsScreen(),
          ),
          GoRoute(
            path: '/player/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/booking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookingScreen(),
      ),

      // Guardian Shell Route (5 Tabs)
      ShellRoute(
        builder: (context, state, child) {
          return GuardianNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/guardian/home',
            builder: (context, state) => const GuardianHomeScreen(),
          ),
          GoRoute(
            path: '/guardian/book',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/guardian/players',
            builder: (context, state) => const MyPlayersScreen(),
          ),
          GoRoute(
            path: '/guardian/sessions',
            builder: (context, state) => const MySessionsScreen(),
          ),
          GoRoute(
            path: '/guardian/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
