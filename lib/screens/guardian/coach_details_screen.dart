import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/search_service.dart';

class CoachDetailsScreen extends StatefulWidget {
  final String coachId;

  const CoachDetailsScreen({super.key, required this.coachId});

  @override
  State<CoachDetailsScreen> createState() => _CoachDetailsScreenState();
}

class _CoachDetailsScreenState extends State<CoachDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchService = SearchService();

  Map<String, dynamic>? _coach;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await _searchService.getCoachDetails(widget.coachId);
      debugPrint('Fetched Coach Details: $data');
      if (mounted) {
        setState(() {
          _coach = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _coach == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Error: ${_error ?? "Coach not found"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _coach!;

    // Safely handle user object/populated field
    final userObj = profile['userId'];
    final userMap = userObj is Map<String, dynamic>
        ? userObj
        : <String, dynamic>{};

    final fullName = userMap['fullName'] ?? 'Unknown Coach';
    final profilePhoto =
        userMap['profilePhoto'] ??
        'https://i.pravatar.cc/150?u=${widget.coachId}';
    final specializations =
        (profile['specializations'] as List?)?.join(', ') ?? 'Coach';
    final bio = profile['bio'] ?? profile['aboutMe'] ?? 'No bio available.';

    // Handle rating mismatch (backend has 'rating', frontend expected 'ratings.overall')
    final rawRating = profile['rating'] ?? profile['ratings']?['overall'] ?? 0;
    final rating = rawRating.toString(); // Simplify display

    final reviewCount = profile['ratings']?['count']?.toString() ?? '0';
    final experience =
        '${profile['experienceYears'] ?? profile['experience'] ?? 0} Yrs';
    final hourlyRate =
        profile['defaultPricing']?['hourlyRate']?.toString() ??
        profile['pricing']?['hourlyRate']?.toString() ??
        'TBD';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Light background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: Colors.black,
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          fullName,
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                color: Colors.orange,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Image
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(profilePhoto),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 16),

                  // Name & Title
                  Text(
                    fullName,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 4),

                  Text(
                    specializations,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B4EFF), // Purple nuance
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                  const SizedBox(height: 12),

                  // Badges (Static for now, can be dynamic later)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(Icons.verified_user, 'Verified'),
                      const SizedBox(width: 12),
                      _buildBadge(Icons.school, 'Certified'),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Stats Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(rating, 'RATING', isStar: true),
                        _buildDivider(),
                        _buildStat(experience, 'EXPERIENCE'),
                        _buildDivider(),
                        _buildStat('50+', 'PLAYERS'), // Placeholder
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppPalette.navyPrimary,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      indicatorColor: AppPalette.navyPrimary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3,
                      padding: EdgeInsets.zero,
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'Reviews'),
                        Tab(
                          text: 'Schedule',
                        ), // Could integrate calendar preview here
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      height:
                          400, // Fixed height for tab view content inside scroll view
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // ABOUT TAB
                          SingleChildScrollView(
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
                                const SizedBox(height: 12),
                                Text(
                                  bio,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Training Gallery',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.navyPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 120,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _buildGalleryItem(
                                        'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff',
                                      ),
                                      _buildGalleryItem(
                                        'https://i.pravatar.cc/300?img=25',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),

                          // REVIEWS TAB (Placeholder)
                          Center(
                            child: Text("Reviews coming soon ($reviewCount)"),
                          ),

                          // SCHEDULE TAB (Placeholder)
                          const Center(
                            child: Text("Schedule preview unavailable"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Bar
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
                      'HOURLY RATE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 1,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$$hourlyRate',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        Text(
                          ' /hr',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to booking screen, passing sessionId if known, or just coach info?
                      // The current route expects :sessionId.
                      // We might need a generic booking route or create a session first.
                      // For now, let's navigate to a generic booking creation flow or show a dialog.
                      // Simulating navigating to a session selection for this coach
                      // context.push('/booking/new?coachId=${widget.coachId}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Booking flow for specific coach to be implemented',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Book Session',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 1.0, duration: 400.ms),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.navyPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppPalette.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, {bool isStar = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildGalleryItem(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
