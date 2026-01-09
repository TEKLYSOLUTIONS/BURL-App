import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isPromoApplied = false;
  bool _isPromoError = false;
  String _promoMessage = '';

  void _applyPromo() {
    setState(() {
      _isPromoError = false;
      _promoMessage = '';
    });

    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // Mock validation
    // Valid codes: PROCOACH50, SUPERCOACH25
    if (code == 'PROCOACH50') {
      setState(() {
        _isPromoApplied = true;
        _promoMessage = 'PROMO APPLIED!';
      });
    } else if (code == 'SUPERCOACH25') {
      setState(() {
        _isPromoError = true;
        _promoMessage = 'This code is invalid or has expired.';
      });
    } else {
      setState(() {
        _isPromoError = true;
        _promoMessage = 'Invalid promo code.';
      });
    }
  }

  void _removePromo() {
    setState(() {
      _isPromoApplied = false;
      _promoController.clear();
      _promoMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey bg
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppPalette.navyPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Unlock Pro Access',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Pro Coach Plan',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppPalette.navyPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elevate your coaching with advanced tools.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppPalette.textSecondaryLight, // Brownish grey
              ),
            ),
            const SizedBox(height: 32),

            // Pricing Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Card Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: AppPalette.navyPrimary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isPromoApplied)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '50% OFF',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ).animate().scale(),
                            ],
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.orangeAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Most Popular',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Plan',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.navyPrimary,
                                  ),
                                ),
                                Text(
                                  'Cancel anytime',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPalette
                                        .textSecondaryLight, // brownish
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (_isPromoApplied)
                                  Text(
                                    '\$29.99',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _isPromoApplied ? '\$14.99' : '\$29.99',
                                      style: GoogleFonts.outfit(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: _isPromoApplied
                                            ? Colors.green
                                            : AppPalette.navyPrimary,
                                      ),
                                    ),
                                    Text(
                                      '/mo',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 24),
                        _buildFeatureItem('Unlimited athlete profiles'),
                        _buildFeatureItem('Advanced video analysis'),
                        _buildFeatureItem('Team chat & scheduling'),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 500.ms),

            const SizedBox(height: 24),

            // Free Trial Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isPromoApplied
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF0FDF4), // Light green
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPromoApplied
                      ? Colors.green.withValues(alpha: 0.3)
                      : const Color(0xFFDCFCE7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPromoApplied ? Icons.celebration : Icons.calendar_today,
                    color: Colors.green[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isPromoApplied
                        ? '7-day free trial + 50% off for 3 months'
                        : '7-day free trial included',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Promo Code
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Promo Code',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppPalette.navyPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPromoApplied
                      ? Colors.green
                      : (_isPromoError ? Colors.red : Colors.grey[300]!),
                  width: _isPromoApplied || _isPromoError ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        readOnly: _isPromoApplied,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isPromoApplied
                              ? Colors.green
                              : AppPalette.navyPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ENTER CODE',
                          hintStyle: GoogleFonts.outfit(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (!_isPromoApplied)
                      ElevatedButton(
                        onPressed: _applyPromo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(
                            100,
                            48,
                          ), // Explicit size to prevent Theme infinity crash
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (_isPromoApplied)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
            if (_isPromoApplied || _isPromoError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPromoApplied ? 'PROMO APPLIED!' : _promoMessage,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isPromoApplied ? Colors.green : Colors.red[300],
                      ),
                    ),
                    if (_isPromoApplied)
                      GestureDetector(
                        onTap: _removePromo,
                        child: Text(
                          'Remove code',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    if (_isPromoError && _promoMessage.contains('Try Again'))
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPromoError = false;
                            _promoController.clear();
                          });
                        },
                        child: Text(
                          'Try Again',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.orangeAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
            Text(
              'Total due today: \$0.00',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPalette.navyPrimary,
              ),
            ),
            Text(
              'First charge of \$${_isPromoApplied ? '14.99' : '29.99'} begins after 7 days.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate or Logic
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Free Trial Started!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppPalette.orangeAccent.withValues(alpha: 0.4),
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
            Text(
              'By continuing, you agree to our Terms of Service. You can cancel your subscription at any time from your account settings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppPalette.orangeAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppPalette.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
