import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
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
import '../screens/guardian/guardian_profile_screen.dart'; // New Import
import '../screens/guardian/coach_details_screen.dart'; // New Import
import '../screens/coach/students_screen.dart';
import '../screens/coach/earning_history_screen.dart';
import '../screens/coach/availability_screen.dart';
import '../screens/coach/session_report_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/player/player_reports_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/notification_detail_screen.dart';

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
        builder: (context, state) => const WelcomeScreen(),
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
            CoachDetailsScreen(coachId: state.pathParameters['id'] ?? '1'),
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
        path: '/guardian/add-player',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddPlayerScreen(),
      ),

      GoRoute(
        path: '/guardian/player-details/:id',
        builder: (context, state) {
          final isCoach = state.uri.queryParameters['isCoach'] == 'true';
          return PlayerDetailsScreen(
            playerId: state.pathParameters['id'] ?? '1',
            isCoachView: isCoach,
          );
        },
      ),

      GoRoute(
        path: '/guardian/edit-player',
        builder: (context, state) => const EditPlayerScreen(),
      ),

      GoRoute(
        path: '/player-reports/:id',
        builder: (context, state) =>
            PlayerReportsScreen(playerId: state.pathParameters['id'] ?? '1'),
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
            builder: (context, state) => const MySessionsScreen(isCoach: true),
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
            builder: (context, state) => const CoachProfileScreen(coachId: '1'),
          ),
          GoRoute(
            path: '/coach/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/coach/create-session',
            builder: (context, state) => const CreateSessionScreen(),
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
            path: '/player/sessions',
            builder: (context, state) => const MySessionsScreen(isCoach: false),
          ),
          GoRoute(
            path: '/player/notifications',
            builder: (context, state) => const NotificationsScreen(),
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
            builder: (context, state) => const MySessionsScreen(isCoach: false),
          ),
          GoRoute(
            path: '/guardian/profile',
            builder: (context, state) => const GuardianProfileScreen(),
          ),
          GoRoute(
            path: '/guardian/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/notification-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return NotificationDetailScreen(
            title: data['title'],
            time: data['time'],
            description: data['description'],
            avatar: data['avatar'],
            iconData: data['iconData'],
            iconColor: data['iconColor'],
            iconBg: data['iconBg'],
          );
        },
      ),
    ],
  );
}
