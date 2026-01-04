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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Players',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppPalette.navyPrimary,
            onPressed: () {
              context.push('/guardian/add-player');
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: Player.mockPlayers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final player = Player.mockPlayers[index];
          return _PlayerCard(
            player: player,
            index: index, // Pass index for ID simulation
          ).animate().fadeIn(delay: (index * 100).ms).slideX();
        },
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.push('/guardian/player-details/${index + 1}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(player.avatarUrl),
                  backgroundColor: AppPalette.navyLight,
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
                        '${player.role} • ${player.age} yrs',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppPalette.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.battingStyle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppPalette.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppPalette.textDisabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
