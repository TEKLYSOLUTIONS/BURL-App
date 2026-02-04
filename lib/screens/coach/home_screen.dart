import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  int _totalSessions = 0;
  int _totalPlayers = 0;
  double _rating = 0.0;
  List<dynamic> _upcomingSessions = [];
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

    // If today, re-use dashboard load for full data (stats + activity)
    // If other date, just fetch sessions
    try {
      if (_isToday(date)) {
        await _loadDashboardData();
      } else {
        final response = await SessionService.getCoachSessions(date: date);
        if (mounted) {
          setState(() {
            _upcomingSessions = response['sessions'] as List<dynamic>;
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

      if (data != null && mounted) {
        setState(() {
          _totalSessions = data['stats']?['totalSessions'] ?? 0;
          _totalPlayers = data['stats']?['totalPlayers'] ?? 0;
          _rating = (data['stats']?['rating'] ?? 0.0).toDouble();
          _upcomingSessions = List.from(data['upcomingSessions'] ?? []);
          _recentActivity = List.from(data['recentActivity'] ?? []);
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
                              // Stats Cards (Only show if viewing "today" or maybe always? Users prefer consistency. Let's keep them)
                              // Actually, if we filter by date, maybe we just want to show sessions for that date.
                              // But the request was "integrate a calendar... to check particular day sessions".
                              // So filtering the "Upcoming Sessions" list is the key.

                              // Let's keep stats at the top for context.

                              // Stats Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      Icons.timer_outlined,
                                      _totalSessions.toString(),
                                      'Sessions',
                                      Colors.indigo[50]!,
                                      AppPalette.navyPrimary,
                                      onTap: () =>
                                          context.push('/coach/sessions'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      Icons.people_outline,
                                      _totalPlayers.toString(),
                                      'Players',
                                      Colors.orange[50]!,
                                      Colors.orange,
                                      onTap: () =>
                                          context.push('/coach/students'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      Icons.star_rounded,
                                      _rating.toStringAsFixed(1),
                                      'Rating',
                                      Colors.amber[50]!,
                                      Colors.amber,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn().slideX(),

                              const SizedBox(height: 32),

                              // Sessions List Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isToday(_selectedDate)
                                        ? 'Upcoming Sessions'
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
                              if (_upcomingSessions.isEmpty)
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
                                          'No sessions scheduled',
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
                                ..._upcomingSessions.map((session) {
                                  final timeSlots =
                                      session['timeSlots'] as List?;
                                  final startTime =
                                      timeSlots != null && timeSlots.isNotEmpty
                                      ? DateTimeUtils.formatTime(
                                          timeSlots[0]['startTime'],
                                        )
                                      : 'TBD';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildSessionCard(
                                      context,
                                      session['_id'] ?? '',
                                      session['location'] ?? 'TBD',
                                      session['title'] ?? 'Untitled Session',
                                      startTime,
                                      'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&q=80&w=300',
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

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppPalette.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    String sessionId,
    String location,
    String title,
    String time,
    String imageUrl, {
    Color? labelColor,
    Color? labelTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: labelColor ?? Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: labelTextColor ?? AppPalette.navyPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppPalette.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/session-details/$sessionId'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Plan', // Or "Details"
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
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
