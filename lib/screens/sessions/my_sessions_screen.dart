import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Sessions',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppPalette.navyPrimary,
          unselectedLabelColor: AppPalette.textDisabled,
          indicatorColor: AppPalette.orangeAccent,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionList(isUpcoming: true),
          _buildSessionList(isUpcoming: false),
        ],
      ),
    );
  }

  Widget _buildSessionList({required bool isUpcoming}) {
    // Mock Data
    final sessions = isUpcoming
        ? [
            {
              'title': 'Advanced Batting',
              'coach': 'Rahul Dravid',
              'date': 'Aug 14, 10:00 AM',
              'status': 'Confirmed',
              'color': AppPalette.success,
            },
            {
              'title': 'Fitness Test',
              'coach': 'Physio Team',
              'date': 'Aug 16, 08:00 AM',
              'status': 'Pending',
              'color': AppPalette.warning,
            },
          ]
        : [
            {
              'title': 'Bowling Basics',
              'coach': 'Zaheer Khan',
              'date': 'Aug 10, 04:00 PM',
              'status': 'Completed',
              'color': AppPalette.textDisabled,
            },
          ];

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppPalette.textDisabled.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppPalette.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppPalette.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.navyLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session['date'] as String,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppPalette.navyPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (session['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session['status'] as String,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: session['color'] as Color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session['title'] as String,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppPalette.textPrimaryLight,
                ),
              ),
              Text(
                'with ${session['coach']}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppPalette.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              if (isUpcoming)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/session-details/1'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.navyPrimary,
                      side: const BorderSide(color: AppPalette.navyPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
      },
    );
  }
}
