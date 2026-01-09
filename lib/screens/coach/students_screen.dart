import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _selectedFilter = 'All Students';

  // Mock Data with distinct status for filtering
  final List<Map<String, dynamic>> _allStudents = [
    {
      'name': 'Alex Rivera',
      'detail': 'Tennis • Forward',
      'avatarUrl': 'https://i.pravatar.cc/150?img=11',
      'status': 'Active',
      'statusLabel': 'ON TRACK',
      'statusColor': Colors.green[50]!,
      'statusTextColor': Colors.green[700]!,
      'showOnlineDot': true,
      'onlineDotColor': Colors.green,
    },
    {
      'name': 'Sarah Chen',
      'detail': 'Swimming • 100m Free',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
      'status': 'Injured',
      'statusLabel': 'INJURED',
      'statusColor': Colors.red[50]!,
      'statusTextColor': Colors.red[700]!,
      'showOnlineDot': true,
      'onlineDotColor': Colors.red,
      'actionIcon': Icons.local_hospital_outlined,
    },
    {
      'name': 'Michael Johnson',
      'detail': 'Track • Sprinter',
      'avatarUrl': 'https://i.pravatar.cc/150?img=8',
      'status': 'Needs Review',
      'statusLabel': 'NEEDS REVIEW',
      'statusColor': Colors.orange[50]!,
      'statusTextColor': Colors.orange[800]!,
      'actionIcon': Icons.priority_high,
      'isActionAlert': true,
    },
    {
      'name': 'Emily Davis',
      'detail': 'Volleyball • Libero',
      'avatarUrl': 'https://i.pravatar.cc/150?img=9',
      'status': 'Active',
      'statusLabel': 'ON TRACK',
      'statusColor': Colors.green[50]!,
      'statusTextColor': Colors.green[700]!,
      'actionIcon': Icons.add,
      'isFab': true,
    },
  ];

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
      body: SingleChildScrollView(
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
                    value: '24',
                    subtitle: '+2 This Month',
                    isDark: true,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'ACTIVE',
                    value: '18',
                    subtitle: '↗ 92% Attd.',
                    subtitleColor: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'INJURED',
                    value: '3',
                    subtitle: '⚠ Needs Review',
                    subtitleColor: Colors.red,
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
                    'Injured',
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
                  actionIcon: student['actionIcon'],
                  isActionAlert: student['isActionAlert'] ?? false,
                  isFab: student['isFab'] ?? false,
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
    IconData? actionIcon,
    bool isActionAlert = false,
    bool isFab = false,
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
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.chat_bubble, color: Colors.grey[300]),
                ),
                if (isFab)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(actionIcon, color: Colors.white),
                  )
                else if (isActionAlert)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(actionIcon, color: Colors.orange),
                  )
                else
                  Icon(
                    actionIcon ?? Icons.bar_chart_rounded,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
