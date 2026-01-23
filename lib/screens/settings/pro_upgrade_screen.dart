import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  bool _isAnnual = false;
  final TextEditingController _promoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Unlock Pro Access',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppPalette.navyPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Pro Coach Plan',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.navyPrimary,
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 8),

              Text(
                'Elevate your coaching with advanced tools.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFFA16C42), // Brownish text from image
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn().slideY(begin: 0.1, delay: 100.ms),

              const SizedBox(height: 24),

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

              const SizedBox(height: 32),

              // PRO Card (Matched to Image)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Navy Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppPalette.navyPrimary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67E22), // Orange badge
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Most Popular',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ), // Spacing in blue area? Image shows empty blue area?
                          // The image shows a dark blue block. The content is BELOW it or INSIDE?
                          // Image: "Most Popular" is INSIDE.
                          // "Monthly Plan" is BELOW in white area.
                          // So the blue header is just decorative background?
                          // Or did it have text? The text "Pro Coach Plan" is outside.
                          // Image has empty blue space? No, likely decorative.
                          // I'll keep it simple.
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isAnnual ? 'Annual Plan' : 'Monthly Plan',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.navyPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Cancel anytime',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFFA16C42),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _isAnnual
                                        ? '\$290.00'
                                        : '\$29.99', // Updated pricing logic
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.navyPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isAnnual ? '/yr' : '/mo',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 24),

                          _buildTickItem('Unlimited athlete profiles'),
                          _buildTickItem('Advanced video analysis'),
                          _buildTickItem('Team chat & scheduling'),
                          if (_isAnnual) _buildTickItem('Priority support'),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Green Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF16A34A),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '7-day free trial included',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // Promo Code
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Promo Code',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        decoration: InputDecoration(
                          hintText: 'ENTER CODE',
                          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316), // Orange
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, // Fixed weight
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Total
              Text(
                'Total due today: \$0.00', // Hardcoded as per design image logic
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                ),
              ),
              Text(
                'First charge of \$${_isAnnual ? '290.00' : '29.99'} begins after 7 days.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316), // Orange
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.orange.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Free Trial',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Footer
              Text(
                'By continuing, you agree to our Terms of Service. You can cancel your subscription at any time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Restore Previous Purchases / Free Plan Link
              TextButton(
                onPressed: () {
                  // Logic to stay on Free Plan
                  Navigator.pop(context);
                },
                child: Text(
                  'Restore Purchases',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ),

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

  Widget _buildTickItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppPalette.navyPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
