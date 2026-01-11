import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../../models/user_model.dart';

class MyPlayersScreen extends StatelessWidget {
  const MyPlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: Text(
          'My Players',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppPalette.navyPrimary,
          ),
          onPressed: () => context.go('/guardian/home'),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 90.0,
        ), // Move up to avoid tab bar
        child: FloatingActionButton(
          onPressed: () => context.push('/guardian/add-player'),
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: ListView(
        // Changed to ListView to easily add "Connect Athlete" at end
        padding: const EdgeInsets.all(24),
        children: [
          ...Player.mockPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _PlayerCard(
                player: player,
                index: index,
              ).animate().fadeIn(delay: (index * 100).ms).slideX(),
            );
          }),

          // Connect Athlete Card
          _ConnectAthleteCard()
              .animate()
              .fadeIn(delay: (Player.mockPlayers.length * 100).ms)
              .slideX(),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final int index;

  const _PlayerCard({required this.player, required this.index});

  @override
  Widget build(BuildContext context) {
    // Mock status logic for demo
    final bool isGameDay = index == 0;
    final bool isTrainingComplete = index == 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            context.push('/guardian/player-details/${index + 1}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar with potentially a status indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(player.avatarUrl),
                      backgroundColor: AppPalette.navyLight,
                    ),
                    if (isGameDay)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.role} • #${index == 0 ? "10" : "23"}', // Mock jersey detail
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppPalette.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status Row
                      if (isGameDay)
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GAME TOMORROW 9:00 AM',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        )
                      else if (isTrainingComplete)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Training Complete',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        // Fallback or empty status
                        Text(
                          'Next Session: Fri 4pm', // Mock
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppPalette.textDisabled,
                          ),
                        ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectAthleteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Logic to connect athlete code
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connect Athlete Flow')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icon Placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect Athlete',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Colors.grey[700], // Slightly lighter than primary
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter team code',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppPalette.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Plus Icon
                Icon(Icons.add_circle, size: 28, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
