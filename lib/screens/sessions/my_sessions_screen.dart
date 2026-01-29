import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
import '../../services/session_service.dart';
import '../../services/booking_service.dart';
import '../../utils/date_time_utils.dart';

class MySessionsScreen extends StatefulWidget {
  final bool isCoach;
  const MySessionsScreen({super.key, this.isCoach = true});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // API State
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _pastSessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.isCoach) {
      _fetchSessions();
    }
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isCoach) {
        // Coach: Fetch sessions they created
        final results = await Future.wait([
          SessionService.getCoachSessions(type: 'upcoming', limit: 50),
          SessionService.getCoachSessions(type: 'past', limit: 50),
        ]);

        setState(() {
          _upcomingSessions = List<Map<String, dynamic>>.from(
            results[0]['sessions'] ?? [],
          );
          _pastSessions = List<Map<String, dynamic>>.from(
            results[1]['sessions'] ?? [],
          );
          _isLoading = false;
        });
      } else {
        // Player/Guardian: Fetch their bookings
        final results = await Future.wait([
          BookingService.getPlayerBookings(type: 'upcoming', limit: 50),
          BookingService.getPlayerBookings(type: 'past', limit: 50),
        ]);

        setState(() {
          _upcomingSessions = List<Map<String, dynamic>>.from(
            results[0]['bookings'] ?? [],
          );
          _pastSessions = List<Map<String, dynamic>>.from(
            results[1]['bookings'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sessions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: Column(
        children: [
          // Standardized Light Header
          // Conditional Header: Dark for Coach, Light for others
          CoachAppBar(
            backgroundColor: widget.isCoach
                ? AppPalette.navyPrimary
                : Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    widget.isCoach ? 'My Sessions' : 'Sessions',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isCoach
                          ? Colors.white
                          : AppPalette.navyPrimary,
                    ),
                  ),
                ),
                NotificationButton(
                  iconColor: widget.isCoach
                      ? Colors.white
                      : AppPalette.navyPrimary,
                  backgroundColor: widget.isCoach
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white,
                  onTap: () => context.push(
                    widget.isCoach
                        ? '/coach/notifications'
                        : '/player/notifications',
                  ),
                ),
              ],
            ),
          ),

          // Tabs moved under the header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppPalette.navyPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppPalette.textSecondaryLight,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),

          // Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSessionList(isUpcoming: true),
                _buildSessionList(isUpcoming: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isCoach
          ? FloatingActionButton(
              onPressed: () => context.push('/coach/create-session'),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSessionList({required bool isUpcoming}) {
    // Show loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppPalette.navyPrimary),
        ),
      );
    }

    // Role-based data
    final sessions = widget.isCoach
        ? (isUpcoming ? _upcomingSessions : _pastSessions)
        : (isUpcoming
              ? [
                  {
                    'title': 'Advanced Tennis Technique',
                    'coach': 'Coach Sarah',
                    'date': 'Tomorrow, 10:00 AM',
                    'status': 'Confirmed',
                    'statusColor': Colors.green[50],
                    'statusTextColor': Colors.green[700],
                    'image': 'assets/images/welcome_batting.png',
                    'action': 'View Details',
                    'isCoachView': false,
                  },
                ]
              : []);

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppPalette.textDisabled.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming sessions' : 'No past sessions',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppPalette.textSecondaryLight,
              ),
            ),
            if (isUpcoming && widget.isCoach) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.push('/coach/create-session'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Your First Session'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.isCoach ? _fetchSessions : () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final isCoachView = widget.isCoach;

          if (isCoachView) {
            return _buildCoachSessionCard(session, index);
          } else {
            return _buildStudentSessionCard(session, index);
          }
        },
      ),
    );
  }

  Widget _buildCoachSessionCard(Map<String, dynamic> session, int index) {
    // Extract first time slot for display
    final timeSlots = session['timeSlots'] as List? ?? [];
    if (timeSlots.isEmpty) return const SizedBox.shrink();

    final timeSlot = timeSlots[0];
    final startTime = DateTime.parse(timeSlot['startTime'] as String).toLocal();
    final duration = timeSlot['durationMinutes'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session['location'] as String,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1565C0),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  session['title'] as String,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateTimeUtils.formatTimeFromDateTime(startTime)} • ${DateTimeUtils.formatDuration(duration)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateTimeUtils.formatSessionDate(startTime),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () =>
                      context.push('/session-details/${session['_id']}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Plan',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
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
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 110,
              height: 110,
              color: Colors.grey[200],
              child: const Icon(
                Icons.sports_cricket,
                size: 40,
                color: AppPalette.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }

  Widget _buildStudentSessionCard(Map<String, dynamic> booking, int index) {
    // For players/guardians, the data is a booking with nested session
    final session = booking['session'] as Map<String, dynamic>? ?? {};
    final occurrenceDate = booking['occurrenceDate'] != null
        ? DateTime.parse(booking['occurrenceDate'] as String)
        : DateTime.now();
    final bookingStatus = booking['status'] as String? ?? 'pending';

    // Map booking status to display status
    String displayStatus;
    Color statusColor;
    Color statusTextColor;

    switch (bookingStatus.toLowerCase()) {
      case 'confirmed':
        displayStatus = 'Confirmed';
        statusColor = Colors.green[50]!;
        statusTextColor = Colors.green[700]!;
        break;
      case 'pending':
        displayStatus = 'Pending';
        statusColor = Colors.orange[50]!;
        statusTextColor = Colors.orange[700]!;
        break;
      case 'cancelled':
        displayStatus = 'Cancelled';
        statusColor = Colors.red[50]!;
        statusTextColor = Colors.red[700]!;
        break;
      case 'completed':
        displayStatus = 'Completed';
        statusColor = Colors.blue[50]!;
        statusTextColor = Colors.blue[700]!;
        break;
      default:
        displayStatus = 'Scheduled';
        statusColor = Colors.grey[50]!;
        statusTextColor = Colors.grey[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Simple status icon mapping
                      if (displayStatus == 'Confirmed')
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: statusTextColor,
                        ),
                      if (displayStatus == 'Pending')
                        Icon(
                          Icons.access_time_filled,
                          size: 14,
                          color: statusTextColor,
                        ),
                      if (displayStatus == 'Scheduled')
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: statusTextColor,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        displayStatus,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  session['title'] as String? ?? 'Untitled Session',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateTimeUtils.formatSessionDate(occurrenceDate),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (session['coach'] as Map<String, dynamic>?)?['fullName']
                              as String? ??
                          'Unknown Coach',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        session['location'] as String? ?? 'Location TBD',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: AppPalette.navyPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'For: ${(booking['player'] as Map<String, dynamic>?)?['fullName'] as String? ?? 'Unknown Player'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppPalette.navyPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    final sessionId = session['_id'] as String?;
                    if (sessionId != null && sessionId.isNotEmpty) {
                      context.push('/session-details/$sessionId');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session details not available'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppPalette.navyPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }
}
