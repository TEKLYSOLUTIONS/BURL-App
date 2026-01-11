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
        child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(30),
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
                  autofocus: false,
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

              // Recommended Coaches Section
              Text(
                'Recommended Coaches',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CoachCard(
                      name: 'Rahul Dravid',
                      role: 'Batting Coach',
                      rating: '4.9',
                      imageUrl: 'https://i.pravatar.cc/150?u=coach1',
                      onTap: () => context.push('/coach-details/1'),
                    ),
                    const SizedBox(width: 16),
                    _CoachCard(
                      name: 'Zaheer Khan',
                      role: 'Bowling Coach',
                      rating: '4.8',
                      imageUrl: 'https://i.pravatar.cc/150?u=coach2',
                      onTap: () => context.push('/coach-details/2'),
                    ),
                    const SizedBox(width: 16),
                    _CoachCard(
                      name: 'Jonty Rhodes',
                      role: 'Fielding Coach',
                      rating: '5.0',
                      imageUrl: 'https://i.pravatar.cc/150?u=coach3',
                      onTap: () => context.push('/coach-details/3'),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(),

              const SizedBox(height: 32),

              // Sessions Section
              Text(
                'Sessions',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 16),

              // Session List
              Column(
                children: [
                  _SearchResultItem(
                    title: 'Bowling Masterclass',
                    subtitle: 'Tomorrow • 10:00 AM',
                    icon: Icons.sports_cricket,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _SearchResultItem(
                    title: 'Advanced Batting',
                    subtitle: 'Friday • 4:00 PM',
                    icon: Icons.sports_cricket,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _SearchResultItem(
                    title: 'Wicket Keeping Drills',
                    subtitle: 'Saturday • 9:00 AM',
                    icon: Icons.sports_handball,
                    onTap: () {},
                  ),
                ].animate(interval: 100.ms).fadeIn().slideX(begin: 0.1),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final String name;
  final String role;
  final String rating;
  final String imageUrl;
  final VoidCallback onTap;

  const _CoachCard({
    required this.name,
    required this.role,
    required this.rating,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: AppPalette.navyPrimary.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppPalette.navyPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              role,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            Expanded(
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }
}
