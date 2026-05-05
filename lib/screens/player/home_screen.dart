import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/cached_avatar.dart';
import '../../widgets/calendar/horizontal_week_calendar.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/session_service.dart';
import '../../services/search_service.dart';
import '../../utils/date_time_utils.dart';
import '../../services/profile_service.dart';

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  String _userName = 'Player';
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isLoadingRatings = true;

  DateTime _selectedDate = DateTime.now();

  // For the selected date
  List<dynamic> _dateSessions = [];

  // Dashboard overview  
  Map<String, dynamic>? _stats;

  // Ratings from session reports
  double _avgRating = 0.0;
  double _avgTechnical = 0.0;
  double _avgPhysical = 0.0;
  double _avgMental = 0.0;
  int _totalReports = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  // Featured coaches
  List<dynamic> _featuredCoaches = [];
  bool _isLoadingCoaches = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadUserData(),
      _loadDashboardAndSessions(),
      _loadRatings(),
      _loadFeaturedCoaches(),
    ]);
  }

  Future<void> _loadUserData() async {
    try {
      final results = await Future.wait([
        AuthService.getUserName(),
        ProfileService.getProfile(),
      ]);
      final name = results[0] as String?;
      final profileData = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          if (name != null) _userName = name.split(' ').first;
          if (profileData != null) {
            // ProfileService.getProfile() returns the user object directly
            // with playerProfile nested inside (not { user:..., profile:... })
            if (profileData['profileImage'] != null) {
              _profileImageUrl = profileData['profileImage'] as String?;
            } else {
              final playerProfile =
                  profileData['playerProfile'] as Map<String, dynamic>?;
              if (playerProfile != null &&
                  playerProfile['profilePhoto'] != null) {
                _profileImageUrl = playerProfile['profilePhoto'] as String?;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadDashboardAndSessions({bool silent = false}) async {
    // Show spinner only on very first load (no data yet)
    if (!silent && _dateSessions.isEmpty && _stats == null) {
      if (mounted) setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        DashboardService.getPlayerDashboard(),
        SessionService.getPlayerSessions(date: _selectedDate),
      ]);
      final dashboard = results[0] as Map?;
      final sessionsResponse = (results[1] as Map?) ?? {};

      if (mounted) {
        setState(() {
          if (dashboard != null) _stats = dashboard['stats'];
          _dateSessions = (sessionsResponse['sessions'] as List<dynamic>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard/sessions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSessionsForDate(DateTime date, {bool silent = false}) async {
    // Only show spinner if no sessions are currently displayed
    if (!silent && _dateSessions.isEmpty) {
      if (mounted) setState(() => _isLoading = true);
    }
    try {
      final response = await SessionService.getPlayerSessions(date: date);
      if (mounted) {
        setState(() {
          _dateSessions = response['sessions'] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions for date: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatings() async {
    if (mounted) setState(() => _isLoadingRatings = true);
    try {
      final id = await AuthService.getUserId();
      if (id == null) {
        if (mounted) setState(() => _isLoadingRatings = false);
        return;
      }
      final reports = await SessionService.getPlayerSessionReports(id);
      if (mounted) {
        double sumRating = 0, sumTech = 0, sumPhys = 0, sumMental = 0;
        int count = 0;
        for (final r in reports) {
          final tech = _toDouble(r['batting'] ?? r['technicalRating']);
          final phys = _toDouble(r['bowling'] ?? r['physicalRating']);
          final mental = _toDouble(r['fielding'] ?? r['mentalRating']);
          final overall = _toDouble(r['overall'] ?? r['overallRating']);
          if (tech > 0 || phys > 0 || mental > 0) {
            sumTech += tech;
            sumPhys += phys;
            sumMental += mental;
            sumRating += overall > 0 ? overall : (tech + phys + mental) / 3;
            count++;
          }
        }
        setState(() {
          _totalReports = reports.length;
          if (count > 0) {
            _avgRating = sumRating / count;
            _avgTechnical = sumTech / count;
            _avgPhysical = sumPhys / count;
            _avgMental = sumMental / count;
          }
          _isLoadingRatings = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ratings: $e');
      if (mounted) setState(() => _isLoadingRatings = false);
    }
  }

  Future<void> _loadFeaturedCoaches() async {
    if (mounted) setState(() => _isLoadingCoaches = true);
    try {
      final result = await SearchService().searchCoaches(limit: 4);
      final coaches = (result['coaches'] ??
          result['data'] ??
          result['results'] ??
          []) as List<dynamic>;
      if (mounted) {
        setState(() {
          _featuredCoaches = coaches;
          _isLoadingCoaches = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured coaches: $e');
      if (mounted) setState(() => _isLoadingCoaches = false);
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Fixed Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppPalette.orangeAccent.withValues(alpha: 0.2),
                        ),
                        child: ClipOval(
                          child: CachedAvatar(
                            imageUrl: _profileImageUrl ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_userName)}&background=random',
                            radius: 24,
                            backgroundColor:
                                AppPalette.orangeAccent.withValues(alpha: 0.2),
                            foregroundColor: AppPalette.orangeAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateTimeUtils.getCurrentDateFormatted(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateTimeUtils.getGreeting()}, $_userName',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(width: 8),
                  NotificationButton(
                    onTap: () =>
                        context.push('/player/notifications'),
                    iconColor:
                        Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.2),
            ),

            // â”€â”€ Horizontal Calendar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            HorizontalWeekCalendar(
              initialDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                _loadSessionsForDate(date);
              },
            ).animate().fadeIn(delay: 50.ms),

            // â”€â”€ Scrollable body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // â”€â”€ Sessions for selected date â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isToday(_selectedDate)
                              ? 'TODAY\'S SESSIONS'
                              : 'SESSIONS FOR ${_formatDate(_selectedDate)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (_isToday(_selectedDate))
                          GestureDetector(
                            onTap: () => context.go('/player/sessions'),
                            child: Text(
                              'View All',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.orangeAccent,
                              ),
                            ),
                          ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_dateSessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy,
                                size: 48,
                                color: Theme.of(context).disabledColor),
                            const SizedBox(height: 12),
                            Text(
                              _isToday(_selectedDate)
                                  ? 'No sessions today'
                                  : 'No sessions on this day',
                              style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  context.go('/player/search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.orangeAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Find a Coach'),
                            ),
                          ],
                        ),
                      ).animate().fadeIn()
                    else
                      ..._dateSessions
                          .take(3)
                          .map((s) => _buildSessionCard(context, s)),

                    const SizedBox(height: 24),

                    // â”€â”€ Performance Metrics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text(
                      'PERFORMANCE METRICS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        children: [
                          _MetricCard(
                            icon: Icons.calendar_month,
                            iconColor: Colors.blue,
                            label: 'Sessions',
                            value:
                                '${_stats?['completedSessions'] ?? 0}',
                            trend: 'Completed',
                            trendColor: Colors.blue,
                            trendIsText: true,
                          ),
                          const SizedBox(width: 12),
                          _MetricCard(
                            icon: Icons.timer,
                            iconColor: Colors.green,
                            label: 'Training Hrs',
                            value:
                                '${_stats?['hoursTraining'] ?? 0}',
                            trend: 'Total Hours',
                            trendIsText: true,
                            trendColor: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _MetricCard(
                            icon: Icons.description_outlined,
                            iconColor: Colors.orange,
                            label: 'Reports',
                            value: '$_totalReports',
                            trend: 'Coach Reports',
                            trendIsText: true,
                            trendColor: Colors.orange,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

                    const SizedBox(height: 24),

                    // â”€â”€ Ratings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MY RATINGS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.push('/player/reports'),
                          child: Text(
                            'View Reports',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.orangeAccent,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 450.ms),
                    const SizedBox(height: 12),

                    if (_isLoadingRatings)
                      const Center(child: CircularProgressIndicator())
                    else if (_avgRating == 0.0 && _totalReports == 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_border_rounded,
                                color: Colors.amber, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'No ratings yet.\nComplete sessions to see your progress.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 470.ms)
                    else
                      _buildRatingsCard(context).animate().fadeIn(delay: 470.ms),

                    const SizedBox(height: 24),

                    // â”€â”€ Quick Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text(
                      'QUICK ACTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.search_rounded,
                            label: 'Book Coach',
                            onTap: () => context.go('/player/search'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.description_outlined,
                            label: 'My Reports',
                            onTap: () =>
                                context.push('/player/reports'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 24),

                    // â”€â”€ Featured Coaches â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FEATURED COACHES',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/player/search'),
                          child: Text(
                            'See All',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.orangeAccent,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 12),

                    if (_isLoadingCoaches)
                      const Center(child: CircularProgressIndicator())
                    else if (_featuredCoaches.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No coaches available right now.',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5)),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Column(
                        children: _featuredCoaches
                            .take(4)
                            .map((coach) =>
                                _buildFeaturedCoachCard(context, coach))
                            .toList(),
                      ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, Map<String, dynamic> session) {
    final coach = session['coach'];
    final String coachName = coach is Map
        ? (coach['fullName'] ?? 'Coach')
        : 'Coach';
    final String? coachPhoto = coach is Map
        ? (coach['profilePhoto'] ?? coach['profileUrl'])
        : null;

    final slots = session['timeSlots'] as List?;
    final displaySlot = session['displaySlot'] as Map?;
    final slot = displaySlot ?? (slots != null && slots.isNotEmpty ? slots[0] as Map : null);

    final sessionId = (session['_id'] ?? session['id'] ?? '').toString();
    final slotDateStr = slot?['startTime'] as String?;

    void navigateToDetail() {
      if (sessionId.isEmpty) return;
      final uri = slotDateStr != null
          ? '/player/session-details/$sessionId?date=${Uri.encodeComponent(slotDateStr)}'
          : '/player/session-details/$sessionId';
      context.push(uri);
    }

    return GestureDetector(
      onTap: navigateToDetail,
      child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).shadowColor.withValues(alpha: 0.3),
            blurRadius: 12,
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
                if (slot != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppPalette.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateTimeUtils.formatRelativeTime(
                              slot['startTime']),
                          style: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  session['title'] ?? 'Training Session',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).colorScheme.onPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${session['location'] ?? 'TBD'} â€¢ Coach $coachName',
                  style: GoogleFonts.inter(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                if (slot != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateTimeUtils.formatTime(slot['startTime']),
                        style: GoogleFonts.inter(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: navigateToDetail,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppPalette.orangeAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View Session',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedAvatar(
              imageUrl: coachPhoto ?? '',
              radius: 30,
              fallbackText: coachName,
              backgroundColor: AppPalette.navyPrimary,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildRatingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Overall rating row
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                _avgRating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'avg overall',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
              const Spacer(),
              Text(
                '$_totalReports ${_totalReports == 1 ? 'report' : 'reports'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildRatingItem(
                      'Technical', _avgTechnical, Colors.green)),
              Expanded(
                  child: _buildRatingItem(
                      'Physical', _avgPhysical, Colors.purple)),
              Expanded(
                  child: _buildRatingItem(
                      'Mental', _avgMental, Colors.teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 10.0,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildFeaturedCoachCard(
      BuildContext context, dynamic coach) {
    final Map<String, dynamic> c =
        coach is Map<String, dynamic> ? coach : {};
    // API returns CoachProfile with userId populated as { fullName, profilePhoto, ... }
    final userObj = c['userId'] is Map ? c['userId'] as Map : null;
    final String name = userObj?['fullName'] ??
        c['fullName'] ??
        c['name'] ??
        'Coach';
    final String? photo = userObj?['profilePhoto'] ??
        c['profilePhoto'] ??
        c['profileUrl'];
    final List<dynamic> specs =
        c['specializations'] as List<dynamic>? ?? [];
    final String role = specs.isNotEmpty
        ? specs.take(2).join(' \u2022 ')
        : c['specialization']?.toString() ?? 'Cricket Coach';
    final String? city = c['city'] as String?;
    final dynamic rating = c['rating'] ?? c['avgRating'];
    final int reviews = (c['reviewCount'] as num?)?.toInt() ?? 0;
    // Use the user's _id for navigation (CoachDetailsScreen expects userId)
    final String coachId = userObj?['_id']?.toString() ??
        c['_id']?.toString() ??
        '';

    return GestureDetector(
      onTap: coachId.isNotEmpty
          ? () async {
              final now = DateTime.now();
              if (now.difference(_lastTap).inMilliseconds < 1500) return;
              _lastTap = now;
              await context.push('/player/coach-details/$coachId');
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .shadowColor
                  .withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedAvatar(
                imageUrl: photo ?? '',
                radius: 28,
                fallbackText: name,
                backgroundColor: AppPalette.navyPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    role,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (city != null && city.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            city,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        rating != null
                            ? double.tryParse(rating.toString())
                                    ?.toStringAsFixed(1) ??
                                'N/A'
                            : 'N/A',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$reviews reviews',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String trend;
  final Color trendColor;
  final bool trendIsText;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendColor,
    this.trendIsText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).shadowColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              if (!trendIsText)
                Icon(Icons.trending_up, size: 14, color: trendColor),
              if (!trendIsText) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .shadowColor
                  .withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: AppPalette.orangeAccent, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


