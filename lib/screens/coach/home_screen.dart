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
  double _todayEarnings = 0.0;
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
          _todaySessionsCount = todaySummary?['sessions'] ?? 0;
          _todayEarnings = (todaySummary?['earnings'] ?? 0).toDouble();
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
      backgroundColor: AppPalette.backgroundLight,
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
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${DateTimeUtils.getGreeting()}, $_userName',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                                      color: AppPalette.navyPrimary,
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
                                          color: AppPalette.navyPrimary,
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 48,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _isToday(_selectedDate)
                                              ? 'No sessions today'
                                              : 'No sessions scheduled',
                                          style: GoogleFonts.inter(
                                            color: Colors.grey,
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
                                    color: AppPalette.navyPrimary,
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
                                          color: Colors.grey,
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
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S SUMMARY",
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
              _buildSummaryItem(_todaySessionsCount.toString(), 'Sessions'),
              _buildSummaryItem(
                '£${_todayEarnings.toStringAsFixed(0)}', // Assuming GBP as per request image
                'Earnings',
              ),
              _buildSummaryItem(_todayStudentsCount.toString(), 'Students'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppPalette.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isNextSession
            ? Border.all(color: AppPalette.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
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
                    color: AppPalette.navyPrimary,
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
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
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
                      color: Colors.grey[100],
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
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppPalette.navyPrimary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                      color: AppPalette.navyPrimary,
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
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.orange),
        ],
      ),
    );
  }
}
