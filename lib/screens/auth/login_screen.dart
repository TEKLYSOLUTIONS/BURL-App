import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.white, // Reference has white background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Wave Header
            Stack(
              children: [
                ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppPalette.navyPrimary, AppPalette.navyLight],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Placeholder Logo
                          const Icon(
                            Icons.sports_cricket,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'CRICKET COACH',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                ),
              ],
            ).animate().slideY(begin: -0.2, duration: 600.ms),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Welcome back!',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.textPrimaryLight,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  if (widget.role != null)
                    Text(
                      'Login as ${widget.role!.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppPalette.textSecondaryLight,
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  // Username / Email Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                  const SizedBox(height: 16),

                  // Password Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextFormField(
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppPalette.navyPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) =>
                                setState(() => _rememberMe = val!),
                          ),
                          Text(
                            'Remember me',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 30),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
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
                        backgroundColor: Colors.transparent, // For gradient
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: AppPalette.orangeAccent,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.orangeAccent.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            'Login',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),

                  // Create Account Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "New user? ",
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.role != null) {
                            context.go('/register?role=${widget.role}');
                          } else {
                            context.go('/register');
                          }
                        },
                        child: Text(
                          "Sign Up",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppPalette.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "OR",
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 20),

                  // Social Media
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialIcon(
                        icon: Icons.facebook,
                        color: Color(0xFF1877F2),
                      ),
                      SizedBox(width: 20),
                      _SocialIcon(
                        icon: Icons.g_mobiledata,
                        color: Colors.red,
                        size: 34,
                      ), // Google placeholder
                      SizedBox(width: 20),
                      _SocialIcon(icon: Icons.apple, color: Colors.black),
                    ],
                  ).animate().fadeIn(delay: 1000.ms),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _SocialIcon({required this.icon, required this.color, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    // First curve
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Second curve
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
