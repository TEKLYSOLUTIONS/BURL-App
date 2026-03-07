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

    // Check auth status immediately without artificial delay
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation to finish and keep the splash screen visible a bit longer
    await Future.delayed(const Duration(milliseconds: 3000));

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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? const RadialGradient(
                      center: Alignment.center,
                      radius: 1.5, // Spread the glow out smoother
                      colors: [
                        Color(
                            0xFF2962FF), // Bright, vivid whitish-blue glow at the center
                        Color(
                            0xFF010613), // Deep, dark navy almost-black at the edges
                      ],
                    )
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Central Content: Logo and Spaced Loading Spinner
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/burl_splash_logo.png',
                        width: 250, // Adjust width as necessary
                      ),
                      const SizedBox(
                          height: 40), // Space between logo and spinner
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
