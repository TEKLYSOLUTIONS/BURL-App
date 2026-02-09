import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

import '../../services/booking_service.dart';

class ConfirmBookingScreenSimple extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const ConfirmBookingScreenSimple({super.key, this.bookingDetails = const {}});

  @override
  State<ConfirmBookingScreenSimple> createState() =>
      _ConfirmBookingScreenSimpleState();
}

class _ConfirmBookingScreenSimpleState
    extends State<ConfirmBookingScreenSimple> {
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  double _discountAmount = 0.0;
  String? _promoError;
  int _selectedPaymentMethod = 0; // 0: Card, 1: Apple Pay, 2: Test Booking
  bool _isProcessing = false;

  final double _sessionFee = 60.00;
  final double _serviceFee = 2.50;
  final double _tax = 0.00;

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
        _discountAmount = 30.00;
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
    final coachName = widget.bookingDetails['coachName'] ?? 'Michael Ray';
    final coachImage =
        widget.bookingDetails['coachImage'] ??
        'https://i.pravatar.cc/150?img=12';
    final dateStr = widget.bookingDetails['date'] ?? 'Tue, Oct 24';
    final timeStr = widget.bookingDetails['time'] ?? '10:00 AM';
    final location =
        widget.bookingDetails['location'] ?? 'Sunnydale Sports Complex';

    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success banner if discount applied
                  if (_appliedPromoCode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
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
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Booking Summary Header
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(coachImage),
                              backgroundColor: Colors.grey[200],
                              onBackgroundImageError:
                                  (exception, stackTrace) {},
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
                          child: Divider(color: AppPalette.divider, height: 1),
                        ),
                        _buildInfoRow(
                          Icons.calendar_today_rounded,
                          'DATE & TIME',
                          '$dateStr • $timeStr',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.location_on_rounded,
                          'LOCATION',
                          location,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Price Breakdown
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
                                  const Icon(
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
                          child: Divider(color: AppPalette.divider, height: 1),
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
                  ),

                  const SizedBox(height: 24),

                  // Promo Code Section
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
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Payment Method
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

                  _buildPaymentOption(
                    index: 0,
                    icon: Icons.credit_card,
                    title: 'Visa ending in 4242',
                    subtitle: 'Expires 12/25',
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    index: 1,
                    icon: Icons.apple,
                    title: 'Apple Pay',
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    index: 2,
                    icon: Icons.bug_report,
                    title: 'Test Booking',
                    subtitle: 'For testing purposes only',
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom Pay Button
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
                    const Icon(
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
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() {
                              _isProcessing = true;
                            });

                            try {
                              // Map payment method index to string
                              String paymentMethodStr = 'card';
                              if (_selectedPaymentMethod == 1) {
                                paymentMethodStr = 'apple_pay';
                              } else if (_selectedPaymentMethod == 2) {
                                paymentMethodStr = 'test';
                              }

                              final sessionId =
                                  widget.bookingDetails['sessionId'];
                              final occurrenceDate =
                                  widget.bookingDetails['occurrenceDate'];
                              final promoCode = _appliedPromoCode;

                              if (sessionId == null || occurrenceDate == null) {
                                throw Exception('Missing booking details');
                              }

                              // Call API
                              await BookingService.createBooking(
                                sessionId: sessionId,
                                occurrenceDate: occurrenceDate,
                                paymentMethod: paymentMethodStr,
                                promoCode: promoCode,
                              );

                              if (context.mounted) {
                                context.push(
                                  '/booking-success',
                                  extra: widget.bookingDetails,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Booking failed: $e'),
                                    backgroundColor: AppPalette.error,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.orangeAccent,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppPalette.orangeAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppPalette.orangeAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
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
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final isSelected = _selectedPaymentMethod == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      child: Container(
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
