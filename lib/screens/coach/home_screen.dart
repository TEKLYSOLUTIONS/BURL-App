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
import '../../services/earnings_service.dart'; // Import EarningsService
import '../../utils/date_time_utils.dart';
import '../../utils/responsive.dart'; // Import Responsive utility

import '../../utils/session_utils.dart'; // Import SessionUtils
import '../../navigation/app_router.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> with RouteAware {
  String _userName = 'Coach';
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now(); // Track selected date

  // Dashboard data
  int _todaySessionsCount = 0;
  double _totalEarnings = 0.0;
  String _currency = 'USD'; // Default currency
  int _todayStudentsCount = 0;
  List<dynamic> _todaysSessions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh data when returning to this screen
    _loadDashboardData();
    // Also reload sessions for the selected date if it's not today
    if (!_isToday(_selectedDate)) {
      _loadSessionsForDate(_selectedDate);
    }
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
          _totalEarnings = (stats?['totalEarnings'] ?? 0).toDouble();
          _currency = stats?['currency'] ?? 'USD'; // Fetch currency
          _todayStudentsCount = todaySummary?['students'] ?? 0;

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
                    CircleAvatar(
                      radius: context.responsive.circularSize(
                        20,
                        min: 18,
                        max: 24,
                      ),
                      backgroundImage: const NetworkImage(
                        'https://i.pravatar.cc/150?img=11',
                      ),
                    ),
                    SizedBox(width: context.spacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateTimeUtils.getCurrentDateFormatted(),
                          style: GoogleFonts.inter(
                            fontSize: context.text.tiny,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7),
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${DateTimeUtils.getGreeting()}, $_userName',
                          style: GoogleFonts.inter(
                            fontSize: context.text.h4,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    NotificationButton(
                      onTap: () => context.push('/coach/notifications'),
                      iconColor: Theme.of(context)
                          .colorScheme
                          .onPrimary, // Ensure visibility on primary background
                      backgroundColor: Colors.white.withValues(
                        alpha: 0.1,
                      ), // Subtle background
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
                    padding: EdgeInsets.symmetric(vertical: context.spacing.md),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.screenPadding,
                    ),
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
                                SizedBox(height: context.spacing.lg),
                                _buildQuickActions(),
                                SizedBox(height: context.spacing.lg),
                                _buildNextSessionSection(),
                                SizedBox(
                                  height: context.spacing.sectionSpacing,
                                ),
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
                                    style: GoogleFonts.inter(
                                      fontSize: context.text.h4,
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
                                          fontSize: context.text.bodySmall,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: context.spacing.md),

                              // Dynamic sessions from API - always use _todaysSessions
                              // (populated for selected date by _loadSessionsForDate)
                              if (_todaysSessions.isEmpty)
                                Container(
                                  padding: EdgeInsets.all(
                                    context.spacing.sectionSpacing,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                      context.responsive.radius(16),
                                    ),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: context.responsive.iconSize(48),
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                        ),
                                        SizedBox(height: context.spacing.md),
                                        Text(
                                          _isToday(_selectedDate)
                                              ? 'No sessions today'
                                              : 'No sessions scheduled',
                                          style: GoogleFonts.inter(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: context.text.bodySmall,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ..._todaysSessions.map((session) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: context.spacing.md,
                                    ),
                                    child: _buildNewSessionCard(
                                      context,
                                      session,
                                    ),
                                  );
                                }),

                              SizedBox(height: context.spacing.sectionSpacing),

                              // Recent Activity Removed
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
        backgroundColor: AppPalette.orangeAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.responsive.radius(24)),
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
              fontSize: context.text.caption,
              fontWeight: FontWeight.w600,
              color: AppPalette.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: context.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                _todaySessionsCount.toString(),
                'Sessions',
                onTap: () => context.push('/coach/sessions'),
              ),
              _buildSummaryItem(
                // Removed hardcoded currency
                EarningsService.formatCurrency(
                  _totalEarnings,
                  currency: _currency,
                ).split('.')[0], // Display Dynamic Currency
                'Total Earnings',
                onTap: () => context.push('/coach/earnings'),
              ),
              _buildSummaryItem(
                _todayStudentsCount.toString(),
                'Students',
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
            borderRadius: BorderRadius.circular(context.responsive.radius(16)),
            child: Container(
              padding: EdgeInsets.all(context.spacing.md),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  context.responsive.radius(16),
                ),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.spacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.2,
                      ), // Darker bg for icon
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: context.responsive.iconSize(20),
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Bookings',
                          style: GoogleFonts.inter(
                            fontSize: context.text.h4,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          'View incoming requests',
                          style: GoogleFonts.inter(
                            fontSize: context.text.caption,
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
                    size: context.responsive.iconSize(24),
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
      borderRadius: BorderRadius.circular(context.responsive.radius(12)),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.sm),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: context.text.h1,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: context.text.bodySmall,
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
    // 1. Check for TODAY'S sessions first
    final hasTodaySessions = _todaysSessions.isNotEmpty;

    if (!hasTodaySessions) {
      // 2. Explicitly show "No sessions today" if today is empty
      // We do NOT populate this with tomorrow's session anymore, per user request.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT SESSION',
            style: GoogleFonts.inter(
              fontSize: context.text.caption,
              fontWeight: FontWeight.w600,
              color: AppPalette.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.spacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                context.responsive.radius(24),
              ),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available,
                  size: context.responsive.iconSize(32),
                  color: Theme.of(context).disabledColor,
                ),
                SizedBox(height: context.spacing.sm),
                Text(
                  'No sessions today',
                  style: GoogleFonts.inter(
                    fontSize: context.text.bodySmall,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 3. Find the next UPCOMING session
    // Filter out completed, cancelled, or past sessions
    final now = DateTime.now();
    final upcomingSessions = _todaysSessions.where((s) {
      final status = s['status'];
      if (status == 'completed' || status == 'cancelled') return false;

      // check time
      final timeSlots =
          (s['timeSlots'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (timeSlots.isEmpty) return false;

      final startTimeStr = timeSlots[0]['startTime'];
      if (startTimeStr == null) return false;

      final startTime = DateTime.parse(startTimeStr).toLocal();
      // Consider it "next" if it hasn't ended yet (start + duration)
      // or simply if it's in the future or currently running
      final duration = timeSlots[0]['durationMinutes'] ?? 60;
      final endTime = startTime.add(Duration(minutes: duration));

      return endTime.isAfter(now);
    }).toList();

    if (upcomingSessions.isEmpty) {
      // Same "No sessions" view but specific for "No MORE sessions today"
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT SESSION',
            style: GoogleFonts.inter(
              fontSize: context.text.caption,
              fontWeight: FontWeight.w600,
              color: AppPalette.textSecondaryLight,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.spacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                context.responsive.radius(24),
              ),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: context.responsive.iconSize(32),
                  color: Colors.green.withValues(alpha: 0.5),
                ),
                SizedBox(height: context.spacing.sm),
                Text(
                  'All sessions completed',
                  style: GoogleFonts.inter(
                    fontSize: context.text.bodySmall,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final nextSession = upcomingSessions.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT SESSION',
          style: GoogleFonts.inter(
            fontSize: context.text.caption,
            fontWeight: FontWeight.w600,
            color: AppPalette.textSecondaryLight,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: context.spacing.md),
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
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.responsive.radius(24)),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.sm,
                    vertical: context.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      context.responsive.radius(8),
                    ),
                  ),
                  child: Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: context.text.caption,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: context.spacing.sm),

                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: context.text.h4,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.spacing.sm),

                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: context.responsive.iconSize(16),
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: context.spacing.xs),
                    Text(
                      formattedTime,
                      style: GoogleFonts.inter(
                        fontSize: context.text.bodySmall,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.md),

                // Buttons Row
                Row(
                  children: [
                    // Start Session Button (only for next session)
                    if (isNextSession)
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              context.push('/session-attendance/$sessionId'),
                          borderRadius: BorderRadius.circular(
                            context.responsive.radius(12),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacing.sm,
                              vertical: context.spacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(
                                context.responsive.radius(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: context.responsive.iconSize(16),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                                SizedBox(width: context.spacing.xs),
                                Text(
                                  'Start',
                                  style: GoogleFonts.inter(
                                    fontSize: context.text.bodySmall,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (isNextSession) SizedBox(width: context.spacing.sm),

                    // Details Button
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            context.push('/session-details/$sessionId'),
                        borderRadius: BorderRadius.circular(
                          context.responsive.radius(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.spacing.sm,
                            vertical: context.spacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              context.responsive.radius(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isNextSession ? 'Details' : 'View Plan',
                                style: GoogleFonts.inter(
                                  fontSize: context.text.bodySmall,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: context.spacing.xs),
                              Icon(
                                Icons.arrow_forward,
                                size: context.responsive.iconSize(14),
                                color: Theme.of(context).colorScheme.onSurface,
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
          SizedBox(width: context.spacing.sm),
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(context.responsive.radius(16)),
            child: Image.network(
              SessionUtils.getSessionImage(session), // Dynamic Image
              width: context.responsive.circularSize(100, min: 80, max: 120),
              height: context.responsive.circularSize(100, min: 80, max: 120),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: context.responsive.circularSize(
                    100,
                    min: 80,
                    max: 120,
                  ),
                  height: context.responsive.circularSize(
                    100,
                    min: 80,
                    max: 120,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.sports_cricket,
                    size: context.responsive.iconSize(40),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
