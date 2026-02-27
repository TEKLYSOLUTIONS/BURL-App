import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../services/session_service.dart';
import '../../../utils/session_utils.dart';
import '../../../utils/date_time_utils.dart';

class GroupSessionsTab extends StatefulWidget {
  const GroupSessionsTab({super.key});

  @override
  State<GroupSessionsTab> createState() => _GroupSessionsTabState();
}

class _GroupSessionsTabState extends State<GroupSessionsTab>
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
        SessionService.getCoachSessions(type: 'upcoming', limit: 50),
        SessionService.getCoachSessions(type: 'past', limit: 50),
      ]);

      if (mounted) {
        setState(() {
          _upcomingSessions = List<Map<String, dynamic>>.from(
            results[0]['sessions'] ?? [],
          );
          _pastSessions = List<Map<String, dynamic>>.from(
            results[1]['sessions'] ?? [],
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
        // Tab Bar for Upcoming / Past
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
            unselectedLabelColor: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
            if (isUpcoming) ...[
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
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: sessions.length,
        itemBuilder: (context, index) =>
            _buildCoachSessionCard(sessions[index], index),
      ),
    );
  }

  Widget _buildCoachSessionCard(Map<String, dynamic> session, int index) {
    // Use displaySlot sent by backend — this is the CORRECT occurrence to show
    // (next future slot for upcoming, most recent past slot for past).
    // Fall back to timeSlots[0] only if backend didn't provide it.
    final Map<String, dynamic>? displaySlot =
        session['displaySlot'] as Map<String, dynamic>? ??
            (session['timeSlots'] as List? ?? [])
                .cast<Map<String, dynamic>>()
                .firstOrNull;

    if (displaySlot == null) return const SizedBox.shrink();

    final startTime =
        DateTime.parse(displaySlot['startTime'] as String).toLocal();
    final duration = displaySlot['durationMinutes'] as int? ?? 60;

    // isFinished comes from backend; fallback to time-based check
    final bool isFinished = session['isFinished'] as bool? ??
        DateTime.parse(displaySlot['endTime'] as String)
            .toLocal()
            .isBefore(DateTime.now());

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationTagColor = isDark
        ? Theme.of(context).colorScheme.primaryContainer
        : const Color(0xFFE3F2FD);
    final locationTextColor = isDark
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : const Color(0xFF1565C0);

    final primaryColor = SessionUtils.getSessionPrimaryColor(context, session);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SessionUtils.getSessionColor(context, session),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
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
                // Location tag + Finished badge row
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: locationTagColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session['location'] as String? ?? 'TBD',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: locationTextColor,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (isFinished) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 12,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Finished',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  session['title'] as String? ?? 'Untitled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 16,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateTimeUtils.formatTimeFromDateTime(startTime)} • ${DateTimeUtils.formatDuration(duration)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateTimeUtils.formatSessionDate(startTime),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons row
                Row(
                  children: [
                    // Start button — only for upcoming (not yet finished)
                    if (!isFinished) ...[
                      InkWell(
                        onTap: () => context.push(
                          '/session-attendance/${session['_id']}',
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Start',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Details / View Plan button
                    Flexible(
                      child: InkWell(
                        onTap: () async {
                          final dateParam = startTime.toIso8601String();
                          final result = await context.push(
                            '/coach/session-details/${session['_id']}?date=$dateParam',
                          );
                          if (result == true) _fetchSessions();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isFinished ? 'Details' : 'View Plan',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isFinished
                                    ? Icons.check_circle_outline
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.sports_cricket,
                size: 40,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }
}
