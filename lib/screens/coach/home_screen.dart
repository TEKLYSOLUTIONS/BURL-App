import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/palette.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
import '../../widgets/calendar/horizontal_week_calendar.dart'; // Import Calendar
import '../../widgets/cached_avatar.dart'; // Import CachedAvatar

import '../../services/dashboard_service.dart';
import '../../services/session_service.dart'; // Import SessionService
import '../../services/earnings_service.dart'; // Import EarningsService
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/responsive.dart'; // Import Responsive utility
import '../../utils/currency_helper.dart';
import '../../utils/session_utils.dart'; // Import SessionUtils
import '../../navigation/app_router.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> with RouteAware, WidgetsBindingObserver {
  String _userName = 'Coach';
  String? _profileImageUrl;
  String? _userId;
  bool _isUploadingImage = false;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now(); // Track selected date
  Timer? _refreshTimer;

  // Dashboard data
  int _todaySessionsCount = 0;
  double _totalEarnings = 0.0;
  String _currency = CurrencyHelper.defaultCurrency; // Default currency
  int _todayStudentsCount = 0;
  List<dynamic> _todaysSessions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserAndCurrency();
    _loadDashboardData();
    _startAutoRefreshTimer();
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
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        _loadDashboardData(forceRefresh: true);
      }
    }
  }

  void _startAutoRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isToday(_selectedDate) && mounted) {
        _loadDashboardData(forceRefresh: true);
      }
    });
  }

  @override
  void didPopNext() {
    // Refresh data when returning to this screen
    _loadUserAndCurrency();
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

  // Merged method: loads user name, profile image, userId AND currency in a single API call
  Future<void> _loadUserAndCurrency() async {
    try {
      final profile = await ProfileService.getProfile();
      final detectedCurrency = await CurrencyHelper.loadUserCurrency();
      if (mounted) {
        final name = profile['fullName'] as String?;
        setState(() {
          if (name != null) _userName = name.split(' ').first;
          _userId = profile['_id'] ?? profile['id'];
          _profileImageUrl = profile['coachProfile']?['profilePhoto'] ??
              profile['profileImage'] ??
              profile['profileUrl'];
          _currency = detectedCurrency;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _changeProfilePhoto() async {
    if (_userId == null) return;
    try {
      final pickedFile = await StorageService.showImageSourceSheet(context);
      if (pickedFile == null) return;
      setState(() => _isUploadingImage = true);
      final imageUrl = await StorageService.uploadProfilePicture(
        userId: _userId!,
        imageFile: File(pickedFile.path),
      );
      await ProfileService.updateProfile({'profileImage': imageUrl});
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      if (forceRefresh) {
        DashboardService.invalidateCache();
        SessionService.invalidateCoachSessionsCache();
      }

      final results = await Future.wait([
        DashboardService.getCoachDashboard(),
        SessionService.getCoachSessions(date: DateTime.now()),
      ]);

      final data = results[0];
      final todaySessionsResponse = results[1] as Map<String, dynamic>;

      if (data != null && mounted) {
        setState(() {
          final todaySummary = data['todaySummary'];
          final stats = data['stats']; // Get stats for Total Earnings

          _todaySessionsCount = todaySummary?['sessions'] ?? 0;
          // _todayEarnings removed
          _totalEarnings = (stats?['totalEarnings'] ?? 0).toDouble();
          // Currency now loaded from profile location
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
                    GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: Stack(
                        children: [
                          CachedAvatar(
                            imageUrl: _profileImageUrl ?? '',
                            radius: context.responsive.circularSize(
                              20,
                              min: 18,
                              max: 24,
                            ),
                            backgroundColor: AppPalette.navyPrimary,
                            fallbackText: _userName,
                          ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: CircleAvatar(
                                radius: context.responsive.circularSize(
                                  20,
                                  min: 18,
                                  max: 24,
                                ),
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.4),
                                child: const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.spacing.sm),
                    Expanded(
                      child: Column(
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
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
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
            child: RefreshIndicator(
              onRefresh: () => _loadDashboardData(forceRefresh: true),
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                  width: double.infinity,
                                  padding: EdgeInsets.all(
                                    context.spacing.lg,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                      context.responsive.radius(24),
                                    ),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: context.responsive.iconSize(32),
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                        ),
                                        SizedBox(height: context.spacing.sm),
                                        Text(
                                          _isToday(_selectedDate)
                                              ? 'No sessions today'
                                              : 'No sessions scheduled',
                                          style: GoogleFonts.inter(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: context.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  _todaySessionsCount.toString(),
                  'Sessions',
                  onTap: () => context.push('/coach/sessions'),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  // Removed hardcoded currency
                  EarningsService.formatCurrency(
                    _totalEarnings,
                    currency: _currency,
                  ).split('.')[0], // Display Dynamic Currency
                  'Earnings',
                  onTap: () => context.push('/coach/earnings'),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  _todayStudentsCount.toString(),
                  'Students',
                  onTap: () => context.push('/coach/students'),
                ),
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize:
                      context.responsive.sp(32), // Using a fixed base size
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                maxLines: 1,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
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

    // 3. Find the next UPCOMING session using isFinished from backend
    final upcomingSessions = _todaysSessions.where((s) {
      final status = s['status'];
      if (status == 'cancelled') return false;
      // Use backend-provided isFinished flag; fall back to checking endTime locally
      final isFinished = s['isFinished'] as bool? ?? false;
      return !isFinished;
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

    // Use displaySlot from backend (correct occurrence for this date/context).
    // Fall back to scanning timeSlots for the selected date if backend didn't provide it.
    Map<String, dynamic>? relevantSlot =
        session['displaySlot'] as Map<String, dynamic>?;

    if (relevantSlot == null) {
      final timeSlots = session['timeSlots'] as List?;
      if (timeSlots != null) {
        for (final slot in timeSlots) {
          final st = slot['startTime'];
          if (st != null) {
            final slotDate = DateTime.parse(st).toLocal();
            if (slotDate.year == _selectedDate.year &&
                slotDate.month == _selectedDate.month &&
                slotDate.day == _selectedDate.day) {
              relevantSlot = slot as Map<String, dynamic>;
              break;
            }
          }
        }
        if (relevantSlot == null && timeSlots.isNotEmpty) {
          relevantSlot = timeSlots[0] as Map<String, dynamic>;
        }
      }
    }

    final startTimeStr = relevantSlot?['startTime'];
    final formattedTime =
        startTimeStr != null ? DateTimeUtils.formatTime(startTimeStr) : 'TBD';

    // Use backend-provided isFinished; fall back to end-time check
    bool isFinishedToday = session['isFinished'] as bool? ?? false;
    if (!(session.containsKey('isFinished'))) {
      final now = DateTime.now();
      DateTime? endTime;
      if (relevantSlot != null && relevantSlot['endTime'] != null) {
        endTime = DateTime.parse(relevantSlot['endTime']).toLocal();
      } else if (startTimeStr != null) {
        final startTime = DateTime.parse(startTimeStr).toLocal();
        final duration = relevantSlot?['durationMinutes'] ?? 60;
        endTime = startTime.add(Duration(minutes: duration));
      }
      if (endTime != null && endTime.isBefore(now)) {
        isFinishedToday = true;
      } else if (session['status'] == 'completed') {
        isFinishedToday = true;
      }
    }

    final primaryColor = SessionUtils.getSessionPrimaryColor(context, session);

    return Container(
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: SessionUtils.getSessionColor(context, session),
        borderRadius: BorderRadius.circular(context.responsive.radius(24)),
        border:
            isNextSession ? Border.all(color: primaryColor, width: 2) : null,
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
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      context.responsive.radius(8),
                    ),
                  ),
                  child: Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: context.text.caption,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
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
                              color: AppPalette.orangeAccent,
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
                        onTap: () {
                          final dateParam = _selectedDate.toIso8601String();
                          context.push(
                              '/coach/session-details/$sessionId?date=$dateParam');
                        },
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
                                isNextSession
                                    ? 'Details'
                                    : (isFinishedToday
                                        ? 'Finished'
                                        : 'View Plan'),
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
                                isFinishedToday
                                    ? Icons.check_circle_outline
                                    : Icons.arrow_forward,
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
        ],
      ),
    );
  }
}
