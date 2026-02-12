import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../widgets/notification_button.dart';
import '../../services/auth_service.dart';

import '../../utils/date_time_utils.dart';
import '../../services/dashboard_service.dart';
import '../../services/guardian_service.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  int _selectedTabIndex = 0;
  int _selectedDay = DateTime.now().day;
  String _userName = 'Guardian';
  bool _isLoading = true;

  // Dynamic Data
  List<dynamic> _managedPlayers = [];
  List<dynamic> _upcomingSessions = [];
  Map<String, dynamic>? _stats;
  // List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
    // Listen for updates (e.g., new player added)
    GuardianService.playerUpdateNotifier.addListener(_loadDashboardData);
  }

  @override
  void dispose() {
    GuardianService.playerUpdateNotifier.removeListener(_loadDashboardData);
    super.dispose();
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
      final data = await DashboardService.getGuardianDashboard();
      if (data != null && mounted) {
        setState(() {
          // Flatten the managed players structure if needed, depends on API
          // API returns: managedPlayers: [{ player: { ... } }]
          // Ensure we handle potential nulls or different structures gracefully
          _managedPlayers = (data['managedPlayers'] as List? ?? []);
          _upcomingSessions = data['upcomingSessions'] ?? [];
          _stats = data['stats'];
          // _recentActivity = data['recentActivity'] ?? [];
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

  // Get filtered sessions for selected child
  List<dynamic> _getFilteredSessions() {
    if (_selectedTabIndex == 0) return _upcomingSessions;

    // index 1 corresponds to _managedPlayers[0], index 2 to [1], etc.
    if (_selectedTabIndex - 1 < _managedPlayers.length) {
      final selectedPlayerId = _managedPlayers[_selectedTabIndex - 1]['_id'];

      return _upcomingSessions.where((session) {
        final assigned = session['assignedPlayers'] as List?;
        if (assigned == null) return false;
        return assigned.any((ap) => ap['player']['_id'] == selectedPlayerId);
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Light grey background
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _ProfileHeader(
                      userName: _userName,
                    ).animate().fadeIn(duration: 600.ms),
                    const SizedBox(height: 20),

                    // Child Selection Tabs
                    _buildChildTabs().animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),

                    if (_selectedTabIndex == 0)
                      _buildOverviewView()
                    else
                      _buildChildDetailView(),
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
        // Up Next Section (Carousel)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader(title: 'Up Next'),
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
        const SizedBox(height: 12),
        if (_upcomingSessions.isEmpty)
          const Center(child: Text("No upcoming sessions"))
        else
          SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: _upcomingSessions.length,
              controller: PageController(viewportFraction: 0.92),
              padEnds: false,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _UpNextCard(session: _upcomingSessions[index]),
                );
              },
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 24),

        // This Week Calendar (Styled Container)
        const _SectionHeader(
          title: 'This Week',
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 12),
        _buildWeekCalendar().animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 24),

        // Performance Section - Using Stats instead
        const _SectionHeader(
          title: 'Overview Stats',
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 12),
        _buildStatsSection().animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
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

    // childName could be used for debugging or UI
    // For now we don't display it in the session item

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.blue.shade50,
              child: const Icon(
                Icons.sports_cricket,
                color: AppPalette.navyPrimary,
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
                  style: GoogleFonts.outfit(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50], // Defaulting to confirmed/green
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Confirmed', // Placeholder status
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
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
                  style: GoogleFonts.outfit(
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
                  style: GoogleFonts.outfit(
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
                      style: GoogleFonts.outfit(
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
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? Colors.white
                          : AppPalette.orangeAccent,
                      backgroundImage: playerImage != null
                          ? NetworkImage(playerImage)
                          : null,
                      child: playerImage == null
                          ? Text(
                              playerName[0],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      playerName,
                      style: GoogleFonts.outfit(
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

  Widget _buildWeekCalendar() {
    // Current Week (Dynamic)
    final now = DateTime.now();
    // Start from current day or start of week? Let's show current week (Mon-Sun)
    // Find previous Monday
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final days = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      // Format day name: Mon, Tue etc.
      final dayName = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][date.weekday - 1];

      return {
        'date': date.day,
        'day': dayName,
        'fullDate': date, // Use this for comparison if needed
      };
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          final date = day['date'] as int;
          final isSelected = _selectedDay == date;
          // final hasSession = date == 25 || date == 27;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = date;
              });
            },
            child: Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppPalette.orangeAccent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                // No border for unselected
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['day'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dot Indicator
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.5)
                          : (date == DateTime.now().day
                                ? AppPalette
                                      .orangeAccent // Highlight today
                                : Theme.of(context).dividerColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String userName;
  const _ProfileHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppPalette.orangeAccent,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=sarah'),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              decoration: const BoxDecoration(
                color: AppPalette.orangeAccent,
                borderRadius: BorderRadius.only(
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), // Light Blue
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.groups,
                        size: 14,
                        color: AppPalette.navyPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CRICKET',
                        style: GoogleFonts.inter(
                          color: AppPalette.navyPrimary,
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
                            color: const Color(0xFFE8F5E9), // Light Green
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_cricket,
                            color: Color(0xFF2E7D32),
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
                              color: AppPalette.orangeAccent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
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
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppPalette.navyPrimary,
                            ),
                          ),
                          Text(
                            session['location'] ?? 'Field',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        startTime,
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        session['location'] ?? 'TBD',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0), // Orange tint
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.deepOrange,
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
