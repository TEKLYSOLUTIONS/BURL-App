import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import '../../config/palette.dart';

class LoginScreen extends StatefulWidget {
  final String? role;

  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Back Button (Optional context based)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
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

              const SizedBox(height: 30),

              // Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Ionicons.flag_outline,
                  size: 40,
                  color: AppPalette.orangeAccent,
                ),
              ).animate().scale(delay: 100.ms),

              const SizedBox(height: 24),

              // Title
              Text(
                'Welcome Back',
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Sign in to manage your team and track progress.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppPalette.textSecondaryLight,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),

              // Email Field
              const _CustomTextField(
                label: 'Email Address',
                hint: 'coach@example.com',
                icon: Ionicons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

              const SizedBox(height: 16),

              // Password Field
              _CustomTextField(
                label: 'Password',
                hint: '••••••••',
                icon: Ionicons.lock_closed_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onVisibilityChanged: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

              const SizedBox(height: 12),

              // Details: Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppPalette.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) =>
                              setState(() => _rememberMe = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.inter(
                          color: AppPalette.textSecondaryLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        color: AppPalette.orangeAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.role == 'coach') {
                      context.go('/coach/home');
                    } else if (widget.role == 'player') {
                      context.go('/player/home');
                    } else {
                      context.go('/guardian/home');
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Log In',
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
                      'OR CONTINUE WITH',
                      style: GoogleFonts.inter(
                        color: AppPalette.textSecondaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
                      assetPath: 'assets/images/logo_google.png',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SocialButton(
                      assetPath: 'assets/images/logo_apple.png',
                      isApple: true,
                      onTap: () {},
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 900.ms),

              const SizedBox(height: 48),

              // Footer
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (widget.role != null) {
                      context.go('/register?role=${widget.role}');
                    } else {
                      context.go('/register');
                    }
                  },
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppPalette.textSecondaryLight,
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
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

  const _CustomTextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.onVisibilityChanged,
    this.keyboardType = TextInputType.text,
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
  final String assetPath;
  final VoidCallback onTap;
  final bool isApple;

  const _SocialButton({
    required this.assetPath,
    required this.onTap,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56, // Match main button height
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, height: 24, width: 24),
            if (isApple) ...[
              const SizedBox(width: 8),
              Text(
                'iOS',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
