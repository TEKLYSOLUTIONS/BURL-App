import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';

class PlayerHomeScreen extends StatelessWidget {
  const PlayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight, // Pearl White / Off-white
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppPalette.textSecondaryLight,
                        ),
                      ),
                      Text(
                        'Akshar Patel',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  NotificationButton(
                    hasNotification: false,
                    onTap: () => context.push('/player/notifications'),
                    iconColor: AppPalette.navyPrimary,
                    backgroundColor: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 24),

              // 2. Search Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Find a coach or venue...',
                    hintStyle: GoogleFonts.inter(
                      color: AppPalette.textDisabled,
                      fontSize: 14,
                    ),
                    icon: const Icon(
                      Icons.search,
                      color: AppPalette.textDisabled,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // View All Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppPalette.orangeAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              // 3. Featured Session Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppPalette.orangeAccent.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_cricket,
                            color: AppPalette.orangeAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Batting Technique',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'with Coach Rahul Dravid',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.orangeAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Today',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppPalette.divider, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppPalette.textSecondaryLight,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '4:00 PM - 5:00 PM',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppPalette.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppPalette.textSecondaryLight,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lords Stadium',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppPalette.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Coaches',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  Text(
                    'See All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.orangeAccent,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              // 4. Coach List
              const _CoachCard(
                name: 'Coach Virat',
                specialty: 'Cricket • Batting Specialist',
                rating: 5.0,
                hourlyRate: 50,
                imageUrl: 'https://i.pravatar.cc/150?img=33',
              ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

              const SizedBox(height: 16),

              const _CoachCard(
                name: 'Coach Rohit',
                specialty: 'Cricket • Batting Specialist',
                rating: 4.8,
                hourlyRate: 45,
                imageUrl: 'https://i.pravatar.cc/150?img=12',
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),

              const SizedBox(height: 80), // Bottom padding for floating nav
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final String name;
  final String specialty;
  final double rating;
  final int hourlyRate;
  final String imageUrl;

  const _CoachCard({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.hourlyRate,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                Text(
                  specialty,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppPalette.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.star,
                  size: 16,
                  color: AppPalette.orangeAccent,
                ),
              ],
            ),
          ),
          // Price Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.offWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '\$$hourlyRate/hr',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
