import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../auth/welcome_screen.dart'; // Import WelcomeScreen

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Discover Expert Coaches',
      description:
          'Find qualified coaches across all sports. Browse profiles, read reviews, and choose the perfect match for your goals.',
      imageColor: AppPalette.navyPrimary,
      icon: Icons.search,
      imageAsset: 'assets/images/onboarding_1.png',
    ),
    OnboardingSlide(
      title: 'Book Sessions Instantly',
      description:
          'Reserve training sessions and facilities with just a few taps. Manage your schedule all in one place.',
      imageColor: AppPalette.orangeAccent,
      icon: Icons.calendar_today_rounded,
      imageAsset: 'assets/images/onboarding_2.png',
    ),
    OnboardingSlide(
      title: 'Track Your Progress',
      description:
          'Monitor your improvement, track session history, and celebrate achievements. Coaches can manage earnings and grow their business.',
      imageColor: AppPalette.navyLight,
      icon: Icons.trending_up_rounded,
      imageAsset: 'assets/images/onboarding_3.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _slides.length;

    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      body: Stack(
        children: [
          // Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length + 1, // +1 for Welcome Screen
            itemBuilder: (context, index) {
              if (index == _slides.length) {
                return const WelcomeScreen();
              }
              return _OnboardingCard(slide: _slides[index]);
            },
          ),

          // Overlay Controls (Skip & Bottom) - Hidden on Welcome Screen
          if (!isLastPage) ...[
            // Top Bar with Skip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _slides.length, // Jump to Welcome Screen
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: AppPalette.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length, // Only show dots for slides 1-3
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _currentPage == index ? 24 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _slides[_currentPage].imageColor
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _slides[_currentPage].imageColor,
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
                                'Next',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ).animate().fadeIn(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final Color imageColor;
  final IconData icon;
  final String imageAsset;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.imageColor,
    required this.icon,
    required this.imageAsset,
  });
}

class _OnboardingCard extends StatelessWidget {
  final OnboardingSlide slide;

  const _OnboardingCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Image Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: slide.imageColor.withValues(
                  alpha: 0.1,
                ), // Subtle background tint
                border: Border.all(
                  color: slide.imageColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  height: 320,
                  width: double.infinity,
                  color: Colors.white,
                  child: Image.asset(
                    slide.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          slide.icon,
                          size: 80,
                          color: slide.imageColor.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 32),

            // Circular Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: slide.imageColor,
                boxShadow: [
                  BoxShadow(
                    color: slide.imageColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(slide.icon, color: Colors.white, size: 32),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 24),

            // Text Content
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPalette.textPrimaryLight,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 12),

            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppPalette.textSecondaryLight,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const Spacer(
              flex: 2,
            ), // Extra space to push content up from bottom controls area
            const SizedBox(height: 80), // Reserve space for bottom controls
          ],
        ),
      ),
    );
  }
}
