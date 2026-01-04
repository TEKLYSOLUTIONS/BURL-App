import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      body: Stack(
        children: [
          // 1. Header Background (Navy)
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppPalette.navyPrimary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                // Header Content (in navy area)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Title (White text in header)
                      Text(
                        'What\'s your\ngame plan?',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),

                      const SizedBox(height: 12),

                      // Subtitle (White text in header)
                      Text(
                        'Select the role that best describes you to\ncustomize your experience.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Role Options and buttons (below header)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _RoleOption(
                          icon: Icons.sports_soccer,
                          title: 'Coach',
                          description: 'Manage teams & strategy',
                          value: 'coach',
                          groupValue: selectedRole,
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                        const SizedBox(height: 16),

                        _RoleOption(
                          icon: Icons.sports_cricket,
                          title: 'Player',
                          description: 'Track stats & training',
                          value: 'player',
                          groupValue: selectedRole,
                          iconColor: AppPalette.orangeAccent,
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                        if (selectedRole == 'player') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.orangeAccent.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppPalette.orangeAccent.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: AppPalette.orangeAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "I'm booking sessions for myself",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppPalette.navyPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(),
                        ],

                        const SizedBox(height: 16),

                        _RoleOption(
                          icon: Icons.family_restroom,
                          title: 'Guardian',
                          description: 'Monitor progress & schedules',
                          value: 'guardian',
                          groupValue: selectedRole,
                          iconColor: AppPalette.success,
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                        const Spacer(),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: selectedRole != null
                                ? () {
                                    context.push('/login?role=$selectedRole');
                                  }
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 16),

                        // Login Link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppPalette.textSecondaryLight,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.push('/login');
                                },
                                child: Text(
                                  'Log in',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppPalette.navyPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final Color iconColor;
  final ValueChanged<String?> onChanged;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.iconColor = AppPalette.navyPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppPalette.orangeAccent : AppPalette.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppPalette.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppPalette.orangeAccent
                      : AppPalette.textDisabled,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
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
