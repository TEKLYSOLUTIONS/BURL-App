import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/cached_avatar.dart'; // Import CachedAvatar
import '../../widgets/calendar/horizontal_week_calendar.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/session_service.dart';

import '../../utils/date_time_utils.dart';
import '../../utils/session_utils.dart';
import '../../services/dashboard_service.dart';
import '../../services/guardian_service.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen>
    with AutomaticKeepAliveClientMixin<GuardianHomeScreen> {
  @override
  bool get wantKeepAlive => true;

  int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String _userName = 'Guardian';
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isLoadingSessions = false;

  // Dynamic Data
  List<dynamic> _managedPlayers = [];
  List<dynamic> _dateFilteredSessions = [];
  Map<String, dynamic>? _stats;
  // List<dynamic> _recentActivity = [];

  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen for updates (e.g., new player added)
    GuardianService.playerUpdateNotifier.addListener(_loadDashboardData);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload dashboard every time this screen becomes active (first open + return from other routes)
    if (!_initialLoadDone || _managedPlayers.isEmpty) {
      _initialLoadDone = true;
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    GuardianService.playerUpdateNotifier.removeListener(_loadDashboardData);
    super.dispose();
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
            final guardianProfile =
                profileData['guardianProfile'] as Map<String, dynamic>?;
            _profileImageUrl = (guardianProfile?['profilePhoto'] ??
                    profileData['profileImage'] ??
                    profileData['profileUrl'])
                ?.toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DashboardService.getGuardianDashboard(),
        SessionService.getGuardianSessions(date: _selectedDate),
      ]);
      final data = results[0];
      final sessionsData = results[1];
      if (data != null && mounted) {
        setState(() {
          _managedPlayers = (data['managedPlayers'] as List? ?? []);
          _stats = data['stats'];
          _dateFilteredSessions =
              sessionsData?['sessions'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading guardian dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSessionsForDate(DateTime date) async {
    setState(() => _isLoadingSessions = true);
    try {
      final result = await SessionService.getGuardianSessions(date: date);
      if (mounted) {
        setState(() {
          _dateFilteredSessions =
              result['sessions'] as List<dynamic>? ?? [];
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions for date: $e');
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}';

  // Get filtered sessions for selected child
  List<dynamic> _getFilteredSessions() {
    if (_selectedTabIndex == 0) return _dateFilteredSessions;

    // index 1 corresponds to _managedPlayers[0], index 2 to [1], etc.
    if (_selectedTabIndex - 1 < _managedPlayers.length) {
      final selectedPlayerId = _managedPlayers[_selectedTabIndex - 1]['_id'];

      return _dateFilteredSessions.where((session) {
        final assigned = session['assignedPlayers'] as List?;
        if (assigned == null) return false;
        return assigned.any((ap) => ap['player']['_id'] == selectedPlayerId);
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Light grey background
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ProfileHeader(
                        userName: _userName,
                        profileImageUrl: _profileImageUrl,
                      ).animate().fadeIn(duration: 600.ms),
                    ),
                    const SizedBox(height: 20),

                    // Child Selection Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildChildTabs().animate().fadeIn(delay: 200.ms),
                    ),
                    const SizedBox(height: 12),

                    // 📅 Horizontal Calendar (Let it span full width so it doesn't get clipped on right)
                    HorizontalWeekCalendar(
                      initialDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                        _loadSessionsForDate(date);
                      },
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _selectedTabIndex == 0
                          ? _buildOverviewView()
                          : _buildChildDetailView(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sessions Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: _isToday(_selectedDate)
                  ? 'Up Next'
                  : 'Sessions on ${_formatDate(_selectedDate)}',
            ),
            TextButton(
              onPressed: () {
                context.go('/guardian/sessions');
              },
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  color: AppPalette.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            if (_isLoadingSessions) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (_dateFilteredSessions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isToday(_selectedDate)
                            ? 'No sessions today'
                            : 'No sessions on ${_formatDate(_selectedDate)}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: _dateFilteredSessions.map((session) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UpNextCard(session: session),
                );
              }).toList(),
            );
          },
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 24),

        // Overview Stats
        const _SectionHeader(
          title: 'Overview Stats',
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 12),
        _buildStatsSection().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildChildDetailView() {
    String childName = 'Child';
    if (_selectedTabIndex > 0 &&
        _selectedTabIndex - 1 < _managedPlayers.length) {
      childName = _managedPlayers[_selectedTabIndex - 1]['fullName'].split(
        ' ',
      )[0];
    }

    final sessions = _getFilteredSessions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Using Stats instead of Performance for now
        const _SectionHeader(title: 'Overview Stats'),
        const SizedBox(height: 12),
        _buildStatsSection(),
        const SizedBox(height: 24),

        _SectionHeader(title: '$childName\'s Sessions'),
        const SizedBox(height: 12),

        if (sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No sessions found for this child."),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return _buildSessionItem(sessions[index]);
            },
          ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSessionItem(dynamic session) {
    String startTime = 'TBD';
    if (session['timeSlots'] != null &&
        (session['timeSlots'] as List).isNotEmpty) {
      startTime = DateTimeUtils.formatTime(
        session['timeSlots'][0]['startTime'],
      );
    }

    final primaryColor = SessionUtils.getSessionPrimaryColor(context, session);

    // childName could be used for debugging or UI
    // For now we don't display it in the session item

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SessionUtils.getSessionColor(context, session),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.sports_cricket,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['title'] ?? 'Training Session',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session['coach'] != null
                      ? 'Coach ${session['coach']['fullName']}'
                      : 'No Coach',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  startTime,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Confirmed',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final sessionId = session['_id']?.toString();
                  if (sessionId != null && sessionId.isNotEmpty) {
                    String dateParam = '';
                    if (session['timeSlots'] != null &&
                        (session['timeSlots'] as List).isNotEmpty) {
                      final slotStart = session['timeSlots'][0]['startTime'];
                      if (slotStart != null) {
                        final dt = DateTime.tryParse(slotStart.toString())
                            ?.toLocal();
                        if (dt != null) {
                          dateParam = '?date=${dt.toIso8601String()}';
                        }
                      }
                    }
                    context.push(
                        '/guardian/session-details/$sessionId$dateParam');
                  }
                },
                child: Text(
                  'View Session',
                  style: TextStyle(
                    color: AppPalette.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        // Managed Players Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: AppPalette.orangeAccent,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: AppPalette.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_stats?['managedPlayers'] ?? 0}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Players Managed',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Upcoming Sessions Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Upcoming',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_stats?['upcomingSessions'] ?? 0}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Sessions Planned',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildTabs() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _managedPlayers.length + 1, // +1 for "Overview"
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;

          if (index == 0) {
            // Overview Tab
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard_rounded,
                      size: 18,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Overview',
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Child Tabs
            final player = _managedPlayers[index - 1];
            final playerName = player['fullName'].split(' ')[0];
            // Ideally use player['profilePhoto'] if available
            final playerImage = player['profilePhoto'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 20, 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CachedAvatar(
                      imageUrl: playerImage ?? '',
                      radius: 18,
                      backgroundColor:
                          isSelected ? Colors.white : AppPalette.orangeAccent,
                      fallbackText: playerName,
                      foregroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      playerName,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  const _ProfileHeader({required this.userName, this.profileImageUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        profileImageUrl != null && profileImageUrl!.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppPalette.orangeAccent,
          backgroundImage:
              hasPhoto ? NetworkImage(profileImageUrl!) : null,
          child: hasPhoto
              ? null
              : Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateTimeUtils.getGreeting(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
            ],
          ),
        ),
        NotificationButton(
          onTap: () => context.push('/guardian/notifications'),
          iconColor: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
      ],
    );
  }
}

class _UpNextCard extends StatelessWidget {
  final dynamic session;
  const _UpNextCard({required this.session});

  @override
  Widget build(BuildContext context) {
    String startTime = 'TBD';
    if (session['timeSlots'] != null &&
        (session['timeSlots'] as List).isNotEmpty) {
      startTime = DateTimeUtils.formatTime(
        session['timeSlots'][0]['startTime'],
      );
    }

    String childName = 'Child';
    if (session['assignedPlayers'] != null &&
        (session['assignedPlayers'] as List).isNotEmpty &&
        session['assignedPlayers'][0]['player'] != null) {
      final playerObj = session['assignedPlayers'][0]['player'];
      if (playerObj is Map && playerObj['fullName'] != null) {
        childName = (playerObj['fullName'] as String).split(' ')[0];
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final primaryColor = SessionUtils.getSessionPrimaryColor(context, session);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SessionUtils.getSessionColor(context, session),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Orange Border Left Strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CRICKET badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? primaryColor.withValues(alpha: 0.15)
                        : primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CRICKET',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.green.withValues(alpha: 0.15)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.sports_cricket,
                            color: isDark
                                ? Colors.green[300]
                                : const Color(0xFF2E7D32),
                            size: 24,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).cardColor,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              childName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['title'] ?? 'Training',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            session['location'] ?? 'Field',
                            style: GoogleFonts.inter(
                              color: subtleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: subtleColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        startTime,
                        style: GoogleFonts.inter(
                          color: subtleColor,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 16, color: subtleColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        session['location'] ?? 'TBD',
                        style: GoogleFonts.inter(
                          color: subtleColor,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    final sessionId = session['_id']?.toString();
                    if (sessionId != null && sessionId.isNotEmpty) {
                      String dateParam = '';
                      if (session['timeSlots'] != null &&
                          (session['timeSlots'] as List).isNotEmpty) {
                        final slotStart = session['timeSlots'][0]['startTime'];
                        if (slotStart != null) {
                          final dt = DateTime.tryParse(slotStart.toString())
                              ?.toLocal();
                          if (dt != null) {
                            dateParam = '?date=${dt.toIso8601String()}';
                          }
                        }
                      }
                      context.push(
                          '/guardian/session-details/$sessionId$dateParam');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
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
    );
  }
}
