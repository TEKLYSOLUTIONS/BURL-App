import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../../models/user_model.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Students',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: Player.mockPlayers.length, // Reusing Player mock
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final student = Player.mockPlayers[index];
          return _StudentCard(
            student: student,
          ).animate().fadeIn(delay: (index * 100).ms).slideX();
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Player student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(student.avatarUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Next Session: Tomorrow, 10 AM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppPalette.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.note_add_outlined,
                color: AppPalette.navyPrimary,
              ),
              onPressed: () {
                // Navigate to create report
                context.push('/coach/session-report');
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppPalette.navyPrimary,
              ),
              onPressed: () {
                // Chat placeholder
              },
            ),
          ],
        ),
      ),
    );
  }
}
