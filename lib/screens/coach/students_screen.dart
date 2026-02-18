import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/coach_service.dart';
import '../../config/palette.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _selectedFilter = 'All Students';
  bool _isLoading = true;

  // API Data
  List<Map<String, dynamic>> _allStudents = [];
  int _totalCount = 0;
  int _activeCount = 0;
  int _needsReviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);

    try {
      final data = await CoachService.getCoachPlayers();
      final players = data['players'] as List? ?? [];
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      setState(() {
        _allStudents = players.map((player) {
          // Map status from backend to display status
          String displayStatus = 'Active';
          String statusLabel = 'CONFIRMED';
          String rawStatus = player['status'] ?? 'confirmed';

          if (rawStatus == 'invited') {
            displayStatus = 'Needs Review';
            statusLabel = 'INVITED';
          } else if (rawStatus == 'confirmed') {
            displayStatus = 'Active';
            statusLabel = 'CONFIRMED';
          } else if (rawStatus == 'declined') {
            displayStatus = 'Declined';
            statusLabel = 'DECLINED';
          } else if (rawStatus == 'waitlisted') {
            displayStatus = 'Waitlisted';
            statusLabel = 'WAITLISTED';
          }

          return {
            'id': player['_id'],
            'name': player['name'] ?? 'Unknown',
            'detail': '${player['sessionsCount'] ?? 0} sessions',
            'avatarUrl': player['avatarUrl'] ?? 'https://i.pravatar.cc/150',
            'status': displayStatus, // For filter
            'rawStatus': rawStatus, // For color logic
            'statusLabel': statusLabel, // For badge text
            'showOnlineDot': rawStatus == 'confirmed',
            'onlineDotColor': AppPalette.successGreen,
          };
        }).toList();

        _totalCount = stats['total'] ?? 0;
        _activeCount = stats['active'] ?? 0;
        _needsReviewCount = stats['needsReview'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load players: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_selectedFilter == 'All Students') return _allStudents;
    return _allStudents.where((s) => s['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Light grey background
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'My Players',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                10,
                24,
                100,
              ), // Added bottom padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSummaryCard(
                          title: 'TOTAL',
                          value: _totalCount.toString(),
                          subtitle: '${_allStudents.length} Players',
                          isDark: true,
                        ),
                        const SizedBox(width: 12),
                        _buildSummaryCard(
                          title: 'ACTIVE',
                          value: _activeCount.toString(),
                          subtitle: 'Confirmed',
                          subtitleColor: AppPalette.successGreen,
                        ),
                        const SizedBox(width: 12),
                        _buildSummaryCard(
                          title: 'PENDING',
                          value: _needsReviewCount.toString(),
                          subtitle: 'Needs Review',
                          subtitleColor: AppPalette.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Students'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Declined',
                          hasDot: true,
                          dotColor: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Needs Review',
                          hasDot: true,
                          dotColor: AppPalette.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student List (Filtered)
                  if (_filteredStudents.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No players found',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._filteredStudents.map((student) {
                      final colors = _getStatusColors(
                        student['rawStatus'] ?? 'confirmed',
                        context,
                      );
                      return _buildStudentCard(
                        name: student['name'],
                        detail: student['detail'],
                        avatarUrl: student['avatarUrl'],
                        status: student['statusLabel'],
                        statusColor: colors.background,
                        statusTextColor: colors.text,
                        showOnlineDot: student['showOnlineDot'] ?? false,
                        onlineDotColor:
                            student['onlineDotColor'] ??
                            AppPalette.successGreen,
                      );
                    }),
                ],
              ),
            ),
    );
  }

  ({Color background, Color text}) _getStatusColors(
    String status,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case 'invited': // Needs Review
        return (
          background: isDark
              ? AppPalette.warning.withValues(alpha: 0.2)
              : AppPalette.warning.withValues(alpha: 0.1),
          text: isDark ? AppPalette.warning : AppPalette.warning,
        );
      case 'declined':
        return (
          background: isDark
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
          text: isDark
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.error,
        );
      case 'waitlisted':
        return (
          background: isDark
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.blue[50]!,
          text: isDark ? Colors.blue[200]! : Colors.blue[700]!,
        );
      case 'confirmed':
      default:
        return (
          background: isDark
              ? AppPalette.successGreen.withValues(alpha: 0.2)
              : AppPalette.successGreen.withValues(alpha: 0.1),
          text: isDark ? AppPalette.successGreen : AppPalette.successGreen,
        );
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    bool isDark = false,
    Color? subtitleColor,
  }) {
    return Container(
      width: 140, // Fixed width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: isDark
                    ? Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.7)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isDark
                      ? Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.7)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    subtitleColor ??
                    (isDark
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    bool hasDot = false,
    Color? dotColor,
  }) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            if (hasDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String detail,
    required String avatarUrl,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    bool showOnlineDot = false,
    Color onlineDotColor = AppPalette.successGreen,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to player details (using placeholder or existing route)
        // Since we don't have a specific coach view for player details,
        // we'll use a placeholder action or route.
        // Assuming we route to a details page:
        context.push(
          '/guardian/player-details/1?isCoach=true',
        ); // Using dummy ID for now
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                if (showOnlineDot)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: onlineDotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    detail,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
