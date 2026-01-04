import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Header
              Text(
                'Search',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn().slideX(begin: -0.1),

              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    30,
                  ), // Rounded as requested
                  border: Border.all(color: AppPalette.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search for coaches, venues...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppPalette.navyPrimary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              Text(
                'Suggested',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Mock Results
              Expanded(
                child: ListView(
                  children: [
                    _SearchResultItem(
                      title: 'Rahul Dravid',
                      subtitle: 'Batting Coach • Lords Stadium',
                      icon: Icons.person,
                      onTap: () => context.push('/coach-details/1'),
                    ),
                    const SizedBox(height: 12),
                    _SearchResultItem(
                      title: 'Lords Cricket Ground',
                      subtitle: 'Venue • London',
                      icon: Icons.stadium,
                      onTap: () {}, // Venue details in future
                    ),
                    const SizedBox(height: 12),
                    _SearchResultItem(
                      title: 'Bowling Masterclass',
                      subtitle: 'Session • Tomorrow',
                      icon: Icons.sports_cricket,
                      onTap: () {},
                    ),
                  ].animate(interval: 100.ms).fadeIn().slideX(begin: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.navyPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppPalette.navyPrimary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
