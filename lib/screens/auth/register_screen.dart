import 'package:flutter/material.dart';
import '../../config/palette.dart';
import '../../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

class RegisterScreen extends StatefulWidget {
  final String? role;

  const RegisterScreen({super.key, this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back Button
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppPalette.navyPrimary,
                ),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
              ),

              const SizedBox(height: 24),

              // Title & Subtitle
              Text(
                'Create Account',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                  height: 1.2,
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 8),

              Text(
                'Sign up to connect with top coaches and\nstart your training journey today.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppPalette.textSecondaryLight,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name Field
                    _CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Ionicons.person_outline,
                      controller: _nameController,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    // Email Field
                    _CustomTextField(
                      label: 'Email Address',
                      hint: 'name@example.com',
                      icon: Ionicons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    // Password Field
                    _CustomTextField(
                      label: 'Password',
                      hint: 'Create a password',
                      icon: Ionicons.lock_closed_outline,
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityChanged: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                      controller: _passwordController,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    _CustomTextField(
                      label: 'Confirm Password',
                      hint: 'Confirm your password',
                      icon: Ionicons.refresh_outline,
                      isPassword: true,
                      isVisible: _isConfirmPasswordVisible,
                      onVisibilityChanged: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                      controller: _confirmPasswordController,
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                    const SizedBox(height: 24),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            activeColor: AppPalette.orangeAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) =>
                                setState(() => _agreedToTerms = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        expandedText(context),
                      ],
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 32),

                    // Register Button
                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_agreedToTerms) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please agree to the terms.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (_passwordController.text !=
                                    _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isLoading = true);
                                final success = await AuthService.register(
                                  _nameController.text,
                                  _emailController.text,
                                  _passwordController.text,
                                  widget.role ?? 'player',
                                );

                                if (!context.mounted) return;

                                setState(() => _isLoading = false);

                                if (success) {
                                  if (widget.role == 'coach') {
                                    context.go('/coach/home');
                                  } else if (widget.role == 'player') {
                                    context.go('/player/home');
                                  } else {
                                    context.go('/guardian/add-player');
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Registration failed.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.orangeAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Register',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Ionicons.arrow_forward, size: 20),
                                ],
                              ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

                    const SizedBox(height: 32),

                    // Social Login Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or register with',
                            style: GoogleFonts.inter(
                              color: AppPalette.textSecondaryLight,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 24),

                    // Social Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            assetPath: 'assets/images/logo_google.png',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            assetPath: 'assets/images/logo_apple.png',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms),

                    const SizedBox(height: 32),

                    // Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if (widget.role != null) {
                            context.go('/login?role=${widget.role}');
                          } else {
                            context.go('/login');
                          }
                        },
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppPalette.textSecondaryLight,
                            ),
                            children: [
                              const TextSpan(text: 'Already a member? '),
                              TextSpan(
                                text: 'Log In',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded expandedText(BuildContext context) {
    return Expanded(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppPalette.textSecondaryLight,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'I agree to the '),
            TextSpan(
              text: 'Terms of Service',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onVisibilityChanged;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const _CustomTextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.onVisibilityChanged,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppPalette.navyPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible
                            ? Ionicons.eye_off_outline
                            : Ionicons.eye_outline,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: onVisibilityChanged,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String assetPath;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, height: 24, width: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppPalette.navyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
