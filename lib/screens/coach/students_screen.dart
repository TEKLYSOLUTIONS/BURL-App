import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../../services/coach_service.dart';

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
          String status = 'Active';
          String statusLabel = 'CONFIRMED';
          Color statusColor = Colors.green[50]!;
          Color statusTextColor = Colors.green[700]!;
          
          if (player['status'] == 'invited') {
            status = 'Needs Review';
            statusLabel = 'INVITED';
            statusColor = Colors.orange[50]!;
            statusTextColor = Colors.orange[800]!;
          } else if (player['status'] == 'confirmed') {
            status = 'Active';
            statusLabel = 'CONFIRMED';
            statusColor = Colors.green[50]!;
            statusTextColor = Colors.green[700]!;
          } else if (player['status'] == 'declined') {
            status = 'Declined';
            statusLabel = 'DECLINED';
            statusColor = Colors.red[50]!;
            statusTextColor = Colors.red[700]!;
          } else if (player['status'] == 'waitlisted') {
            status = 'Waitlisted';
            statusLabel = 'WAITLISTED';
            statusColor = Colors.blue[50]!;
            statusTextColor = Colors.blue[700]!;
          }

          return {
            'id': player['_id'],
            'name': player['name'] ?? 'Unknown',
            'detail': '${player['sessionsCount'] ?? 0} sessions',
            'avatarUrl': player['avatarUrl'] ?? 'https://i.pravatar.cc/150',
            'status': status,
            'statusLabel': statusLabel,
            'statusColor': statusColor,
            'statusTextColor': statusTextColor,
            'showOnlineDot': player['status'] == 'confirmed',
            'onlineDotColor': Colors.green,
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
            backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Players',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppPalette.navyPrimary,
          ),
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
                    subtitleColor: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'PENDING',
                    value: _needsReviewCount.toString(),
                    subtitle: 'Needs Review',
                    subtitleColor: Colors.orange,
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
                    dotColor: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Needs Review',
                    hasDot: true,
                    dotColor: Colors.orange,
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
                return _buildStudentCard(
                  name: student['name'],
                  detail: student['detail'],
                  avatarUrl: student['avatarUrl'],
                  status: student['statusLabel'],
                  statusColor: student['statusColor'],
                  statusTextColor: student['statusTextColor'],
                  showOnlineDot: student['showOnlineDot'] ?? false,
                  onlineDotColor: student['onlineDotColor'] ?? Colors.green,
                );
              }),
          ],
        ),
      ),
    );
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
        color: isDark ? AppPalette.navyPrimary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: isDark ? Colors.white70 : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppPalette.navyPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
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
                    (isDark ? Colors.orangeAccent : Colors.grey[600]),
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
          color: isSelected ? AppPalette.navyPrimary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppPalette.navyPrimary : Colors.grey[200]!,
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
                color: isSelected ? Colors.white : AppPalette.navyPrimary,
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
    Color onlineDotColor = Colors.green,
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
                        border: Border.all(color: Colors.white, width: 2),
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
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  Text(
                    detail,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
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
                Icon(Icons.bar_chart_rounded, color: Colors.orange),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
