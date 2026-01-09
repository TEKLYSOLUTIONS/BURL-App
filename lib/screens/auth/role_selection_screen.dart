import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';
import '../../config/palette.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back Button
              IconButton(
                icon: const Icon(
                  Ionicons.chevron_back,
                  color: AppPalette.navyPrimary,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'What\'s your\ngame plan?',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                  height: 1.2,
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Select the role that best describes you to\ncustomize your experience.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppPalette.textSecondaryLight,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 40),

              // Role Options
              Expanded(
                child: Column(
                  children: [
                    _RoleOption(
                      icon: Ionicons.shield_half_outline, // Coach/Strategy icon
                      title: 'Coach',
                      description: 'Manage teams & strategy',
                      value: 'coach',
                      groupValue: selectedRole,
                      iconBgColor: const Color(0xFFE8F1F5), // Light Blue
                      iconColor: AppPalette.navyPrimary,
                      onChanged: (value) =>
                          setState(() => selectedRole = value),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    _RoleOption(
                      icon: Ionicons.flash_outline, // Player/Action icon
                      title: 'Player',
                      description: 'Track stats & training',
                      value: 'player',
                      groupValue: selectedRole,
                      iconBgColor: AppPalette.orangeAccent.withValues(
                        alpha: 0.1,
                      ), // Light Orange
                      iconColor: AppPalette.orangeAccent,
                      onChanged: (value) =>
                          setState(() => selectedRole = value),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    _RoleOption(
                      icon: Ionicons.people_outline, // Guardian/Team icon
                      title: 'Guardian',
                      description: 'Monitor progress & schedules',
                      value: 'guardian',
                      groupValue: selectedRole,
                      iconBgColor: const Color(0xFFE8F5E9), // Light Green
                      iconColor: const Color(0xFF2E7D32), // Dark Green
                      onChanged: (value) =>
                          setState(() => selectedRole = value),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                    const Spacer(),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: selectedRole != null
                            ? () => context.push('/register?role=$selectedRole')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.orangeAccent,
                          disabledBackgroundColor: AppPalette.textDisabled
                              .withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Ionicons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 24),

                    // Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.push('/login'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppPalette.textSecondaryLight,
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Log in',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String value;
  final String? groupValue;
  final Color iconBgColor;
  final Color iconColor;
  final ValueChanged<String?> onChanged;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.iconBgColor,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppPalette.orangeAccent
                : Colors.transparent, // Cleaner look
            width: 2,
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
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppPalette.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Radio Button Custom
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppPalette.orangeAccent
                      : AppPalette.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppPalette.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
