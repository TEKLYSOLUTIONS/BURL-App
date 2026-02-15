import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
import 'tabs/group_sessions_tab.dart';
import 'tabs/one_on_one_settings_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/player_sessions_view.dart';

class MySessionsScreen extends StatefulWidget {
  final bool isCoach;
  final String? notificationPath;

  const MySessionsScreen({
    super.key,
    this.isCoach = true,
    this.notificationPath,
  });

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isCoach) {
      return _buildPlayerLayout(context);
    }
    return _buildCoachLayout(context);
  }

  Widget _buildPlayerLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CoachAppBar(
            backgroundColor: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Sessions',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                NotificationButton(
                  iconColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).cardColor,
                  onTap: () => context.push(
                    widget.notificationPath ?? '/player/notifications',
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: PlayerSessionsView()),
        ],
      ),
    );
  }

  Widget _buildCoachLayout(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            CoachAppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              bottomPadding: 16,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Balance Notification Button
                      Expanded(
                        child: Text(
                          'My Sessions',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      NotificationButton(
                        iconColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        onTap: () => context.push(
                          widget.notificationPath ?? '/coach/notifications',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.white,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Group'),
                        Tab(text: '1-on-1'),
                        Tab(text: 'Calendar'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: const TabBarView(
                children: [
                  GroupSessionsTab(),
                  OneOnOneSettingsTab(),
                  CalendarTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/coach/create-session'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
