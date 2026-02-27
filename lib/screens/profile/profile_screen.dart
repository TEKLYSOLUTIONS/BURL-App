import 'package:flutter/material.dart';
import '../../config/palette.dart';
import '../../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final bool isCoachView;
  final String? playerId;
  const ProfileScreen({super.key, this.isCoachView = false, this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    debugPrint('ProfileScreen Build: ThemeMode = $themeMode');
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
              style: GoogleFonts.inter(
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
                          context.push('/coach/reports/${playerId ?? '1'}'),
                    ),
                  _ProfileMenuItem(
                    icon: Icons.history,
                    label: 'Booking History',
                    onTap: () => context.push('/bookings'),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.credit_card,
                    label: 'Payment Methods',
                    onTap: () => context.push(
                      '/payment-methods',
                    ), // Ensure this route exists or handle it
                  ),
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: 24),
                  // Toggles
                  _ProfileToggleItem(
                    icon: Icons.notifications_active_outlined,
                    label: 'Push Notifications',
                    value: true,
                    onChanged: (val) {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.palette_outlined,
                    label: 'Appearance',
                    trailing: Consumer(
                      builder: (context, ref, child) {
                        final isDark =
                            ref.watch(themeProvider) == ThemeMode.dark;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isDark ? 'Dark Mode' : 'Light Mode',
                              style: GoogleFonts.inter(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppPalette.textDisabled.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    onTap: () => _showThemeBottomSheet(context, ref),
                  ),
                  const SizedBox(height: 24),
                  _ProfileMenuItem(
                    icon: Icons.logout,
                    label: 'Log Out',
                    color: AppPalette.error,
                    onTap: () async {
                      await AuthService.signOutCompletely();
                      if (context.mounted) context.go('/welcome');
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.delete_forever,
                    label: 'Delete Account',
                    color: AppPalette.error,
                    onTap: () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delete Account',
                      style: TextStyle(color: AppPalette.error)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed:
                        isLoading ? null : () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: const Text(
                'Are you sure you want to permanently delete your account? This action cannot be undone and you will lose all your data.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          final success = await AuthService.deleteAccount();
                          setState(() => isLoading = false);

                          if (context.mounted) {
                            if (success) {
                              Navigator.of(context).pop(); // Close dialog
                              context.go('/welcome'); // Redirect
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to delete account. Please try again later.')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.error,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Delete',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
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

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = ref.watch(themeProvider) == ThemeMode.dark;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Appearance',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildThemeOption(
                context,
                ref,
                title: 'Light Mode',
                icon: Icons.light_mode_outlined,
                isSelected: !isDark,
                onTap: () {
                  ref.read(themeProvider.notifier).toggleTheme(false);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context,
                ref,
                title: 'Dark Mode',
                icon: Icons.dark_mode_outlined,
                isSelected: isDark,
                onTap: () {
                  ref.read(themeProvider.notifier).toggleTheme(true);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.orange, width: 2)
              : Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange
                    : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.orange
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ref.watch(themeProvider) == ThemeMode.dark
                ? AppPalette.surfaceGlassDark
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: ref.watch(themeProvider) == ThemeMode.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppPalette.divider.withValues(alpha: 0.5),
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
              if (trailing != null)
                trailing!
              else
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

class _ProfileToggleItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProfileToggleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ref.watch(themeProvider) == ThemeMode.dark
              ? AppPalette.surfaceGlassDark
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: ref.watch(themeProvider) == ThemeMode.dark
                ? Colors.white.withValues(alpha: 0.1)
                : AppPalette.divider.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppPalette.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }
}
