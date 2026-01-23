import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isAnnual = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: AppPalette.navyPrimary,
                  ),
                  Text(
                    'Upgrade Your Plan',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance back button
                ],
              ),
              const SizedBox(height: 32),

              Text(
                'Choose the Right Plan for You',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 12),

              Text(
                'Unlock advanced features to scale your coaching business.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppPalette.textSecondaryLight,
                ),
              ).animate().fadeIn().slideY(begin: 0.1, delay: 100.ms),

              const SizedBox(height: 32),

              // Monthly / Annual Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption('Monthly', !_isAnnual),
                    _buildToggleOption('Annual (Save 20%)', _isAnnual),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // Plans
              _buildPlanCard(
                title: 'Free Plan',
                price: 0,
                description: 'For new coaches just starting out.',
                features: [
                  'Basic Coach Profile',
                  'Up to 3 Active Clients',
                  'Standard Booking System',
                  '5% Transaction Fee',
                ],
                isPro: false,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              const SizedBox(height: 24),

              _buildPlanCard(
                title: 'Pro Plan',
                price: _isAnnual ? 290 : 29,
                description: 'Everything needed to scale a coaching business.',
                features: [
                  'Verified Pro Badge',
                  'Unlimited Clients',
                  'Advanced Analytics & Reporting',
                  'Reduced 2% Transaction Fee',
                  'Priority 24/7 Support',
                  'Custom Branding',
                ],
                isPro: true,
                isAnnual: _isAnnual,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAnnual = text.contains('Annual');
        });
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.navyPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppPalette.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required int price,
    required String description,
    required List<String> features,
    required bool isPro,
    bool isAnnual = false,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPro ? AppPalette.orangeAccent : Colors.grey[200]!,
              width: isPro ? 2 : 1,
            ),
            boxShadow: isPro
                ? [
                    BoxShadow(
                      color: AppPalette.orangeAccent.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPro) const SizedBox(height: 12), // Space for badge
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: AppPalette.textSecondaryLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$$price',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  Text(
                    isAnnual ? '/year' : '/month',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppPalette.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey[100]),
              const SizedBox(height: 24),
              ...features.map((feature) => _buildFeatureItem(feature, isPro)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPro
                        ? AppPalette.orangeAccent
                        : Colors.grey[100],
                    foregroundColor: isPro
                        ? Colors.white
                        : AppPalette.navyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: isPro ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isPro ? 'Get Started' : 'Current Plan',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPro)
          Positioned(
            top: -12,
            right: 24,
            child:
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.orangeAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.orangeAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ).animate().slideY(
                  begin: -0.5,
                  end: 1.5,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ), // Drop animation
          ),
      ],
    );
  }

  Widget _buildFeatureItem(String text, bool isHighlighed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isHighlighed ? const Color(0xFFE0F2F1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: isHighlighed ? Colors.teal : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppPalette.navyPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
