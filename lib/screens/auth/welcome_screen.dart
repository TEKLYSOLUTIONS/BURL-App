import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/palette.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<WelcomeSlide> _slides = [
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_batting_light.png',
      title1: 'Master Your\n',
      title2: 'Game Skills',
      description:
          'Connect with elite coaches to perfect your technique and dominate in any sport.',
    ),
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_bowling_light.png',
      title1: 'Unleash Your\n',
      title2: 'Full Potential',
      description:
          'Get personalized training plans and analysis to reach the next level of performance.',
    ),
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_fielding_light.png',
      title1: 'Experience the\n',
      title2: 'Thrill of Victory',
      description:
          'Join a community of passionate athletes and track your journey to success.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-scroll is optional for onboarding, but requested in previous context.
    // Keeping it but ensuring it stops on interaction or can be manual.
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _slides.length - 1) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage + 1,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      } else {
        // Stop auto-scroll at end or loop? Usually onboarding stops or loops.
        // Let's loop for "welcome screen" feel, but since it has "Get Started" at end, maybe stop?
        // User said "on last picture get started button shuld apper".
        // Use case: Onboarding. Let's stop at the end.
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      context.push('/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.navyPrimary,
      body: Stack(
        children: [
          // 1. Full Screen Background Carousel
          // 1. Full Screen Background Carousel
          Positioned.fill(
            child: Listener(
              onPointerDown: (_) {
                _timer?.cancel();
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    _slides[index].imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppPalette.navyPrimary);
                    },
                  );
                },
              ),
            ),
          ),

          // 2. Gradient Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 0.7, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Content Section
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                      bottom: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: AppPalette.orangeAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '#1 COACHING APP',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                      const SizedBox(height: 24),

                      // Animated Headlines
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: RichText(
                          key: ValueKey<int>(_currentPage),
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(text: _slides[_currentPage].title1),
                              TextSpan(
                                text: _slides[_currentPage].title2,
                                style: const TextStyle(
                                  color: AppPalette.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Animated Description
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _slides[_currentPage].description,
                          key: ValueKey<int>(_currentPage),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pagination Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppPalette.orangeAccent
                                  : Colors.black.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      // Get Started Button / Next Button
                      if (_currentPage == _slides.length - 1)
                        ElevatedButton(
                          onPressed: () => context.push('/role-selection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.orangeAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ).animate().fadeIn().scale()
                      else
                        ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.orangeAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Login Link
                      GestureDetector(
                        onTap: () => context.push('/login?role=player'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
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
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeSlide {
  final String imageAsset;
  final String title1;
  final String title2;
  final String description;

  WelcomeSlide({
    required this.imageAsset,
    required this.title1,
    required this.title2,
    required this.description,
  });
}
