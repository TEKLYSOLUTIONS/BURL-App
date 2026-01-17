import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';

class MySessionsScreen extends StatefulWidget {
  final bool isCoach;
  const MySessionsScreen({super.key, this.isCoach = true});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                  hasNotification: true,
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
    // Role-based Mock Data
    final sessions = widget.isCoach
        ? (isUpcoming
              ? [
                  {
                    'title': 'Quarterback Drills',
                    'location': 'Field 2',
                    'time': '10:00 AM',
                    'image': 'assets/images/welcome_batting.png',
                    'tagColor': const Color(0xFFE3F2FD),
                    'tagTextColor': const Color(0xFF1565C0),
                    'isCoachView': true,
                  },
                  {
                    'title': 'Team Video Review',
                    'location': 'Room B',
                    'time': '02:00 PM',
                    'image': 'assets/images/welcome_fielding.png',
                    'tagColor': const Color(0xFFF3E5F5),
                    'tagTextColor': const Color(0xFF7B1FA2),
                    'isCoachView': true,
                  },
                ]
              : [])
        : (isUpcoming
              ? [
                  {
                    'title': 'Advanced Tennis Technique',
                    'coach': 'Coach Sarah',
                    'date': 'Tomorrow, 10:00 AM',
                    'status': 'Confirmed',
                    'statusColor': Colors.green[50], // Light Green
                    'statusTextColor': Colors.green[700],
                    'image': 'assets/images/welcome_batting.png',
                    'action': 'View Details',
                    'isCoachView': false,
                  },
                  {
                    'title': 'Strength & Conditioning',
                    'coach': 'Coach Mike',
                    'date': 'Friday, 2:00 PM',
                    'status': 'Pending',
                    'statusColor': Colors.orange[50], // Light Orange
                    'statusTextColor': Colors.orange[800],
                    'image': 'assets/images/welcome_bowling.png',
                    'action': 'Reschedule',
                    'isCoachView': false,
                  },
                  {
                    'title': 'Pro Yoga Flow',
                    'coach': 'Coach Elena',
                    'date': 'Mon, 12 Oct • 8:00 AM',
                    'status': 'Scheduled',
                    'statusColor': Colors.blue[50], // Light Blue
                    'statusTextColor': Colors.blue[700],
                    'image': 'assets/images/welcome_fielding.png',
                    'action': null,
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
              'No sessions found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppPalette.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isCoachView = session['isCoachView'] as bool;

        if (isCoachView) {
          // Coach View Card (Existing Design)
          return _buildCoachSessionCard(session, index);
        } else {
          // Guardian/Student View Card (New Design)
          return _buildStudentSessionCard(session, index);
        }
      },
    );
  }

  Widget _buildCoachSessionCard(Map<String, dynamic> session, int index) {
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
                    color: session['tagColor'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session['location'] as String,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: session['tagTextColor'] as Color,
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
                      session['time'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/session-details/1'),
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
            child: Image.asset(
              session['image'] as String,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[200],
                  child: const Icon(Icons.sports_cricket, color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }

  Widget _buildStudentSessionCard(Map<String, dynamic> session, int index) {
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
                    color: session['statusColor'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Simple status icon mapping could go here if needed
                      if (session['status'] == 'Confirmed')
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: session['statusTextColor'],
                        ),
                      if (session['status'] == 'Pending')
                        Icon(
                          Icons.access_time_filled,
                          size: 14,
                          color: session['statusTextColor'],
                        ),
                      if (session['status'] == 'Scheduled')
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: session['statusTextColor'],
                        ),
                      const SizedBox(width: 4),
                      Text(
                        session['status'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: session['statusTextColor'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  session['title'] as String,
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
                      session['date'] as String,
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
                      session['coach'] as String,
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
                      Icons.child_care, // Changed icon for variety
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'For: ${session['title'] == 'Advanced Tennis Technique' ? 'Leo' : 'Mia'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppPalette.navyPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (session['action'] != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: session['action'] == 'Reschedule'
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                        border: session['action'] == 'Reschedule'
                            ? Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: Text(
                        session['action'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: session['action'] == 'Reschedule'
                              ? Colors.orange[800]
                              : AppPalette.navyPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              session['image'] as String,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 80, height: 80, color: Colors.grey[200]),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }
}
