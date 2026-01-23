import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  final bool isCoachView;
  final String? playerId;
  const ProfileScreen({super.key, this.isCoachView = false, this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 50),
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // Light Theme
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (isCoachView) {
                                // Coach view viewing player profile OR coach profile - Logic might need detail
                                // Assuming 'isCoachView' true means a coach is looking at a player?
                                // Actually ProfileScreen is used for 'Me' tab too.
                                context.push('/settings');
                              } else {
                                // Player Profile
                                context.push('/player/settings');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white, // Match background
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=11',
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 16),

            Text(
              'Arjun Kumar',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Batsman • Right Hand',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(context, 'Sessions', '12'),
                  _buildDivider(),
                  _buildStat(context, 'Hours', '24'),
                  _buildDivider(),
                  _buildStat(context, 'Rating', '4.8'),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 40),

            // Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (!isCoachView)
                    _ProfileMenuItem(
                      icon: Icons.person_outline,
                      label: 'Personal Details',
                      onTap: () => context.push('/edit-profile'),
                    ),
                  if (isCoachView)
                    _ProfileMenuItem(
                      icon: Icons.bar_chart,
                      label: 'Performance Reports',
                      onTap: () =>
                          context.push('/player-reports/${playerId ?? '1'}'),
                    ),
                  _ProfileMenuItem(
                    icon: Icons.history,
                    label: 'Booking History',
                    onTap: () {},
                  ),
                  if (!isCoachView) ...[
                    _ProfileMenuItem(
                      icon: Icons.credit_card,
                      label: 'Payment Methods',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    _ProfileMenuItem(
                      icon: Icons.logout,
                      label: 'Log Out',
                      color: AppPalette.error,
                      onTap: () => context.go('/welcome'),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: AppPalette.divider);
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppPalette.divider.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: color ?? Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppPalette.textDisabled.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
