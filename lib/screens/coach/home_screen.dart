import 'package:flutter/material.dart';
import '../../config/palette.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
import '../../widgets/calendar/horizontal_week_calendar.dart'; // Import Calendar

import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/session_service.dart'; // Import SessionService
import '../../utils/date_time_utils.dart';
import '../../utils/activity_utils.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  String _userName = 'Coach';
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now(); // Track selected date

  // Dashboard data
  int _todaySessionsCount = 0;
  double _totalEarnings = 0.0; // New state for Total Earnings
  int _todayStudentsCount = 0;
  List<dynamic> _upcomingSessions = [];
  List<dynamic> _todaysSessions = [];
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }

  // Helper to check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Helper to format date for display
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}";
  }

  Future<void> _loadSessionsForDate(DateTime date) async {
    setState(() => _isLoading = true);

    try {
      if (_isToday(date)) {
        await _loadDashboardData();
      } else {
        final response = await SessionService.getCoachSessions(date: date);
        if (mounted) {
          setState(() {
            _todaysSessions = response['sessions'] as List<dynamic>;
            // Determine upcoming for selected date if needed, or just list them all
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading date sessions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getUserName();
    if (name != null) {
      if (mounted) {
        setState(() {
          _userName = name.split(' ').first;
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final data = await DashboardService.getCoachDashboard();

      // Also fetch full sessions for today to populate the schedule list correctly
      final todaySessionsResponse = await SessionService.getCoachSessions(
        date: DateTime.now(),
      );

      if (data != null && mounted) {
        setState(() {
          final todaySummary = data['todaySummary'];
          final stats = data['stats']; // Get stats for Total Earnings

          _todaySessionsCount = todaySummary?['sessions'] ?? 0;
          // _todayEarnings removed
          _totalEarnings = (stats?['totalEarnings'] ?? 0)
              .toDouble(); // Fetch Total Earnings
          _todayStudentsCount = todaySummary?['students'] ?? 0;

          _upcomingSessions = List.from(data['upcomingSessions'] ?? []);
          _recentActivity = List.from(data['recentActivity'] ?? []);

          _todaysSessions = todaySessionsResponse['sessions'] as List<dynamic>;

          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Fixed Header Section
          CoachAppBar(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=11',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateTimeUtils.getCurrentDateFormatted(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7),
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${DateTimeUtils.getGreeting()}, $_userName',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    NotificationButton(
                      onTap: () => context.push('/coach/notifications'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📅 Horizontal Calendar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: HorizontalWeekCalendar(
                      initialDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                          _loadSessionsForDate(date);
                        });
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Only show Today's Summary and Next Session if selected date is Today
                              if (_isToday(_selectedDate)) ...[
                                _buildTodaySummary(),
                                const SizedBox(height: 24),
                                _buildQuickActions(),
                                const SizedBox(height: 24),
                                _buildNextSessionSection(),
                                const SizedBox(height: 32),
                              ],

                              // Sessions List Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isToday(_selectedDate)
                                        ? "Today's Schedule"
                                        : 'Sessions for ${_formatDate(_selectedDate)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  if (_isToday(_selectedDate))
                                    TextButton(
                                      onPressed: () =>
                                          context.go('/coach/sessions'),
                                      child: Text(
                                        'See all',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Dynamic upcoming sessions from API
                              if ((_isToday(_selectedDate)
                                      ? _todaysSessions
                                      : _upcomingSessions)
                                  .isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 48,
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _isToday(_selectedDate)
                                              ? 'No sessions today'
                                              : 'No sessions scheduled',
                                          style: GoogleFonts.inter(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...(_isToday(_selectedDate)
                                        ? _todaysSessions
                                        : _upcomingSessions)
                                    .map((session) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _buildNewSessionCard(
                                          context,
                                          session,
                                        ),
                                      );
                                    }),

                              const SizedBox(height: 32),

                              // Recent Activity (Only show on Today view to reduce clutter)
                              if (_isToday(_selectedDate)) ...[
                                Text(
                                  'Recent Activity',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_recentActivity.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    child: Center(
                                      child: Text(
                                        'No recent activity',
                                        style: GoogleFonts.inter(
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ..._recentActivity.map((activity) {
                                    final activityType = activity['type'];
                                    final icon = ActivityUtils.getActivityIcon(
                                      activityType,
                                    );
                                    final iconColor =
                                        ActivityUtils.getActivityIconColor(
                                          activityType,
                                        );
                                    final bgColor =
                                        ActivityUtils.getActivityBgColor(
                                          activityType,
                                        );
                                    final timeAgo =
                                        DateTimeUtils.formatRelativeTime(
                                          activity['createdAt'] ??
                                              DateTime.now().toIso8601String(),
                                        );

                                    return _buildActivityItem(
                                      icon,
                                      bgColor,
                                      iconColor,
                                      activity['title'] ?? '',
                                      activity['description'] ?? '',
                                      timeAgo,
                                    );
                                  }),
                              ],

                              const SizedBox(height: 80), // Footer spacing
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/coach/create-session'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DASHBOARD SUMMARY", // Updated Title
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppPalette.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                _todaySessionsCount.toString(),
                'Sessions\n(Today)',
                onTap: () => context.push('/coach/sessions'),
              ),
              _buildSummaryItem(
                '£${_totalEarnings.toStringAsFixed(0)}', // Display Total Earnings
                'Total Earnings',
                onTap: () => context.push('/coach/earnings'),
              ),
              _buildSummaryItem(
                _todayStudentsCount.toString(),
                'Students\n(Today)',
                onTap: () => context.push('/coach/students'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => context.push('/coach/bookings'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.2,
                      ), // Darker bg for icon
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Bookings',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View incoming requests',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String value, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSessionSection() {
    // Find the next session (closest to now but in future)
    dynamic nextSession;
    if (_upcomingSessions.isNotEmpty) {
      nextSession = _upcomingSessions.first;
    }

    if (nextSession == null) {
      return const SizedBox.shrink(); // Don't show if no next session
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT SESSION',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppPalette.textSecondaryLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildNewSessionCard(context, nextSession, isNextSession: true),
      ],
    );
  }

  Widget _buildNewSessionCard(
    BuildContext context,
    dynamic session, {
    bool isNextSession = false,
  }) {
    final sessionId = session['_id'] ?? '';
    final title = session['title'] ?? 'Untitled Session';
    final location = session['location'] ?? 'Location TBD';

    final timeSlots = session['timeSlots'] as List?;
    final startTimeStr = timeSlots != null && timeSlots.isNotEmpty
        ? timeSlots[0]['startTime']
        : null;

    final formattedTime = startTimeStr != null
        ? DateTimeUtils.formatTime(startTimeStr)
        : 'TBD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isNextSession
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Button
                InkWell(
                  onTap: () => context.push('/session-details/$sessionId'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isNextSession ? 'Details' : 'View Plan',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&q=80&w=300',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    Color bgColor,
    Color iconColor,
    String name,
    String action,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' $action',
                        style: const TextStyle(
                          color: AppPalette.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
