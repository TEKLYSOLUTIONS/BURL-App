import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class CoachProfileScreen extends StatefulWidget {
  final String coachId; // Placeholder for future fetching

  const CoachProfileScreen({super.key, required this.coachId});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background as per design
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppPalette.navyPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Coach Details', // Or Coach Name
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: AppPalette.navyPrimary,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(
                                  'https://i.pravatar.cc/150?img=5',
                                ), // Mock Image
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.green, // Verified Green
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().scale(),

                          const SizedBox(height: 16),

                          // Name & Title
                          Text(
                            'Sarah Jenkins',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.navyPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'High Performance Cricket Coach',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppPalette.textSecondaryLight,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBadge(
                                Icons.shield_outlined,
                                'BCCI Level 2',
                              ),
                              const SizedBox(width: 12),
                              _buildBadge(Icons.school_outlined, 'Certified'),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Stats Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem('4.9', 'RATING', true),
                                _buildVerticalDivider(),
                                _buildStatItem('8 Yrs', 'EXPERIENCE', false),
                                _buildVerticalDivider(),
                                _buildStatItem('500+', 'PLAYERS', false),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppPalette.navyPrimary,
                    unselectedLabelColor: AppPalette.textDisabled,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    indicatorColor: AppPalette.navyPrimary,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'Schedule'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(),
                        const Center(child: Text('Reviews Coming Soon')),
                        const Center(child: Text('Schedule Coming Soon')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar (Price + Action)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL PRICE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textSecondaryLight,
                        letterSpacing: 1,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '\$60',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.navyPrimary,
                            ),
                          ),
                          TextSpan(
                            text: ' /hr',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppPalette.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: const Text('Book Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.navyPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPalette.navyPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Former D1 athlete specializing in serve mechanics and agility training. I help intermediate players break through plateaus by focusing on the mental game and biomechanics.',
            style: GoogleFonts.inter(
              color: AppPalette.textSecondaryLight,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Specialties',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPalette.navyPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSpecialtyChip(Icons.sports_cricket, 'Technical Analysis'),
              _buildSpecialtyChip(Icons.directions_run, 'Agility & Footwork'),
              _buildSpecialtyChip(Icons.fitness_center, 'Strength Training'),
              _buildSpecialtyChip(Icons.psychology, 'Mental Game'),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Training Gallery',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              TextTextButton(
                onPressed: () {},
                child: Text(
                  'See All',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildGalleryItem(
                  'https://images.unsplash.com/photo-1531415074968-bc236357463d?auto=format&fit=crop&q=80&w=300',
                ),
                const SizedBox(width: 12),
                _buildGalleryItem(
                  'https://images.unsplash.com/photo-1624880357913-a8539238245b?auto=format&fit=crop&q=80&w=300',
                ),
                const SizedBox(width: 12),
                _buildGalleryItem(
                  'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&q=80&w=300',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Location',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPalette.navyPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=1000',
                ), // Map Placeholder
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: AppPalette.navyPrimary,
                    size: 40,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Golden Gate Courts',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '2.4 miles away',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80), // Bottom padding for FAB if needed
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.navyPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppPalette.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isStar) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            if (isStar) ...[
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 16, color: Colors.amber),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }

  Widget _buildSpecialtyChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppPalette.orangeAccent,
          ), // Styled icon color
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppPalette.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(String imageUrl) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Helper for Text Button
class TextTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const TextTextButton({
    super.key,
    required this.onPressed,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
  }
}
