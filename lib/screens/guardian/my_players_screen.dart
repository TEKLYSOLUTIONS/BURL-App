import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/palette.dart';
import '../../services/guardian_service.dart';
import '../../widgets/notification_button.dart';
import '../../utils/date_time_utils.dart';

class MyPlayersScreen extends StatefulWidget {
  const MyPlayersScreen({super.key});

  @override
  State<MyPlayersScreen> createState() => _MyPlayersScreenState();
}

class _MyPlayersScreenState extends State<MyPlayersScreen>
    with WidgetsBindingObserver {
  final _guardianService = GuardianService();
  List<dynamic> _players = [];
  bool _isLoading = true;
  String? _error;

  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch on first build AND on every time the route becomes active again
    // (e.g. popping back from edit-player or player-details)
    if (!_initialised || !_isLoading) {
      _initialised = true;
      _fetchPlayers();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchPlayers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Light grey background
      appBar: AppBar(
        title: Text(
          'My Players',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: NotificationButton(
              onTap: () => context.push('/guardian/notifications'),
              iconColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ],
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
          backgroundColor: AppPalette.orangeAccent,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
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
        _ConnectAthleteCard(onPlayerAdded: _fetchPlayers)
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            )
                          : null,
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
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Mock Status Row
                      Text(
                          'Age: ${DateTimeUtils.calculateAge(playerData['dateOfBirth'], playerData['age']?.toString())}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectAthleteCard extends StatefulWidget {
  final VoidCallback onPlayerAdded;

  const _ConnectAthleteCard({required this.onPlayerAdded});

  @override
  State<_ConnectAthleteCard> createState() => _ConnectAthleteCardState();
}

class _ConnectAthleteCardState extends State<_ConnectAthleteCard> {
  void _showConnectDialog(BuildContext context) {
    final emailController = TextEditingController();
    bool isConnecting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(
            'Connect Athlete',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the email address of the existing player to link them to your account.',
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'player@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isConnecting ? null : () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              onPressed: isConnecting
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;

                      setState(() {
                        isConnecting = true;
                      });

                      try {
                        await GuardianService().linkPlayer(email);
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Player linked successfully!'),
                              backgroundColor: AppPalette.successGreen,
                            ),
                          );
                          widget.onPlayerAdded();
                        }
                      } catch (e) {
                        setState(() {
                          isConnecting = false;
                        });
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.orangeAccent,
                foregroundColor: Colors.white,
              ),
              child: isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Connect', style: GoogleFonts.inter()),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
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
            _showConnectDialog(context);
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
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
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface, // Slightly lighter than primary
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter player email',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Plus Icon
                Icon(
                  Icons.add_circle,
                  size: 28,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
