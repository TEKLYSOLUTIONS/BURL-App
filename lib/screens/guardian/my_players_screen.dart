import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../../services/guardian_service.dart';

class MyPlayersScreen extends StatefulWidget {
  const MyPlayersScreen({super.key});

  @override
  State<MyPlayersScreen> createState() => _MyPlayersScreenState();
}

class _MyPlayersScreenState extends State<MyPlayersScreen> {
  final _guardianService = GuardianService();
  List<dynamic> _players = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final players = await _guardianService.getMyPlayers();
      if (mounted) {
        setState(() {
          _players = players;
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
          onPressed: () async {
            // Wait for result from AddPlayerScreen
            final result = await context.push('/guardian/add-player');
            if (result == true) {
              _fetchPlayers(); // Refresh list if player added
            }
          },
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPlayers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_players.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No players added yet.\nTap + to add your first athlete.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppPalette.textSecondaryLight,
                  fontSize: 16,
                ),
              ),
            ),
          ),

        ..._players.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _PlayerCard(
              playerData: player,
              index: index,
            ).animate().fadeIn(delay: (index * 100).ms).slideX(),
          );
        }),

        // Connect Athlete Card (Optional feature)
        _ConnectAthleteCard()
            .animate()
            .fadeIn(delay: (_players.length * 100).ms)
            .slideX(),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Map<String, dynamic> playerData;
  final int index;

  const _PlayerCard({required this.playerData, required this.index});

  @override
  Widget build(BuildContext context) {
    // Determine avatar URL or placeholder
    final String? avatarUrl = playerData['profilePhoto'];
    final String fullName = playerData['fullName'] ?? 'Unknown Player';
    final String role = playerData['role'] ?? 'Athlete';

    // Using mock logic for status just for display
    final bool isGameDay = index == 0;

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
            context.push('/guardian/player-details/${playerData['_id']}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : const AssetImage(
                                  'assets/images/user_placeholder_soccer.png',
                                )
                                as ImageProvider,
                      backgroundColor: AppPalette.navyLight,
                    ),
                    if (isGameDay) // Mock indicator
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
                        fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppPalette.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Mock Status Row
                      Text(
                        'Age: ${playerData['age'] ?? 'N/A'}',
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
