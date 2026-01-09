import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../widgets/notification_button.dart';
import '../settings/change_password_screen.dart';
import '../settings/pro_upgrade_screen.dart';

class CoachProfileScreen extends StatelessWidget {
  final String coachId; // Keep for compatibility if needed

  const CoachProfileScreen({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        // Move padding to inside Column for content only
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: AppPalette.navyPrimary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const NotificationButton(hasNotification: true),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
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
                                'Coach Alex Johnson',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Head Coach • Pro Plan',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => context.push('/edit-profile'),
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
                          iconBgColor: Colors.blue[50]!,
                          iconColor: Colors.blue,
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProUpgradeScreen(),
                            ),
                          ),
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
                            value: true,
                            onChanged: (val) {},
                            activeTrackColor: Colors.orange,
                            activeThumbColor: Colors.white,
                          ),
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.dark_mode_outlined,
                          iconBgColor: Colors.grey[100]!,
                          iconColor: Colors.grey[700]!,
                          title: 'Dark Mode',
                          trailing: Switch(
                            value: false, // Off in image
                            onChanged: (val) {},
                            activeTrackColor: Colors.grey[300],
                            activeThumbColor: Colors.white,
                          ),
                          onTap: () {},
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
                                'English (US)',
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
                          iconBgColor: Colors.green[50]!,
                          iconColor: Colors.green,
                          title: 'Help Center',
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.privacy_tip_outlined,
                          iconBgColor: Colors.blueGrey[50]!,
                          iconColor: Colors.blueGrey,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        _buildListTile(
                          icon: Icons.description_outlined,
                          iconBgColor: Colors
                              .grey[100]!, // Should actually be different icon from image
                          iconColor: Colors.grey[700]!,
                          title: 'Terms of Service',
                          onTap: () {},
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
                    color: AppPalette.navyPrimary,
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
}
