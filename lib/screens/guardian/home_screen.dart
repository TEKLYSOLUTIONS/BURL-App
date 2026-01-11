import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../widgets/notification_button.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  int _selectedTabIndex = 0;
  int _selectedDay = 25; // Matching the image (Wed 25)

  // Mock sessions for carousel and child view
  final List<Map<String, dynamic>> _carouselSessions = [
    {
      'title': 'Soccer Practice',
      'subtitle': 'Technical Drills & Scrimmage',
      'time': 'Today, 4:00 - 5:30 PM',
      'location': 'Field 4, Central Park',
      'child': 'Leo',
      'image': 'assets/images/welcome_batting.png', // Placeholder
    },
    {
      'title': 'Tennis Match',
      'subtitle': 'Quarter Finals',
      'time': 'Tomorrow, 10:00 - 11:30 AM',
      'location': 'Court 1, Sports Complex',
      'child': 'Mia',
      'image': 'assets/images/welcome_fielding.png', // Placeholder
    },
  ];

  final List<Map<String, dynamic>> _childSessions = [
    {
      'title': 'Batting Practice',
      'coach': 'Coach Sarah',
      'date': 'Tomorrow, 10:00 AM',
      'status': 'Confirmed',
      'statusColor': Colors.green[50], // Light Green
      'statusTextColor': Colors.green[700],
      'image': 'assets/images/welcome_batting.png',
      'tag': 'Batting',
    },
    {
      'title': 'Fielding Drills',
      'coach': 'Coach Mike',
      'date': 'Friday, 2:00 PM',
      'status': 'Pending',
      'statusColor': Colors.orange[50], // Light Orange
      'statusTextColor': Colors.orange[800],
      'image': 'assets/images/welcome_fielding.png',
      'tag': 'Fielding',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              const _ProfileHeader().animate().fadeIn(duration: 600.ms),
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
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: _carouselSessions.length,
            controller: PageController(viewportFraction: 0.92),
            padEnds: false,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _UpNextCard(session: _carouselSessions[index]),
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

        // Performance Section
        const _SectionHeader(
          title: 'Performance',
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 12),
        const _PerformanceSection()
            .animate()
            .fadeIn(delay: 800.ms)
            .slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildChildDetailView() {
    final childName = _selectedTabIndex == 1 ? 'Leo' : 'Mia';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance first for Child View
        const _SectionHeader(title: 'Performance'),
        const SizedBox(height: 12),
        const _PerformanceSection(),
        const SizedBox(height: 24),

        _SectionHeader(title: '$childName\'s Sessions'),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _childSessions.length,
          itemBuilder: (context, index) {
            return _buildSessionItem(_childSessions[index]);
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              session['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 60, height: 60, color: Colors.grey[200]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['title'],
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session['coach'],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session['date'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: session['statusColor'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              session['status'],
              style: TextStyle(
                color: session['statusTextColor'],
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildTabs() {
    final tabs = [
      {'name': 'Overview', 'avatar': null},
      {'name': 'Leo', 'avatar': 'https://i.pravatar.cc/150?u=leo'},
      {'name': 'Mia', 'avatar': 'https://i.pravatar.cc/150?u=mia'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _selectedTabIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppPalette.navyPrimary
                      : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab['avatar'] != null) ...[
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(tab['avatar'] as String),
                      backgroundColor: AppPalette.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                  ] else if (index == 0) ...[
                    const Icon(
                      Icons.dashboard_rounded,
                      size: 18,
                      color: AppPalette.navyPrimary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    tab['name'] as String,
                    style: TextStyle(
                      color: AppPalette.navyPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekCalendar() {
    // Matches the provided image style
    final days = [
      {'date': 23, 'day': 'Mon'},
      {'date': 24, 'day': 'Tue'},
      {'date': 25, 'day': 'Wed'},
      {'date': 26, 'day': 'Thu'},
      {'date': 27, 'day': 'Fri'},
      {'date': 28, 'day': 'Sat'},
      {'date': 29, 'day': 'Sun'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                          : AppPalette.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppPalette.navyPrimary,
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
                          : (date == 29
                                ? AppPalette.orangeAccent
                                : Colors.grey[300]), // Example logic
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
  const _ProfileHeader();

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
                'GOOD MORNING',
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
                'Sarah Wilson',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        NotificationButton(
          hasNotification: true, // You can make this dynamic later
          onTap: () => context.push('/guardian/notifications'),
          iconColor:
              AppPalette.navyPrimary, // Makes it visible on light background
          backgroundColor: const Color(0xFFF1F5F9),
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
  final Map<String, dynamic> session;
  const _UpNextCard({required this.session});

  @override
  Widget build(BuildContext context) {
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
                        'U15 TEAM',
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
                            Icons.sports_soccer, // Changed to match "Soccer"
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
                              session['child'],
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
                            session['title'],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppPalette.navyPrimary,
                            ),
                          ),
                          Text(
                            session['subtitle'],
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
                      child: Image.asset(
                        session['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                        ),
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
                        session['time'],
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
                        'Field 4, Central Park', // Mock
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
                  // Added GestureDetector
                  onTap: () {
                    context.push(
                      '/session-details/${session['id'] ?? '1'}',
                    ); // Navigate to details
                  },
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

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Attendance Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                      Icons.trending_up,
                      color: AppPalette.success,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '+2%',
                      style: TextStyle(
                        color: AppPalette.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '95%',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attendance Rate',
                  style: GoogleFonts.inter(
                    color: AppPalette.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.95,
                    backgroundColor: AppPalette.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppPalette.navyPrimary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Drills Missed Card (Empty/Placeholder style to match image)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 20),
                const SizedBox(height: 45), // Maintain height similarity
                Text(
                  'Needs Focus', // Mock
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppPalette.navyPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
