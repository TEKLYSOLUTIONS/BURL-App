import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  int _selectedTabIndex = 0;
  int _selectedDay = 24; // Oct 24 selected by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

              // Up Next Section
              const _SectionHeader(
                title: 'Up Next',
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              const _UpNextCard()
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 24),

              // This Week Calendar
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
          ),
        ),
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
                color: isSelected
                    ? AppPalette.navyPrimary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppPalette.navyPrimary
                      : Theme.of(context).dividerColor,
                ),
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
                    Icon(
                      Icons.dashboard,
                      size: 18,
                      color: isSelected
                          ? AppPalette.white
                          : AppPalette.navyPrimary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    tab['name'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? AppPalette.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
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
    final days = [
      {'date': 23, 'day': 'Mon'},
      {'date': 24, 'day': 'Tue'},
      {'date': 25, 'day': 'Wed'},
      {'date': 26, 'day': 'Thu'},
      {'date': 27, 'day': 'Fri'},
      {'date': 28, 'day': 'Sat'},
      {'date': 29, 'day': 'Sun'},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final day = days[index];
          final date = day['date'] as int;
          final isSelected = _selectedDay == date;
          final hasSession = date == 24 || date == 27; // Sample data

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = date;
              });
            },
            child: Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppPalette.orangeAccent
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppPalette.orangeAccent
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['day'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? AppPalette.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$date',
                    style: TextStyle(
                      color: isSelected
                          ? AppPalette.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasSession)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.white
                            : AppPalette.orangeAccent,
                        shape: BoxShape.circle,
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: Theme.of(context).iconTheme.color,
            size: 22,
          ),
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
  const _UpNextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.navyPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups, size: 14, color: AppPalette.navyPrimary),
                    SizedBox(width: 4),
                    Text(
                      'U15 TEAM',
                      style: TextStyle(
                        color: AppPalette.navyPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppPalette.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_cricket,
                  color: AppPalette.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soccer Practice',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Technical Drills & Scrimmage',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
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
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Today, 4:00 - 5:30 PM',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppPalette.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Field 4, Central Park',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                backgroundColor: AppPalette.orangeAccent.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Text(
                'Details',
                style: TextStyle(
                  color: AppPalette.orangeAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              label: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppPalette.orangeAccent,
              ),
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attendance Rate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
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
        // Drills Missed Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppPalette.warning,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '4/5',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drills Missed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Text('😟', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Text('😊', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Text('😊', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Text('😊', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
