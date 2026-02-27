import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/palette.dart';
import '../../services/guardian_service.dart';
import '../../services/session_service.dart';
import '../../utils/date_time_utils.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final String playerId;
  final bool isCoachView;

  const PlayerDetailsScreen({
    super.key,
    required this.playerId,
    this.isCoachView = false,
  });

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _guardianService = GuardianService();

  bool _isLoading = true;
  bool _isLoadingReports = true;
  String? _error;

  Map<String, dynamic>? _playerData;
  List<dynamic> _sessionReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchPlayerDetails(),
      _fetchSessionReports(),
    ]);
  }

  Future<void> _fetchPlayerDetails() async {
    try {
      final data = await _guardianService.getPlayerDetails(widget.playerId);
      if (mounted) {
        setState(() {
          _playerData = data;
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

  Future<void> _fetchSessionReports() async {
    try {
      final reports =
          await SessionService.getPlayerSessionReports(widget.playerId);
      if (mounted) {
        setState(() {
          _sessionReports = reports;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReports = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _playerData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        ),
        body: Center(child: Text('Error: ${_error ?? "Player not found"}')),
      );
    }

    final player = _playerData!;
    final String fullName = player['fullName'] ?? 'Unknown';
    final String role = player['role'] ?? 'Athlete';
    final String age = player['age']?.toString() ?? 'N/A';
    final String? profilePhoto = player['profilePhoto'] ?? player['profileUrl'];
    final stats = player['stats'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF0D1B2A) : AppPalette.navyPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!widget.isCoachView)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () async {
                    await context.push('/guardian/edit-player',
                        extra: _playerData);
                    _fetchPlayerDetails();
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(
                  context, fullName, role, age, profilePhoto, stats),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color:
                    isDark ? const Color(0xFF0D1B2A) : AppPalette.navyPrimary,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppPalette.orangeAccent,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Reports'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, player, stats),
            _buildReportsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    String fullName,
    String role,
    String age,
    String? profilePhoto,
    Map<String, dynamic>? stats,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.navyPrimary,
            AppPalette.navyPrimary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.orangeAccent, width: 3),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      (profilePhoto != null && profilePhoto.isNotEmpty)
                          ? NetworkImage(profilePhoto)
                          : null,
                  child: (profilePhoto == null || profilePhoto.isEmpty)
                      ? const Icon(Icons.person,
                          color: Colors.white70, size: 48)
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age $age  •  $role',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildHeaderChip(
                            '${stats?['totalSessions'] ?? stats?['sessions'] ?? 0} Sessions'),
                        const SizedBox(width: 8),
                        _buildHeaderChip(
                          () {
                            final r = stats?['avgRating'] ?? stats?['rating'];
                            final rv = r != null && r != 0 && r != 0.0
                                ? '⭐ ${_formatAvgRating(r)}'
                                : 'No Rating Yet';
                            return rv;
                          }(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAvgRating(dynamic rating, {bool naIfNull = false}) {
    if (rating == null || rating == 0 || rating == 0.0) {
      return naIfNull ? 'N/A' : '0.0';
    }
    if (rating is num) return rating.toStringAsFixed(1);
    final d = double.tryParse(rating.toString());
    if (d == null || d == 0) return naIfNull ? 'N/A' : '0.0';
    return d.toStringAsFixed(1);
  }

  Widget _buildHeaderChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────── Overview Tab
  Widget _buildOverviewTab(
    BuildContext context,
    Map<String, dynamic> player,
    Map<String, dynamic>? stats,
  ) {
    final batting = _playerData?['battingStyle'] ?? 'N/A';
    final bowling = _playerData?['bowlingStyle'] ?? 'N/A';
    final medical = _playerData?['medicalIssues'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Rating Breakdown ══════════════════════════════════════════════
        _buildSectionLabel('Performance Summary'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sessions',
                (stats?['totalSessions'] ?? stats?['sessions'] ?? 0).toString(),
                Icons.sports_cricket_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Rating',
                _formatAvgRating(stats?['avgRating'] ?? stats?['rating']),
                Icons.star_rounded,
                Colors.amber,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Technical',
                _formatAvgRating(stats?['avgTechnical'] ??
                    stats?['avgBatting'] ??
                    stats?['batting']),
                Icons.emoji_objects_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Physical',
                _formatAvgRating(stats?['avgPhysical'] ??
                    stats?['avgBowling'] ??
                    stats?['bowling']),
                Icons.fitness_center_rounded,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Mental',
                _formatAvgRating(stats?['avgMental'] ??
                    stats?['avgFielding'] ??
                    stats?['fielding']),
                Icons.psychology_rounded,
                Colors.teal,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 28),

        // ── Player Details ════════════════════════════════════════════════
        _buildSectionLabel('Player Details'),
        const SizedBox(height: 12),
        _buildDetailCard(context, [
          _DetailRow(
              icon: Icons.sports_cricket,
              label: 'Batting Style',
              value: batting),
          _DetailRow(
              icon: Icons.cyclone_rounded,
              label: 'Bowling Style',
              value: bowling),
          if (medical != null && medical.toString().isNotEmpty)
            _DetailRow(
                icon: Icons.medical_services_outlined,
                label: 'Medical Notes',
                value: medical.toString()),
        ]).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 28),

        // ── Recent Reports Preview ════════════════════════════════════════
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Recent Reports'),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text(
                'See all',
                style: GoogleFonts.inter(
                  color: AppPalette.orangeAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingReports)
          const Center(child: CircularProgressIndicator())
        else if (_sessionReports.isEmpty)
          _buildEmptyState('No reports yet', Icons.description_outlined)
        else
          ..._sessionReports
              .take(2)
              .map((r) => _buildReportCard(context, r, preview: true)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────── Reports Tab
  Widget _buildReportsTab(BuildContext context) {
    if (_isLoadingReports) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessionReports.isEmpty) {
      return Center(
        child: _buildEmptyState(
            'No session reports yet', Icons.description_outlined),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _sessionReports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _buildReportCard(context, _sessionReports[i]),
    );
  }

  Widget _buildReportCard(BuildContext context, dynamic report,
      {bool preview = false}) {
    final Map<String, dynamic> r = Map<String, dynamic>.from(report as Map);

    // Backend returns a flat structure: sessionTitle, sessionDate, coach:{fullName..}, batting, bowling, fielding, notes, overall
    final coach = r['coach'] as Map<String, dynamic>?;
    final String sessionTitle = r['sessionTitle']?.toString() ??
        (r['session'] as Map<String, dynamic>?)?['title']?.toString() ??
        'Session';
    final String coachName = coach?['fullName']?.toString() ?? 'Coach';
    final String dateStr = r['sessionDate']?.toString() ??
        r['date']?.toString() ??
        (r['session'] as Map<String, dynamic>?)?['date']?.toString() ??
        '';
    final String notes = r['notes']?.toString() ??
        r['coachNotes']?.toString() ??
        r['primaryFocus']?.toString() ??
        '';
    final double batting =
        _toDouble(r['batting'] ?? r['technicalRating'] ?? r['battingRating']);
    final double bowling =
        _toDouble(r['bowling'] ?? r['physicalRating'] ?? r['bowlingRating']);
    final double fielding =
        _toDouble(r['fielding'] ?? r['mentalRating'] ?? r['fieldingRating']);
    final double overall = _toDouble(r['overall'] ?? r['overallRating']);
    final String formattedDate = dateStr.isNotEmpty
        ? DateTimeUtils.formatDate(DateTime.tryParse(dateStr) ?? DateTime.now())
        : 'Unknown Date';

    return Container(
      margin: EdgeInsets.only(bottom: preview ? 8 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.orangeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppPalette.orangeAccent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionTitle,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Text(
                      'by $coachName  •  $formattedDate',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              if (overall > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        overall.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!preview) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (batting > 0)
                  Expanded(
                      child: _buildSkillRating(
                          'Technical', batting, Colors.green)),
                if (bowling > 0)
                  Expanded(
                      child: _buildSkillRating(
                          'Physical', bowling, Colors.purple)),
                if (fielding > 0)
                  Expanded(
                      child:
                          _buildSkillRating('Mental', fielding, Colors.teal)),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        color: AppPalette.orangeAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.75),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 50.ms * _sessionReports.indexOf(report).clamp(0, 10));
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Widget _buildSkillRating(String label, double value, Color color) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1),
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────── Shared helpers
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55))),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, List<_DetailRow> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppPalette.navyPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(row.icon, color: AppPalette.navyPrimary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.label,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5))),
                        Text(row.value,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
              if (i < rows.length - 1) ...[
                const SizedBox(height: 12),
                Divider(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.4),
                    height: 1),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.inter(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
                fontSize: 14,
              )),
        ],
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
}
