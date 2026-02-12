import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
import '../settings/change_password_screen.dart';

import '../../services/profile_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class CoachProfileScreen extends ConsumerStatefulWidget {
  final String coachId; // Keep for compatibility if needed

  const CoachProfileScreen({super.key, required this.coachId});

  @override
  ConsumerState<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends ConsumerState<CoachProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _userName = 'Coach';
  String _userEmail = '';
  bool _pushNotifications = true;
  String _language = 'English (US)';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      setState(() {
        _profileData = profile;
        _userName = profile['fullName'] ?? 'Coach';
        _userEmail = profile['email'] ?? '';

        // Get preferences if they exist
        final prefs = profile['preferences'] as Map<String, dynamic>?;
        if (prefs != null) {
          _language = prefs['language'] == 'en-US'
              ? 'English (US)'
              : prefs['language'] ?? 'English (US)';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SingleChildScrollView(
        // Move padding to inside Column for content only
        child: Column(
          children: [
            CoachAppBar(
              backgroundColor: AppPalette.navyPrimary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  NotificationButton(
                    onTap: () => context.push('/coach/notifications'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ref.watch(themeProvider) == ThemeMode.dark
                          ? AppPalette.surfaceGlassDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ref.watch(themeProvider) == ThemeMode.dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 35,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?img=11',
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 14,
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
                                _userName,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      ref.watch(themeProvider) == ThemeMode.dark
                                      ? Colors.white
                                      : AppPalette.navyPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail.isNotEmpty
                                    ? _userEmail
                                    : 'Head Coach',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => context.push(
                                  '/edit-profile',
                                  extra: _profileData,
                                ),
                                child: Text(
                                  'Edit Profile',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Account Section
                  _buildSectionHeader('ACCOUNT'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.lock_outline,
                          iconBgColor: Colors.orange[50]!,
                          iconColor: Colors.orange,
                          title: 'Change Password',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.verified_outlined,
                          iconBgColor: Colors.orange[50]!,
                          iconColor: Colors.orange,
                          title: 'Subscription',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50], // Light orange
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Pro Coach',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          onTap: () => context.push('/pro-upgrade'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Preferences Section
                  _buildSectionHeader('PREFERENCES'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.notifications_none,
                          iconBgColor: Colors.purple[50]!,
                          iconColor: Colors.purple,
                          title: 'Push Notifications',
                          trailing: Switch(
                            value: _pushNotifications,
                            onChanged: (val) {
                              setState(() => _pushNotifications = val);
                            },
                            activeTrackColor: Colors.orange,
                            activeThumbColor: Colors.white,
                          ),
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.palette_outlined,
                          iconBgColor: Colors.grey[100]!,
                          iconColor: Colors.grey[700]!,
                          title: 'Appearance',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer(
                                builder: (context, ref, child) {
                                  final isDark =
                                      ref.watch(themeProvider) ==
                                      ThemeMode.dark;
                                  return Text(
                                    isDark ? 'Dark Mode' : 'Light Mode',
                                    style: GoogleFonts.inter(
                                      color: AppPalette.textSecondaryLight,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          onTap: () => _showThemeBottomSheet(context, ref),
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.translate,
                          iconBgColor: Colors.teal[50]!,
                          iconColor: Colors.teal,
                          title: 'Language',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _language,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Support & Legal
                  _buildSectionHeader('SUPPORT & LEGAL'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.help_outline,
                          iconBgColor: Colors.orange[50]!,
                          iconColor: Colors.orange,
                          title: 'Help Center',
                          onTap: () => context.push('/help-center'),
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.privacy_tip_outlined,
                          iconBgColor: Colors.orange[50]!,
                          iconColor: Colors.orange,
                          title: 'Privacy Policy',
                          onTap: () => context.push('/privacy-policy'),
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.description_outlined,
                          iconBgColor: Colors.orange[50]!,
                          iconColor: Colors.orange,
                          title: 'Terms of Service',
                          onTap: () => context.push('/terms'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go('/welcome');
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ), // Light red border
                      backgroundColor: Colors.red.withValues(alpha: 0.05),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),
                  Text(
                    'Version 2.4.0 (Build 345)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppPalette.textSecondaryLight,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20,
        ), // Not perfect if inside column, but ok
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ref.watch(themeProvider) == ThemeMode.dark
                        ? Colors.white
                        : AppPalette.navyPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing,
                if (trailing is! Icon && trailing is! Row)
                  const SizedBox(width: 12),
                if (trailing is! Icon && trailing is! Row)
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ] else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                style: GoogleFonts.outfit(
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
              : Border.all(color: AppPalette.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
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
