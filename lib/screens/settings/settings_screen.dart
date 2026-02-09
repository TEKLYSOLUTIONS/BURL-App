import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/notification_button.dart';
import '../../config/palette.dart';
import '../../services/profile_service.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await ProfileService.getProfile();

      setState(() {
        _userData = data['user'] as Map<String, dynamic>?;
        _profileData = data['profile'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String get displayName {
    if (_userData != null) {
      return _userData!['fullName'] as String? ?? 'User';
    }
    return 'User';
  }

  String get displayRole {
    if (_profileData != null) {
      // For coach, show coachTitle if available
      if (_profileData!['coachTitle'] != null) {
        return _profileData!['coachTitle'] as String;
      }
    }
    if (_userData != null) {
      final role = _userData!['role'] as String? ?? '';
      return role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : '';
    }
    return '';
  }

  String get displayEmail {
    if (_userData != null) {
      return _userData!['email'] as String? ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppPalette.navyPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                ),
                Expanded(
                  child: Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                ),
                NotificationButton(
                  iconColor:
                      Theme.of(context).iconTheme.color ??
                      AppPalette.navyPrimary,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Profile Summary
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
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
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppPalette.navyPrimary,
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppPalette.navyPrimary,
                                      ),
                                    ),
                                    if (displayRole.isNotEmpty)
                                      Text(
                                        displayRole,
                                        style: GoogleFonts.inter(
                                          color: AppPalette.textSecondaryLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final role = _userData?['role'] as String?;
                                    if (role == 'coach') {
                                      final result = await context.push(
                                        '/coach/complete-profile',
                                        extra: _profileData,
                                      );
                                      if (result == true) {
                                        _loadProfile();
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(),

                        const SizedBox(height: 32),

                        _buildSectionHeader('ACCOUNT'),
                        const SizedBox(height: 16),

                        _buildSettingsItem(
                          icon: Icons.lock_outline,
                          iconColor: Colors.orange,
                          iconBg: Colors.orange.withValues(alpha: 0.1),
                          title: 'Change Password',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsItem(
                          icon: Icons.star_outline,
                          iconColor: Colors.orange,
                          iconBg: Colors.orange.withValues(alpha: 0.1),
                          title: 'Subscription',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Pro Coach',
                              style: GoogleFonts.inter(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {},
                        ),

                        const SizedBox(height: 32),
                        _buildSectionHeader('PREFERENCES'),
                        const SizedBox(height: 16),
                        _buildSettingsItem(
                          icon: Icons.notifications_outlined,
                          iconColor: Colors.purple,
                          iconBg: Colors.purple.withValues(alpha: 0.1),
                          title: 'Push Notifications',
                          trailing: Switch(
                            value:
                                _userData?['preferences']?['pushNotifications'] ??
                                true,
                            activeTrackColor: Colors.orange,
                            onChanged: (value) {
                              // Update preferences
                            },
                          ),
                          onTap: null,
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsItem(
                          icon: Icons.dark_mode_outlined,
                          iconColor: Colors.grey.shade700,
                          iconBg: Colors.grey.shade100,
                          title: 'Dark Mode',
                          trailing: Switch(
                            value: ref.watch(themeProvider) == ThemeMode.dark,
                            activeTrackColor: Colors.orange,
                            onChanged: (value) {
                              ref
                                  .read(themeProvider.notifier)
                                  .toggleTheme(value);
                            },
                          ),
                          onTap: null,
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsItem(
                          icon: Icons.language,
                          iconColor: Colors.cyan,
                          iconBg: Colors.cyan.withValues(alpha: 0.1),
                          title: 'Language',
                          trailing: const Text('English (US)'),
                          onTap: () {},
                        ),

                        const SizedBox(height: 32),
                        _buildSectionHeader('Support'),
                        const SizedBox(height: 16),
                        _buildSettingsItem(
                          icon: Icons.help_outline,
                          iconColor: Colors.orange,
                          iconBg: Colors.orange.withValues(alpha: 0.1),
                          title: 'Help Center',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsItem(
                          icon: Icons.info_outline,
                          iconColor: Colors.orange,
                          iconBg: Colors.orange.withValues(alpha: 0.1),
                          title: 'About App',
                          onTap: () {},
                        ),

                        const SizedBox(height: 48),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('token');
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: Text(
                              'Log Out',
                              style: GoogleFonts.outfit(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.05,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
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
          color:
              Theme.of(context).textTheme.bodyMedium?.color ??
              AppPalette.textSecondaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? iconBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg ?? AppPalette.navyPrimary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppPalette.navyPrimary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
            fontSize: 15,
          ),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: AppPalette.textSecondaryLight,
                  )
                : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ).animate().fadeIn().slideX();
  }
}
