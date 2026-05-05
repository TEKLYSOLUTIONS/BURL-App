import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../services/booking_service.dart';
import '../../../utils/session_utils.dart';
import '../../../utils/date_time_utils.dart';

class PlayerSessionsView extends StatefulWidget {
  const PlayerSessionsView({super.key});

  @override
  State<PlayerSessionsView> createState() => _PlayerSessionsViewState();
}

class _PlayerSessionsViewState extends State<PlayerSessionsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _pastSessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        BookingService.getPlayerBookings(type: 'upcoming', limit: 50),
        BookingService.getPlayerBookings(type: 'past', limit: 50),
      ]);

      if (mounted) {
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
      if (mounted) {
        setState(() => _isLoading = false);
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
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),

        // Session Lists
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSessionList(sessions: _upcomingSessions, isUpcoming: true),
              _buildSessionList(sessions: _pastSessions, isUpcoming: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionList({
    required List<Map<String, dynamic>> sessions,
    required bool isUpcoming,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming sessions' : 'No past sessions',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: sessions.length,
        itemBuilder: (context, index) =>
            _buildStudentSessionCard(sessions[index], index),
      ),
    );
  }

  Widget _buildStudentSessionCard(Map<String, dynamic> booking, int index) {
    final session = booking['session'] as Map<String, dynamic>? ?? {};
    final occurrenceDate = booking['occurrenceDate'] != null
        ? DateTime.parse(booking['occurrenceDate'] as String).toLocal()
        : DateTime.now();
    final bookingStatus = booking['status'] as String? ?? 'pending';

    final primaryColor = SessionUtils.getSessionPrimaryColor(context, session);

    String displayStatus;
    Color statusColor;
    Color statusTextColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (bookingStatus.toLowerCase()) {
      case 'confirmed':
        displayStatus = 'Confirmed';
        statusColor =
            isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green[50]!;
        statusTextColor = isDark ? Colors.greenAccent : Colors.green[700]!;
        break;
      case 'pending':
        displayStatus = 'Pending';
        statusColor =
            isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange[50]!;
        statusTextColor = isDark ? Colors.orangeAccent : Colors.orange[700]!;
        break;
      case 'cancelled':
        displayStatus = 'Cancelled';
        statusColor =
            isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red[50]!;
        statusTextColor = isDark ? Colors.redAccent : Colors.red[700]!;
        break;
      case 'completed':
        displayStatus = 'Completed';
        statusColor =
            isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue[50]!;
        statusTextColor = isDark ? Colors.blueAccent : Colors.blue[700]!;
        break;
      default:
        displayStatus = 'Scheduled';
        statusColor =
            isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey[50]!;
        statusTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SessionUtils.getSessionColor(context, session),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
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
                      Icon(
                        displayStatus == 'Confirmed'
                            ? Icons.check_circle
                            : displayStatus == 'Pending'
                                ? Icons.access_time_filled
                                : Icons.calendar_month,
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
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateTimeUtils.formatSessionDate(occurrenceDate),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (() {
                        final coachData =
                            session['coach'] as Map<String, dynamic>?;
                        if (coachData == null) return 'Unknown Coach';
                        final profile =
                            coachData['coachProfile'] as Map<String, dynamic>?;
                        return coachData['fullName'] as String? ??
                            profile?['fullName'] as String? ??
                            'Unknown Coach';
                      })(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.face,
                      size: 14,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (() {
                        final playerData =
                            booking['player'] as Map<String, dynamic>?;
                        if (playerData == null) return 'Unknown Player';
                        return playerData['fullName'] as String? ??
                            'Unknown Player';
                      })(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        session['location'] as String? ?? 'Location TBD',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final sessionId = session['_id'] as String?;
                    if (sessionId != null && sessionId.isNotEmpty) {
                      final dateParam = occurrenceDate.toIso8601String();
                      final isGuardian = GoRouterState.of(context)
                          .uri
                          .toString()
                          .startsWith('/guardian');
                      final route = isGuardian
                          ? '/guardian/session-details/$sessionId?date=$dateParam'
                          : '/player/session-details/$sessionId?date=$dateParam';
                      final result = await context.push(route);
                      if (result == true) _fetchSessions();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
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
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: primaryColor,
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
