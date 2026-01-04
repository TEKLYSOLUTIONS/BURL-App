import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/'); // Fallback
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppPalette.navyPrimary,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Name',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      Text(
                        'user@example.com',
                        style: GoogleFonts.inter(
                          color: AppPalette.textSecondaryLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppPalette.navyPrimary,
                    ),
                    onPressed: () {
                      // Navigate to edit profile (assume exists or mock)
                    },
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(),

            const SizedBox(height: 32),

            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 16),

            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.payment,
              title: 'Payment Methods',
              onTap: () {},
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Preferences'),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.language,
              title: 'Language',
              trailing: const Text('English'),
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              trailing: const Text('Light'),
              onTap: () {},
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Support'),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'About App',
              onTap: () {},
            ),

            const SizedBox(height: 48),

            // Logout
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  context.go('/login');
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
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppPalette.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
            color: AppPalette.navyPrimary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppPalette.navyPrimary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: AppPalette.textPrimaryLight,
            fontSize: 15,
          ),
        ),
        trailing:
            trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ).animate().fadeIn().slideX();
  }
}
