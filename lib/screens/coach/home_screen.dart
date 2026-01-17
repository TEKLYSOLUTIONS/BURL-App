import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
<<<<<<< HEAD
import '../../widgets/headers/coach_app_bar.dart';
=======
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Header Section
<<<<<<< HEAD
            CoachAppBar(
=======
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 20,
                24,
                30,
              ),
              decoration: const BoxDecoration(
                color: AppPalette.navyPrimary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
<<<<<<< HEAD
                        radius: 20, // Reduced from 24
=======
                        radius: 24,
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=11',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OCT 24, 2023',
                            style: GoogleFonts.inter(
<<<<<<< HEAD
                              fontSize: 10, // Reduced from 12
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
=======
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70, // Lighter text for date
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Good Morning, Coach',
                            style: GoogleFonts.outfit(
<<<<<<< HEAD
                              fontSize: 18, // Reduced from 20
=======
                              fontSize: 20, // Slightly smaller to fit
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
<<<<<<< HEAD
                      const Spacer(),
                      NotificationButton(
                        hasNotification: true,
                        onTap: () => context.push('/coach/notifications'),
                      ),
=======
                      const NotificationButton(hasNotification: true),
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
                    ],
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.timer_outlined,
                          '3',
                          'Sessions',
                          Colors.indigo[50]!,
                          AppPalette.navyPrimary,
                          onTap: () => context.push('/coach/sessions'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.people_outline,
                          '24',
                          'Players',
                          Colors.orange[50]!,
                          Colors.orange,
                          onTap: () => context.push('/coach/students'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.star_rounded,
                          '4.8',
                          'Rating',
                          Colors.amber[50]!,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(),

                  const SizedBox(height: 32),

                  // Upcoming Sessions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Sessions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/coach/sessions'),
                        child: Text(
                          'See all',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSessionCard(
                    context,
                    'Field 2',
                    'Quarterback Drills',
                    '10:00 AM',
                    'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&q=80&w=300',
                  ),
                  const SizedBox(height: 16),
                  _buildSessionCard(
                    context,
                    'Room B',
                    'Team Video Review',
                    '02:00 PM',
                    'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&q=80&w=300',
                    labelColor: Colors.purple[100]!,
                    labelTextColor: Colors.purple,
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    Icons.directions_run,
                    Colors.orange[100]!,
                    Colors.orange,
                    'Mike T.',
                    'logged 30 mins cardio',
                    '15 mins ago',
                  ),
                  _buildActivityItem(
                    Icons.local_hospital,
                    Colors.red[100]!,
                    Colors.red,
                    'Emma R.',
                    'updated injury status',
                    '1 hr ago',
                  ),
                  _buildActivityItem(
                    Icons.calendar_today,
                    Colors.blue[100]!,
                    Colors.blue,
                    'Practice',
                    'schedule changed for Friday',
                    '2 hrs ago',
                  ),

                  const SizedBox(height: 80), // Footer spacing
                ],
              ),
            ),
          ],
        ),
      ),
<<<<<<< HEAD
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/coach/create-session'),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppPalette.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
          ],
=======
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => context.push('/coach/create-session'),
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add, color: Colors.white),
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
        ),
      ),
    );
  }

<<<<<<< HEAD
=======
  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppPalette.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
  Widget _buildSessionCard(
    BuildContext context,
    String location,
    String title,
    String time,
    String imageUrl, {
    Color? labelColor,
    Color? labelTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                    color: labelColor ?? Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: labelTextColor ?? AppPalette.navyPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppPalette.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/session-details/1'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Plan', // Or "Details"
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppPalette.navyPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    Color bgColor,
    Color iconColor,
    String name,
    String action,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppPalette.navyPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' $action',
                        style: const TextStyle(
                          color: AppPalette.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[300]),
        ],
      ),
    );
  }
}
