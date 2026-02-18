import 'dart:async';
import 'dart:ui';
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
      imageAsset: 'assets/images/welcome_england.png',
      title1: 'Master Your\n',
      title2: 'Game',
    ),
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_srilanka.png',
      title1: 'Unleash Your\n',
      title2: 'Full Potential',
    ),
    WelcomeSlide(
      imageAsset: 'assets/images/welcome_nz.png',
      title1: 'Experience the\n',
      title2: 'Victory',
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

                // Glass Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                      bottom: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Badge

                            // Animated Headlines
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: RichText(
                                key: ValueKey<int>(_currentPage),
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                    color: Colors.white,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _slides[_currentPage].title1,
                                    ),
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

                            // Pagination Dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_slides.length, (index) {
                                final isActive = index == _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  height: 6,
                                  width: isActive ? 24 : 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppPalette.orangeAccent
                                        : Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 32),

                            // Get Started Button / Next Button
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppPalette.orangeAccent.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _currentPage == _slides.length - 1
                                    ? () => context.push('/role-selection')
                                    : _onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.orangeAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  // Override theme's infinity width
                                  minimumSize: const Size(200, 50),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  _currentPage == _slides.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn().scale(),

                            const SizedBox(height: 24),

                            // Login Link
                            GestureDetector(
                              onTap: () => context.push('/login?role=player'),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: Colors.white70,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                    ),
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
                    ),
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
  WelcomeSlide({
    required this.imageAsset,
    required this.title1,
    required this.title2,
  });
}
