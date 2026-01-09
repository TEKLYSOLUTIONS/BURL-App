import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class SessionDetailsScreen extends StatelessWidget {
  final String sessionId;

  const SessionDetailsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // For image background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Session Details',
          style: GoogleFonts.outfit(
            color: Colors
                .black, // Or white depending on image, usually white if transparent app bar over image?
            // Design image shows white bg header with back button.
            // Wait, design has image AT TOP, but App Bar structure look like simple back button.
            // Let's assume standard behavior: scrolled up = white, top = transparent/image.
            // Actually the design shows "Session Details" text in a white bar. Let's stick to standard opaque AppBar for simplicity unless designed otherwise.
            // Re-looking at image 5: Top bar is white, "Session Details" centered.
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
        flexibleSpace: Container(
          color: Colors.white,
        ), // Force white bg based on design
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Space for footer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=1000&auto=format&fit=crop',
                      ), // Field
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.orangeAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Upcoming',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, duration: 400.ms),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'U18 Advanced Defensive Drills',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date Time
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppPalette.orangeAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Oct 24, 2023  •  16:00 - 17:30',
                            style: GoogleFonts.inter(
                              color: AppPalette.textSecondaryLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: AppPalette.divider),
                      const SizedBox(height: 20),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickStat(Icons.timer_outlined, '90 min'),
                          _buildQuickStat(Icons.people_outline, '18 Players'),
                          _buildQuickStat(
                            Icons.fitness_center,
                            'High Intensity',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickAction(
                            Icons.check_circle_outline,
                            'Check-in',
                          ),
                          _buildQuickAction(
                            Icons.chat_bubble_outline,
                            'Message',
                          ),
                          _buildQuickAction(
                            Icons.edit_calendar_outlined,
                            'Edit Plan',
                          ),
                          _buildQuickAction(
                            Icons.assignment_add,
                            'Report',
                            onTap: () => context.push('/coach/session-report'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Section Title
                      _buildSectionTitle('Coach & Location'),
                      const SizedBox(height: 16),

                      // Coach Card
                      _buildInfoCard(
                        icon: const CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=12',
                          ),
                        ),
                        title: 'Coach Mike T.',
                        subtitle: 'Head Coach',
                        actionIcon: Icons.phone,
                      ),
                      const SizedBox(height: 12),
                      // Location Card
                      _buildInfoCard(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                          ),
                        ),
                        title: 'City Sports Complex',
                        subtitle: 'Field 4, North Entrance',
                        actionIcon: Icons.directions,
                      ),

                      const SizedBox(height: 32),

                      // Participants
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Going (14)'),
                          Text(
                            'View All',
                            style: GoogleFonts.outfit(
                              color: AppPalette.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildAvatar(
                              'Jason',
                              'https://i.pravatar.cc/150?img=60',
                            ),
                            const SizedBox(width: 16),
                            _buildAvatar(
                              'Sarah',
                              'https://i.pravatar.cc/150?img=44',
                            ),
                            const SizedBox(width: 16),
                            _buildAvatar(
                              'Mike',
                              'https://i.pravatar.cc/150?img=12',
                            ),
                            const SizedBox(width: 16),
                            _buildAvatar(
                              'Emma',
                              'https://i.pravatar.cc/150?img=20',
                            ),
                            const SizedBox(width: 16),
                            // Invite
                            Column(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[100],
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Invite',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppPalette.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      _buildSectionTitle('Session Plan'),
                      const SizedBox(height: 16),
                      // Timeline
                      _buildTimelineItem(
                        Icons.directions_run,
                        'Warm-up & Stretching',
                        '15m',
                        'Dynamic stretching, light jogging, and mobility work to prepare muscles.',
                        true,
                      ),
                      _buildTimelineItem(
                        Icons.sports_soccer,
                        'Defensive Box Drills',
                        '30m',
                        'Focus on shape, shifting, and communication in the back four.',
                        true,
                        isHighlight: true,
                      ),
                      _buildTimelineItem(
                        Icons.flag_outlined,
                        'Scrimmage',
                        '45m',
                        '11v11 practice match applying defensive principles.',
                        false,
                      ),

                      const SizedBox(height: 32),

                      // Coach Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPalette.navyLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppPalette.navyPrimary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coach\'s Note',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.navyPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Remember to bring your rain gear, forecast predicts showers later in the session.',
                                    style: GoogleFonts.inter(
                                      color: AppPalette.navyPrimary.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.textSecondaryLight),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppPalette.navyPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppPalette.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppPalette.navyPrimary,
      ),
    );
  }

  Widget _buildInfoCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required IconData actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          SizedBox(height: 48, width: 48, child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppPalette.orangeAccent,
                    fontSize: 12,
                  ), // Orange text as per design
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(actionIcon, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String url) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(radius: 22, backgroundImage: NetworkImage(url)),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppPalette.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    IconData icon,
    String title,
    String time,
    String desc,
    bool showLine, {
    bool isHighlight = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? AppPalette.orangeLight.withValues(alpha: 0.2)
                      : Colors.blue[50], // Light bg
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isHighlight
                      ? AppPalette.orangeAccent
                      : AppPalette.navyPrimary,
                ),
              ),
              if (showLine)
                Expanded(
                  child: VerticalDivider(color: Colors.grey[300], thickness: 1),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      color: AppPalette.textSecondaryLight,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
