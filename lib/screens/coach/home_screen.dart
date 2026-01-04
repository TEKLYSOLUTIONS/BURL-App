import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Avatar
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppPalette.navyPrimary,
                      child: Text(
                        'C',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppPalette.textSecondaryLight,
                            ),
                          ),
                          Text(
                            'Coach Dashboard',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                      color: AppPalette.navyPrimary,
                    ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 32),

                // Stats Overview Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPalette.navyPrimary, AppPalette.navyLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.navyPrimary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Overview',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.people_outline,
                            value: '24',
                            label: 'Students',
                          ),
                          _StatItem(
                            icon: Icons.event_available,
                            value: '6',
                            label: 'Sessions',
                          ),
                          _StatItem(
                            icon: Icons.schedule,
                            value: '8h',
                            label: 'Hours',
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),

                const SizedBox(height: 32),

                // Upcoming Sessions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Sessions',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.textPrimaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'View All',
                        style: GoogleFonts.inter(
                          color: AppPalette.orangeAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                // Session Cards
                const _SessionCard(
                  title: 'Batting Technique',
                  time: '10:00 AM - 11:30 AM',
                  students: '8 Students',
                  color: AppPalette.orangeAccent,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),

                const SizedBox(height: 12),

                const _SessionCard(
                  title: 'Bowling Masterclass',
                  time: '2:00 PM - 3:30 PM',
                  students: '12 Students',
                  color: AppPalette.navyPrimary,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2),

                const SizedBox(height: 12),

                const _SessionCard(
                  title: 'Fielding Practice',
                  time: '4:00 PM - 5:00 PM',
                  students: '10 Students',
                  color: AppPalette.success,
                ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2),

                const SizedBox(height: 32),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.textPrimaryLight,
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/coach/create-session');
                        },
                        child: const _ActionCard(
                          icon: Icons.add_circle_outline,
                          label: 'New Session',
                          color: AppPalette.orangeAccent,
                        ).animate().fadeIn(delay: 800.ms).scale(delay: 800.ms),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/coach/students');
                        },
                        child: const _ActionCard(
                          icon: Icons.people_outline,
                          label: 'Students',
                          color: AppPalette.navyPrimary,
                        ).animate().fadeIn(delay: 900.ms).scale(delay: 900.ms),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100), // Bottom nav spacing
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String time;
  final String students;
  final Color color;

  const _SessionCard({
    required this.title,
    required this.time,
    required this.students,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () => context.push('/session-details/1'),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: AppPalette.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppPalette.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: AppPalette.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            students,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppPalette.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppPalette.navyPrimary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
