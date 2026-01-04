import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  final String? role;

  const RegisterScreen({super.key, this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Wave Header
            Stack(
              children: [
                ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: 250, // Slightly smaller than login
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
                          const Icon(
                            Icons.person_add,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'JOIN US',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
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
                        context.go('/login');
                      }
                    },
                  ),
                ),
              ],
            ).animate().slideY(begin: -0.2, duration: 600.ms),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.textPrimaryLight,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      'Sign up as a ${widget.role?.toUpperCase() ?? "USER"}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppPalette.textSecondaryLight,
                      ),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 30),

                    // Name Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    // Email Field
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
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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
                        textInputAction: TextInputAction.next,
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextFormField(
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                          prefixIcon: Icon(
                            Icons.check_circle_outline,
                            color: Colors.grey[500],
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),

                    const SizedBox(height: 40),

                    // Register Button
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
                            context.go('/guardian/add-player');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppPalette.orangeAccent,
                                AppPalette.orangeLight,
                              ],
                            ),
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
                              'Create Account',
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (widget.role != null) {
                              context.go('/login?role=${widget.role}');
                            } else {
                              context.go('/login');
                            }
                          },
                          child: Text(
                            'Login',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppPalette.navyPrimary,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 800.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
