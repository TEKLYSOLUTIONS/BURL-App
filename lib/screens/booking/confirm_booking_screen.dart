import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const ConfirmBookingScreen({super.key, this.bookingDetails = const {}});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  double _discountAmount = 0.0;
  String? _promoError;

  // Hardcoded values for demo matching the design
  final double _sessionFee = 60.00;
  final double _serviceFee = 2.50;
  final double _tax = 0.00;

  // Payment methods
  int _selectedPaymentMethod = 0; // 0: Card, 1: Apple Pay

  double get _totalAmount => _sessionFee + _serviceFee + _tax - _discountAmount;

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _promoError = null;
      if (code == 'SUMMER10') {
        _appliedPromoCode = 'SUMMER10';
        _discountAmount = 10.00;
      } else if (code == 'CRICKET50') {
        _appliedPromoCode = 'CRICKET50';
        _discountAmount = 30.00; // Arbitrary 50% max capped logic or similar
      } else {
        _promoError = "The code '$code' is invalid or has expired.";
        _appliedPromoCode = null;
        _discountAmount = 0.0;
      }
    });
  }

  void _removePromoCode() {
    setState(() {
      _promoController.clear();
      _appliedPromoCode = null;
      _discountAmount = 0.0;
      _promoError = null;
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine dynamic values with fallbacks
    final coachName = widget.bookingDetails['coachName'] ?? 'Michael Ray';
    final coachImage =
        widget.bookingDetails['coachImage'] ??
        'https://i.pravatar.cc/150?img=12'; // Reliable placeholder
    final dateStr = widget.bookingDetails['date'] ?? 'Tue, Oct 24';
    final timeStr = widget.bookingDetails['time'] ?? '10:00 AM';
    final location =
        widget.bookingDetails['location'] ?? 'Sunnydale Sports Complex';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Confirm Booking',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppPalette.navyPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success Message if Discount Applied
                    if (_appliedPromoCode != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E), // Green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discount Applied!',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "You're saving \$${_discountAmount.toStringAsFixed(2)} on this session.",
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 24),
                    ],

                    // BOOKING SUMMARY HEADER
                    Text(
                      'BOOKING SUMMARY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Booking Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Coach Info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(coachImage),
                                onBackgroundImageError:
                                    (exception, stackTrace) {}, // Prevent crash
                                backgroundColor: Colors.grey[200],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coachName,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppPalette.navyPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Tennis Coaching • Private Session',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppPalette.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          size: 14,
                                          color: AppPalette.orangeAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'TOP RATED COACH',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppPalette.orangeAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Divider(
                              color: AppPalette.divider,
                              height: 1,
                            ),
                          ),
                          // Date & Time
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppPalette.orangeAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppPalette.orangeAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE & TIME',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$dateStr • $timeStr',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.navyPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppPalette.orangeAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppPalette.orangeAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LOCATION',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.navyPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 32),

                    // PRICE BREAKDOWN HEADER
                    Text(
                      'PRICE BREAKDOWN',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Session Fee (1hr)', _sessionFee),
                          const SizedBox(height: 12),
                          _buildPriceRow('Service Fee', _serviceFee),
                          const SizedBox(height: 12),
                          _buildPriceRow('Tax', _tax),
                          if (_appliedPromoCode != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_offer,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Discount ($_appliedPromoCode)',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-\$${_discountAmount.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              color: AppPalette.divider,
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                              Text(
                                '\$${_totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // PROMO CODE SECTION
                    if (_appliedPromoCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _appliedPromoCode!,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _removePromoCode,
                              style: TextButton.styleFrom(
                                foregroundColor: AppPalette.error,
                                backgroundColor: AppPalette.error.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              child: Text(
                                'Remove',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Promo Input
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.local_offer_outlined,
                              color: AppPalette.textDisabled,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                style: GoogleFonts.inter(
                                  color: AppPalette.navyPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'ENTER PROMO CODE',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPalette.textDisabled,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _applyPromoCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.orangeAccent
                                    .withValues(alpha: 0.1),
                                foregroundColor: AppPalette.orangeAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Apply',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_promoError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppPalette.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppPalette.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: AppPalette.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _promoError!,
                                  style: GoogleFonts.inter(
                                    color: AppPalette.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      ),

                    const SizedBox(height: 32),

                    // PAYMENT METHOD HEADER
                    Text(
                      'PAYMENT METHOD',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cards
                    _buildPaymentOption(
                      index: 0,
                      icon: Icons.credit_card,
                      title: 'Visa ending in 4242',
                      subtitle: 'Expires 12/25',
                      iconContent: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'VISA',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      index: 1,
                      icon: Icons.apple,
                      title: 'Apple Pay',
                      iconContent: Container(
                        width: 38,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Add Payment Method Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppPalette.divider,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        // Dotted border effect is usually done with custom painter,
                        // using standard border for simplicity but focusing on clean UI
                        color: AppPalette.backgroundLight,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle,
                              color: AppPalette.textSecondaryLight,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add Payment Method',
                              style: GoogleFonts.inter(
                                color: AppPalette.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40), // Spacing for bottom button
                  ],
                ),
              ),
            ),

            // BOTTOM PAY BUTTON AREA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: AppPalette.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Payments are secure and encrypted',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppPalette.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Process Payment Logic (Mock)
                        context.push(
                          '/booking-success',
                          extra: widget.bookingDetails,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.orangeAccent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pay Total',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppPalette.textSecondaryLight,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppPalette.navyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? iconContent,
  }) {
    final isSelected = _selectedPaymentMethod == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      child: AnimatedContainer(
        duration: 200.ms,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppPalette.orangeAccent.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppPalette.orangeAccent : AppPalette.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (iconContent != null)
              iconContent
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppPalette.navyPrimary),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppPalette.navyPrimary,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppPalette.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppPalette.orangeAccent
                      : AppPalette.textDisabled,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
