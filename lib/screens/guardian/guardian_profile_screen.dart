import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../../widgets/notification_button.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class GuardianProfileScreen extends ConsumerStatefulWidget {
  const GuardianProfileScreen({super.key});

  @override
  ConsumerState<GuardianProfileScreen> createState() =>
      _GuardianProfileScreenState();
}

class _GuardianProfileScreenState extends ConsumerState<GuardianProfileScreen> {
  bool _isLoading = true;
  bool _pushNotifications = true;
  String _userName = 'Guardian';
  String _userEmail = '';
  Map<String, dynamic>? _userProfile; // Store full profile data

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      setState(() {
        _userProfile = profile; // Store complete profile
        _userName = profile['fullName'] ?? 'Guardian';
        _userEmail = profile['email'] ?? '';

        final prefs = profile['preferences'] as Map<String, dynamic>?;
        if (prefs != null) {
          _pushNotifications = prefs['pushNotifications'] ?? true;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
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
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ref.watch(themeProvider) == ThemeMode.dark
                    ? AppPalette.surfaceGlassDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppPalette.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?u=sarah',
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppPalette.orangeAccent,
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
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ref.watch(themeProvider) == ThemeMode.dark
                                ? Colors.white
                                : AppPalette.navyPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail.isNotEmpty
                              ? _userEmail
                              : 'Guardian • Basic Plan',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final result = await context.push(
                              '/guardian/edit-profile',
                              extra: _userProfile, // Pass complete profile data
                            );
                            if (result == true) {
                              _fetchProfile();
                            }
                          },
                          child: Text(
                            'Edit Profile',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppPalette.orangeAccent,
                              fontWeight: FontWeight.bold,
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
            _buildSettingsList([
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                onTap: () => context.push('/guardian/change-password'),
              ),
              _buildSettingsTile(
                icon: Icons.credit_card,
                title: 'Payment Method',
                onTap: () => context.push('/guardian/payment-methods'),
              ),
            ]),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader('PREFERENCES'),
            _buildSettingsList([
              _buildSettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Push Notifications',
                isToggle: true,
                switchValue: _pushNotifications,
                onToggle: (val) => setState(() => _pushNotifications = val),
              ),
              _buildSettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final isDark =
                            ref.watch(themeProvider) == ThemeMode.dark;
                        return Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
                onTap: () => _showThemeBottomSheet(context, ref),
              ),
              _buildSettingsTile(
                icon: Icons.language,
                title: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'English (US)',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // Support & Legal
            _buildSectionHeader('SUPPORT & LEGAL'),
            _buildSettingsList([
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                onTap: () => context.push('/guardian/help-center'),
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => context.push('/guardian/privacy-policy'),
              ),
              _buildSettingsTile(
                icon: Icons.gavel_outlined,
                title: 'Terms of Service',
                onTap: () => context.push('/guardian/terms-of-service'),
              ),
            ]),

            const SizedBox(height: 32),

            // Logout
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ref.watch(themeProvider) == ThemeMode.dark
                    ? AppPalette.surfaceGlassDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  await AuthService.signOutCompletely();
                  if (context.mounted) context.go('/welcome');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  'Log Out',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // Delete Account
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ref.watch(themeProvider) == ThemeMode.dark
                    ? AppPalette.surfaceGlassDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: TextButton.icon(
                onPressed: () => _showDeleteConfirmation(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.delete_forever),
                label: Text(
                  'Delete Account',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),
            Text(
              'Version 2.4.0 (Build 345)',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(themeProvider) == ThemeMode.dark
            ? AppPalette.surfaceGlassDark
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Column(
            children: [
              child,
              if (index != children.length - 1)
                Divider(
                  color: Colors.grey[100],
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    bool isToggle = false,
    bool switchValue = false,
    ValueChanged<bool>? onToggle,
  }) {
    return ListTile(
      onTap: isToggle ? () => onToggle?.call(!switchValue) : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ref.watch(themeProvider) == ThemeMode.dark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.orange, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ref.watch(themeProvider) == ThemeMode.dark
              ? Colors.white
              : AppPalette.navyPrimary,
        ),
      ),
      trailing: isToggle
          ? Switch.adaptive(
              value: switchValue,
              onChanged: onToggle,
              activeTrackColor: AppPalette.orangeAccent,
              activeThumbColor: Colors.white, // thumb color
            )
          : (trailing ??
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              )),
    );
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
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
} // End of _GuardianProfileScreenState
