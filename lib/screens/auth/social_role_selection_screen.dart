import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/palette.dart';
import '../../services/firebase_auth_service.dart';

class SocialRoleSelectionScreen extends StatefulWidget {
  final UserCredential credential;

  const SocialRoleSelectionScreen({super.key, required this.credential});

  @override
  State<SocialRoleSelectionScreen> createState() =>
      _SocialRoleSelectionScreenState();
}

class _SocialRoleSelectionScreenState extends State<SocialRoleSelectionScreen> {
  String? selectedRole;
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  late final String _defaultName;

  @override
  void initState() {
    super.initState();
    final displayName = widget.credential.user?.displayName ?? '';
    final email = widget.credential.user?.email ?? '';
    
    _defaultName = displayName;
    if (_defaultName.isEmpty && email.isNotEmpty) {
      // Capitalize the first letter of the email prefix for a better default name
      final prefix = email.split('@').first;
      if (prefix.isNotEmpty) {
        _defaultName = prefix[0].toUpperCase() + prefix.substring(1);
      }
    }
  }

  Future<void> _handleFinalizeLogin() async {
    if (selectedRole == null) return;

    setState(() => _isLoading = true);
    
    try {
      await _authService.finalizeSocialLogin(
        userCredential: widget.credential,
        role: selectedRole!,
        fullName: _defaultName,
      );

      if (!mounted) return;

      if (selectedRole == 'coach') {
        context.go('/coach/home');
      } else if (selectedRole == 'player') {
        context.go('/player/home');
      } else if (selectedRole == 'guardian') {
        context.go('/guardian/home');
      } else {
        context.go('/player/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Back Button (Cancels sign in/up)
                IconButton(
                  icon: Icon(
                    Ionicons.chevron_back,
                    color: Theme.of(context).iconTheme.color,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () {
                    // Sign out of Firebase if they back out?
                    FirebaseAuth.instance.signOut();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'What\'s your\ngame plan?',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2,
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Complete your profile by selecting the role that best describes you.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color ??
                        AppPalette.textSecondaryLight,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

                const SizedBox(height: 40),

                // Role Options
                _RoleOption(
                  assetPath: 'assets/images/icon_role_coach.png',
                  title: 'Coach',
                  description: 'Manage teams & strategy',
                  value: 'coach',
                  groupValue: selectedRole,
                  iconBgColor: Colors.transparent,
                  iconColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) => setState(() => selectedRole = value),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                _RoleOption(
                  assetPath: 'assets/images/icon_role_player.png',
                  title: 'Player',
                  description: 'Track stats & training',
                  value: 'player',
                  groupValue: selectedRole,
                  iconBgColor: Colors.transparent,
                  iconColor: AppPalette.orangeAccent,
                  onChanged: (value) => setState(() => selectedRole = value),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                _RoleOption(
                  assetPath: 'assets/images/icon_role_guardian.png',
                  title: 'Guardian',
                  description: 'Monitor progress & schedules',
                  value: 'guardian',
                  groupValue: selectedRole,
                  iconBgColor: Colors.transparent,
                  iconColor: const Color(0xFF2E7D32),
                  onChanged: (value) => setState(() => selectedRole = value),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (selectedRole != null && !_isLoading)
                        ? _handleFinalizeLogin
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
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Complete Sign Up',
                                style: GoogleFonts.inter(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String assetPath;
  final String title;
  final String description;
  final String value;
  final String? groupValue;
  final Color iconBgColor;
  final Color iconColor;
  final ValueChanged<String?> onChanged;

  const _RoleOption({
    required this.assetPath,
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppPalette.orangeAccent
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 20),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          AppPalette.textSecondaryLight,
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
                      : Theme.of(context).dividerColor,
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
