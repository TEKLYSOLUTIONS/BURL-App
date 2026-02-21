import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Navigate after splash — check if already logged in
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role');
      if (!mounted) return;
      if (token != null && token.isNotEmpty && role != null) {
        switch (role) {
          case 'coach':
            context.go('/coach/home');
            break;
          case 'guardian':
            context.go('/guardian/home');
            break;
          default:
            context.go('/player/home');
        }
      } else {
        context.go('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context)
          .scaffoldBackgroundColor, // Adapts to Light/Dark Mode
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Burl Logo
                Image.asset(
                  'assets/images/logo_burl.png',
                  width: 350,
                  height: 350,
                  fit: BoxFit.contain,
                ),

                // const SizedBox(height: 40),

                // // Tagline
                // Text(
                //   'Master Your Game',
                //   style: GoogleFonts.inter(
                //     color: AppPalette.textSecondaryLight,
                //     fontSize: 16,
                //     fontWeight: FontWeight.w500,
                //     letterSpacing: 1.5,
                //   ),
                // ),
                const SizedBox(height: 60),

                // Loading Indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
