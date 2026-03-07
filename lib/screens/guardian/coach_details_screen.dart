import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../services/search_service.dart';
import '../../widgets/navigation/role_based_bottom_nav_bar.dart';
import '../../services/review_service.dart';
import '../../utils/date_time_utils.dart';
import '../../services/profile_service.dart';
import '../../utils/currency_helper.dart';

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

  List<dynamic> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetails();
    _fetchReviews();
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
        _fetchSessions(); // Fetch sessions after getting coach details
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

  Future<void> _fetchReviews() async {
    try {
      final data = await ReviewService.getCoachReviews(widget.coachId);
      if (mounted) {
        setState(() {
          _reviews = data['data'] ?? [];
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  List<dynamic> _sessions = [];
  bool _isLoadingSessions = true;

  Future<void> _fetchSessions() async {
    if (_coach == null) return;

    try {
      final userObj = _coach!['userId'];
      final userId = userObj is Map ? userObj['_id'] : userObj;

      if (userId == null) {
        setState(() => _isLoadingSessions = false);
        return;
      }

      final data = await _searchService.searchSessions(coachId: userId);
      if (mounted) {
        setState(() {
          _sessions = data['data'] ?? [];
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
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
    final userMap =
        userObj is Map<String, dynamic> ? userObj : <String, dynamic>{};

    final fullName =
        userMap['fullName'] ?? profile['fullName'] ?? 'Unknown Coach';
    final profilePhoto = userMap['profilePhoto'] ??
        profile['profilePhoto'] ??
        profile['profileImage'] ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=random';

    final specializationsList =
        profile['specializations'] ?? profile['specialties'] ?? [];
    final specializations = specializationsList is List
        ? specializationsList.join(', ')
        : specializationsList.toString();
    final bio = profile['bio'] ?? profile['aboutMe'] ?? 'No bio available.';
    final coachingPhilosophy = profile['coachingPhilosophy'] as String?;
    final notableAchievements =
        (profile['notableAchievements'] as List?)?.cast<String>() ?? [];
    final city = profile['city'] as String?;
    final ageGroups =
        (profile['ageGroupsCoached'] as List?)?.cast<String>() ?? [];
    final sessionTypes =
        (profile['sessionTypesOffered'] as List?)?.cast<String>() ?? [];
    final certifications =
        (profile['certifications'] as List?)?.cast<String>() ?? [];

    // Handle rating mismatch (backend has 'rating', frontend expected 'ratings.overall')
    final rawRating =
        profile['ratings']?['overall'] ?? profile['rating'] ?? 0.0;
    final rating =
        (rawRating as num).toDouble().toStringAsFixed(1); // Simplify display

    final experience =
        '${profile['experienceYears'] ?? profile['experience'] ?? 0} Yrs';
    final hourlyRate = profile['defaultPricing']?['hourlyRate']?.toString() ??
        profile['pricing']?['hourlyRate']?.toString() ??
        'TBD';
    final sessionDuration =
        (profile['defaultPricing']?['sessionDuration'] as num?)?.toInt() ?? 60;
    // Detect currency from coach's profile: saved currency > country > city
    final savedCurrency = (profile['defaultPricing']?['currency'] as String?) ??
        (profile['currency'] as String?);
    final coachLocation = (profile['country'] as String?) ?? city;
    final currencyCode = (savedCurrency != null && savedCurrency.isNotEmpty)
        ? savedCurrency
        : CurrencyHelper.getCurrencyFromLocation(coachLocation);
    final currencySymbol = CurrencyHelper.getCurrencySymbol(currencyCode);
    final sessionPrice = hourlyRate == 'TBD'
        ? 'TBD'
        : '$currencySymbol${((double.tryParse(hourlyRate) ?? 0) * (sessionDuration / 60.0)).toStringAsFixed(0)}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const RoleBasedBottomNavBar(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          fullName,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
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
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
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
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
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
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).cardColor,
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
                      labelColor: Theme.of(context).colorScheme.onSurface,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      indicatorColor: Theme.of(context).colorScheme.primary,
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
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bio,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (city != null) ...[
                                  _buildSectionTitle('Location'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        city,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (coachingPhilosophy != null &&
                                    coachingPhilosophy.isNotEmpty) ...[
                                  _buildSectionTitle('Coaching Philosophy'),
                                  const SizedBox(height: 8),
                                  Text(
                                    coachingPhilosophy,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (notableAchievements.isNotEmpty) ...[
                                  _buildSectionTitle('Notable Achievements'),
                                  const SizedBox(height: 12),
                                  ...notableAchievements.map(
                                    (e) => _buildBulletPoint(e),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (certifications.isNotEmpty) ...[
                                  _buildSectionTitle('Certifications'),
                                  const SizedBox(height: 12),
                                  ...certifications.map(
                                    (e) => _buildBulletPoint(e),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (ageGroups.isNotEmpty) ...[
                                  _buildSectionTitle('Age Groups Coached'),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: ageGroups
                                        .map((e) => _buildChip(e))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (sessionTypes.isNotEmpty) ...[
                                  _buildSectionTitle('Session Types'),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: sessionTypes
                                        .map((e) => _buildChip(e))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ],
                            ),
                          ),

                          // REVIEWS TAB
                          _isLoadingReviews
                              ? const Center(child: CircularProgressIndicator())
                              : _reviews.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.rate_review_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "No reviews yet",
                                            style: GoogleFonts.inter(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: _reviews.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final review = _reviews[index];
                                        final player = review['player'] ?? {};
                                        final playerName =
                                            player['fullName'] ?? 'Anonymous';
                                        final playerImage =
                                            player['profilePhoto'] ??
                                                'https://i.pravatar.cc/150';
                                        final rating = (review['rating'] as num)
                                            .toDouble();
                                        final comment = review['comment'] ?? '';
                                        final date = DateTime.parse(
                                          review['createdAt'],
                                        ).toLocal();

                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context).dividerColor,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 20,
                                                    backgroundImage:
                                                        NetworkImage(
                                                      playerImage,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          playerName,
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                        ),
                                                        Text(
                                                          DateTimeUtils
                                                              .formatDate(
                                                            date,
                                                          ),
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.star,
                                                          size: 14,
                                                          color: Colors.amber,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          rating.toString(),
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                            color: Colors
                                                                .amber[800],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (comment.isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  comment,
                                                  style: GoogleFonts.inter(
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                    height: 1.5,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                          // SCHEDULE TAB (Placeholder)
                          // SCHEDULE TAB
                          _isLoadingSessions
                              ? const Center(child: CircularProgressIndicator())
                              : _sessions.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "No upcoming sessions",
                                            style: GoogleFonts.inter(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: _sessions.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final session = _sessions[index];
                                        final title =
                                            session['title'] ?? 'Session';
                                        final timeSlots =
                                            session['timeSlots'] as List?;
                                        final firstSlot =
                                            timeSlots?.isNotEmpty == true
                                                ? timeSlots!.first
                                                : null;
                                        final startTime = firstSlot != null
                                            ? DateTime.parse(
                                                firstSlot['startTime'],
                                              ).toLocal()
                                            : null;
                                        final price =
                                            session['pricing']?['amount'] ?? 0;

                                        return InkWell(
                                          onTap: () {
                                            final dateParam = startTime != null
                                                ? '?date=${startTime.toIso8601String()}'
                                                : '';
                                            final isGuardian =
                                                GoRouterState.of(context)
                                                    .uri
                                                    .toString()
                                                    .startsWith('/guardian');
                                            context.push(
                                              isGuardian
                                                  ? '/guardian/session-details/${session['_id']}$dateParam'
                                                  : '/session-details/${session['_id']}$dateParam',
                                            );
                                          },
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                16,
                                              ),
                                              border: Border.all(
                                                color: Theme.of(context).dividerColor,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.sports_cricket,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        title,
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      if (startTime != null)
                                                        Text(
                                                          '${DateTimeUtils.formatDate(startTime)} • ${DateTimeUtils.formatTimeFromDateTime(startTime)}',
                                                          style:
                                                              GoogleFonts.inter(
                                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '\$$price',
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color:
                                                        AppPalette.orangeAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
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
              color: Theme.of(context).cardColor,
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
                      'SESSION RATE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      sessionPrice == 'TBD'
                          ? 'TBD'
                          : '$sessionPrice / ${sessionDuration}min',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final ScaffoldMessengerState messenger =
                          ScaffoldMessenger.of(context);
                      final dynamic localRouter = GoRouter.of(context);
                      final Uri currentRouteUri = GoRouterState.of(context).uri;

                      final isComplete =
                          await ProfileService.isProfileComplete();
                      if (!mounted) return;
                      if (!isComplete) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please complete your profile (Location and Phone Number) before booking.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      double rate = 60.0;
                      if (hourlyRate != 'TBD') {
                        rate = double.tryParse(hourlyRate.toString()) ?? 60.0;
                      }

                      final int sessionDuration =
                          profile['defaultPricing']?['sessionDuration'] ?? 60;
                      final String cancellationPolicy =
                          profile['bookingSettings']?['cancellationPolicy'] ??
                              'flexible';

                      final isGuardian =
                          currentRouteUri.toString().startsWith('/guardian');

                      if (isGuardian) {
                        localRouter.push(
                          '/guardian/coach/${widget.coachId}/book',
                          extra: <String, dynamic>{
                            'coachName': fullName,
                            'coachImageUrl': profilePhoto,
                            'hourlyRate': rate,
                            'sessionDuration': sessionDuration,
                            'cancellationPolicy': cancellationPolicy,
                            'currencySymbol': currencySymbol,
                          },
                        );
                      } else {
                        localRouter.push(
                          '/coach/${widget.coachId}/book',
                          extra: <String, dynamic>{
                            'coachName': fullName,
                            'coachImageUrl': profilePhoto,
                            'hourlyRate': rate,
                            'sessionDuration': sessionDuration,
                            'cancellationPolicy': cancellationPolicy,
                            'currencySymbol': currencySymbol,
                          },
                        );
                      }
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
                          'Book Private Session',
                          style: GoogleFonts.inter(
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
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
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
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
    return Container(height: 30, width: 1, color: Theme.of(context).dividerColor);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
