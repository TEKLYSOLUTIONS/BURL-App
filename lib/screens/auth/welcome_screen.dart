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

  final List<String> _images = [
    'assets/images/multi_sport_welcome_1.png',
    'assets/images/multi_sport_welcome_2.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.navyPrimary, // Fallback color
      body: Stack(
        children: [
          // 1. Full Screen Background Carousel
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Image.asset(_images[index], fit: BoxFit.cover);
              },
            ),
          ),

          // 2. Gradient Overlay for text readability
          Positioned.fill(
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

          // 3. Content Section (Bottom Aligned)
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.7,
                    ), // Stronger transparent black for readability
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                      bottom: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
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
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                      const SizedBox(height: 24),

                      // Headline
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            color: Colors.white,
                          ),
                          children: const [
                            TextSpan(text: 'Master Your\n'),
                            TextSpan(
                              text: 'Sport Potential',
                              style: TextStyle(color: AppPalette.orangeAccent),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                      const SizedBox(height: 16),

                      // Subtext
                      Text(
                        'Connect with elite coaches, get personalized training plans, and track your progress in real-time.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                      const SizedBox(height: 24),

                      // Pagination Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_images.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppPalette.orangeAccent
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      // Get Started Button
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
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                      const SizedBox(height: 24),

                      // Login Link
                      GestureDetector(
                        onTap: () => context.push('/login?role=player'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.9),
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
